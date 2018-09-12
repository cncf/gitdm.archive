#!/usr/bin/env ruby
require 'json'

ARGV.each do |json_file|
  data = JSON.parse File.read json_file
  pretty = JSON.pretty_generate data.uniq
  File.write json_file, pretty
end
