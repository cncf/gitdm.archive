require 'pry'
require 'json'
require 'csv'
require './comment'

def enchance_json(json_file, csv_file)
  # Process affiliations found by Python cncf/gitdm saved in CSV
  # "email","company","date_to"
  affs = {}
  CSV.foreach(csv_file, headers: true) do |row|
    next if is_comment row
    h = row.to_h
    e = h['email'].strip
    c = h['company'].strip
    d = h['date_to'].strip
    affs[e] = [] unless affs.key?(e)
    if d && d.length > 0
      affs[e] << "#{c} < #{d}"
    else
      affs[e] << c
    end
  end

  # Make results as strings
  affs.each do |email, comps|
    affs[email] = comps.join ', '
  end
  
  # Parse JSON
  data = JSON.parse File.read json_file

  # Enchance JSON
  n_users = data.count
  enchanced = not_found = 0
  unks = []
  data.each do |user|
    e = user['email']
    v = '?'
    if affs.key?(e)
      enchanced += 1
      v = affs[e]
    else
      not_found += 1
      unks << e
    end
    user['affiliation'] = v
  end
  puts "Processed #{n_users} users, enchanced: #{enchanced}, not found: #{not_found}."
  puts "Unknown emails (VIM search pattern):"
  puts unks.join '\|'

  # Write JSON back
  json = JSON.pretty_generate data
  File.write json_file, json
end

if ARGV.size < 2
  puts "Missing arguments: JSON_file CSV_file (github_users.json all_affs.csv)"
  exit(1)
end

enchance_json(ARGV[0], ARGV[1])
