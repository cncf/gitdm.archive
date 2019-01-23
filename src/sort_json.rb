#!/usr/bin/env ruby

require 'json'

def sort_json(json_file)
  data = JSON.parse File.read json_file
  data = data.sort_by { |u| [-u['commits'], u['login'], u['email']] }
  pretty = JSON.pretty_generate data
  File.write json_file, pretty
end

if ARGV.size < 1
  puts "Missing arguments: github_users.json"
  exit(1)
end

sort_json(ARGV[0])
