require 'pry'
require './merge'

def check_json(json_file, fields)
  # Parse input JSON
  data = JSON.parse File.read json_file

  # Fields to delete
  flds = fields.split(',').map(&:strip)

  # Check JSON
  wrongs = {}
  data.each do |row|
    row.keys.each do |key|
      unless flds.include?(key)
        wrongs[key] = 0 unless wrongs.key?(key)
        wrongs[key] += 1
      end
    end
  end
  if wrongs.keys.length > 0
    puts "There are invalid keys in #{json_file}: #{wrongs.keys}"
    p wrongs
  end
end

if ARGV.size < 2
  puts "Missing arguments: file.json 'field1,field2,...,fieldN'"
  exit(1)
end

check_json(ARGV[0], ARGV[1])
