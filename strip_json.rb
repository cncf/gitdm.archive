require 'pry'
require './merge'

def strip_json(json_in, json_out)
  # Parse input JSON
  data = JSON.parse File.read json_in

  # Strip JSON
  stripped = []
  keys = %w(login email affiliation name)
  data.each do |row|
    stripped_row = {}
    keys.each { |key| stripped_row[key] = row[key] }
    stripped << stripped_row
  end

  # Write JSON back
  pretty = JSON.pretty_generate stripped
  File.write json_out, pretty
end

if ARGV.size < 2
    puts "Missing arguments: file_in.json file_out.json"
  exit(1)
end

strip_json(ARGV[0], ARGV[1])
