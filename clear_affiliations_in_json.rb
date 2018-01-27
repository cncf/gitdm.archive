require 'pry'
require 'json'

def clear_affiliations_in_json(json_file)
  # Parse JSON
  data = JSON.parse File.read json_file

  # Enchance JSON
  n_users = data.count
  puts "Clearing #{n_users} entries..."
  data.each do |user|
    user.delete 'affiliation'
  end

  # Write JSON back
  json = JSON.pretty_generate data
  File.write json_file, json
end

if ARGV.size < 1
  puts "Missing arguments: JSON_file"
  exit(1)
end

clear_affiliations_in_json(ARGV[0])
