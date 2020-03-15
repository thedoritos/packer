#! /usr/bin/env ruby
require 'yaml'

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
when 'unpack'
end

p config[environment]
