#! /usr/bin/env ruby
require 'yaml'
require 'fileutils'

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

  tmp_pack = "#{PACKER_TMP_DIR}/#{Time.now.to_i}/#{environment}"
  FileUtils.rm_rf(tmp_pack)
  files.each do |f|
    dest = "#{tmp_pack}/#{f.sub(Dir.pwd, '').sub('/', '')}"
    p dest
    FileUtils.mkdir_p(File.dirname(dest))
    FileUtils.cp(f, dest)
  end
when 'unpack'
end

p config[environment]
