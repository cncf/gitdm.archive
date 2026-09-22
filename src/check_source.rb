#!/usr/bin/env ruby
#
require 'pry'
require './merge'

def check_source(json_file)
  # Parse input JSON
  data = JSON.parse File.read json_file

  # Delete fields from JSON
  stripped = []
  data.each do |row|
    s = row['source']
    a = row['affiliation']
    if s == 'notfound' && !['NotFound', '?', '', '(Unknown)', nil].include?(a)
      row['source'] = 'config'
      puts "No longer not found: #{row['login']}/#{row['email']}: '#{a}'"
    end
    stripped << row
  end

  # Write JSON back
  pretty = JSON.pretty_generate stripped
  File.write json_file, pretty
end

if ARGV.size < 1
  puts "Missing arguments: file.json"
  exit(1)
end

check_source(ARGV[0])
