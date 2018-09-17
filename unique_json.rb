#!/usr/bin/env ruby
require 'json'

ARGV.each do |json_file|
  data = JSON.parse File.read json_file
  new_data = []
  keys = {}
  data.each do |row|
    key = [row['login'], row['email']]
    unless keys.key?(key)
      new_data << row
      keys[key] = true
    end
  end
  pretty = JSON.pretty_generate new_data
  File.write json_file, pretty
  puts "Rows: #{data.length}, unique by login/email: #{new_data.length}"
end
