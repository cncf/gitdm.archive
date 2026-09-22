require 'pry'
require './merge'

def delete_fields_json(json_file, fields)
  # Parse input JSON
  data = JSON.parse File.read json_file

  # Fields to delete
  dels = fields.split(',').map(&:strip)

  # Delete fields from JSON
  stripped = []
  data.each do |row|
    dels.each { |field| row.delete(field) }
    stripped << row
  end

  # Write JSON back
  pretty = JSON.pretty_generate stripped
  File.write json_file, pretty
end

if ARGV.size < 2
  puts "Missing arguments: file.json 'field1,field2,...,fieldN'"
  exit(1)
end

delete_fields_json(ARGV[0], ARGV[1])
