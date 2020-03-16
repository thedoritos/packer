#! /usr/bin/env ruby
require 'yaml'
require 'fileutils'
require 'openssl'
require 'io/console'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: packer.rb command environment [options]"
  opts.on("-p:", "--password:", "Password for encryption/decryption") do |v|
    options[:password] = v
  end
  opts.on("-f", "--force-replace", "Force to replace existing files") do |v|
    options[:force_replace] = v
  end
end.parse!

PACKS_DIR = "#{Dir.pwd}/Packs"
PACKER_TMP_DIR = "#{Dir.pwd}/.packer"

PACKER_FILE = "#{Dir.pwd}/Packerfile"
abort("Packerfile is not found") unless File.exists?(PACKER_FILE)

config = YAML.load_file(PACKER_FILE)
abort("Packerfile is not a yaml") if config.inspect == "false"

config.each { |k, v| v.flatten! }

command, environment = ARGV

COMMANDS = %w(pack unpack)
abort("Pass command (#{COMMANDS.join('|')}) as arg0") unless COMMANDS.include?(command)

abort("Pass environment as arg1") unless environment
abort("Packerfile doesn't know environment: #{environment}") unless config.keys.include?(environment)

files = config[environment].map { |f| File.expand_path(f) }

case command
when 'pack'
  missing_files = files.reject { |f| File.exists?(f) }
  abort("#{missing_files.count} files are not found:\n#{missing_files.join("\n")}") unless missing_files.empty?

  password = options[:password]
  unless password
    print "Password: "
    password = STDIN.gets.chomp
  end

  tmp_pack_dir = "#{PACKER_TMP_DIR}/#{Time.now.to_i}"
  tmp_pack = "#{tmp_pack_dir}/#{environment}"
  files.each do |f|
    dest = tmp_pack + f.sub(Dir.pwd, '')
    FileUtils.mkdir_p(File.dirname(dest))
    FileUtils.cp(f, dest)
  end

  FileUtils.cd("#{tmp_pack}/..") do
    system("zip -qr #{environment}.zip *")

    cipher = OpenSSL::Cipher.new('aes-256-cbc')
    cipher.encrypt
    key_iv = OpenSSL::PKCS5.pbkdf2_hmac(password, 'salt', 2000, cipher.key_len + cipher.iv_len, 'sha256')
    cipher.key = key_iv[0, cipher.key_len]
    cipher.iv = key_iv[cipher.key_len, cipher.iv_len]

    File.open("#{environment}.pack", 'wb') do |output|
      File.open("#{environment}.zip", 'rb') do |input|
        buff = buff || ""
        while input.read(4096, buff)
          output << cipher.update(buff)
        end
        output << cipher.final
      end
    end
  end

  FileUtils.mkdir_p(PACKS_DIR)
  FileUtils.mv("#{tmp_pack}.pack", "#{PACKS_DIR}")
  FileUtils.rm_rf(tmp_pack_dir)
when 'unpack'
  pack = "#{PACKS_DIR}/#{environment}.pack"
  abort("File is not found:\n#{pack}") unless File.exists?(pack)

  password = options[:password]
  unless password
    print "Password: "
    password = STDIN.noecho(&:gets).chomp
    print "\n\n"
  end

  tmp_pack_dir = "#{PACKER_TMP_DIR}/#{Time.now.to_i}"
  tmp_pack = "#{tmp_pack_dir}/#{environment}"
  FileUtils.mkdir_p(tmp_pack_dir)
  FileUtils.cp(pack, tmp_pack_dir)

  FileUtils.cd(tmp_pack_dir) do
    cipher = OpenSSL::Cipher.new('aes-256-cbc')
    cipher.decrypt
    key_iv = OpenSSL::PKCS5.pbkdf2_hmac(password, 'salt', 2000, cipher.key_len + cipher.iv_len, 'sha256')
    cipher.key = key_iv[0, cipher.key_len]
    cipher.iv = key_iv[cipher.key_len, cipher.iv_len]

    File.open("#{environment}.zip", 'wb') do |output|
      File.open("#{environment}.pack", 'rb') do |input|
        buff = buff || ""
        while input.read(4096, buff)
          output << cipher.update(buff)
        end
        begin
          output << cipher.final
        rescue OpenSSL::Cipher::CipherError => e
          abort("Failed with error: #{e.message}")
        end
      end
    end

    system("unzip -q #{environment}.zip")
  end

  files = Dir["#{tmp_pack}/**/*"].reject { |f| File.directory?(f) }
  files_to = files.map { |f| Dir.pwd + f.sub(tmp_pack, '') }

  unless options[:force_replace]
    replacing_files = files_to.select { |f| File.exists?(f) }
    unless replacing_files.empty?
      print "#{replacing_files.count} files will be replaced:\n#{replacing_files.join("\n")}\n\n"
      print "Replace files? [y/n]: "
      loop do
        answer = STDIN.noecho(&:gets).chomp
        if %w(n no).include?(answer)
          print "n\n"
          exit 1
        end
        if %w(y yes).include?(answer)
          print "y\n"
          break
        end
      end
    end
  end

  files.zip(files_to).each do |from, to|
    FileUtils.mkdir_p(File.dirname(to))
    FileUtils.cp(from, to)
  end
  FileUtils.rm_rf(tmp_pack_dir)
end
