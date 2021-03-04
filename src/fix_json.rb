#!/usr/bin/env ruby

require 'json'

def fix_json(json_file)
  data = JSON.parse(File.read(json_file))

  fixed = 0
  data.each do |row|
    if row['location'] == 'Montreal, Canada'
      if row['country_id'] != 'ca'
        row['country_id'] = 'ca'
        fixed += 1
      end
      #if row['tz'] != 'America/Toronto'
      #  row['tz'] = 'America/Toronto'
      #  fixed += 1
      #end
    end
  end
  puts "Fixed: #{fixed}"

  pretty = JSON.pretty_generate data
  File.write json_file, pretty
end

if ARGV.size < 1
  puts "Missing arguments: file.json"
  exit(1)
end

fix_json(ARGV[0])
