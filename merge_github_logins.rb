require 'pry'
require './merge'

def merge_github_logins(json_file)
  # Parse input JSON
  data = JSON.parse File.read json_file

  # Merge multiple logins
  merge_multiple_logins data, true

  # Write JSON back
  json = JSON.pretty_generate data
  File.write json_file, json
end

if ARGV.size < 1
  puts "Missing argument: JSON_file"
  exit(1)
end

merge_github_logins(ARGV[0])
