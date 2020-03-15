#! /usr/bin/env ruby
require 'yaml'

PACKER_FILE = "#{Dir.pwd}/Packerfile"
abort("Packer file is not found") unless File.exists?(PACKER_FILE)

config = YAML.load_file(PACKER_FILE)
abort("Packer file is not a yaml") if config.inspect == "false"

config.each { |k, v| v.flatten! }
p config
