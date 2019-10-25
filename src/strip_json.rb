require 'pry'
require './merge'

def strip_json(json_in, json_out)
  # Only affiliated
  oa = !ENV['ONLY_AFF'].nil?

  # Parse input JSON
  data = JSON.parse File.read json_in

  # Strip JSON
  stripped = []
  keys = %w(login email affiliation source name commits location country_id sex sex_prob tz age)
  data.each do |row|
    if oa
      aff = row['affiliation']
      add_row = !aff.nil? && !(['', '?', '(Robots)', '(Unknown)', 'NotFound'].include?(aff))
      unless add_row
        cid = row['country_id']
        tz = row['tz']
        sex = row['sex']
        sex_prob = row['prob']
        age = row['age']
        name = row['name']
        add_row = true unless cid.nil? || cid == ''
        add_row = true unless tz.nil? || tz == ''
        add_row = true unless sex.nil? || sex == ''
        add_row = true unless sex_prob.nil?
        add_row = true unless age.nil?
        add_row = true unless name.nil? || name == ''
      end
    else
      add_row = true
    end
    next unless add_row
    stripped_row = {}
    keys.each { |key| stripped_row[key] = row[key] if row.key?(key) }
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
