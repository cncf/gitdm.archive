require 'pry'
require 'json'
require 'pg'

def geousers(json_file)
  # Connect to 'geonames' database
  c = PG.connect( host: 'localhost', dbname: 'geonames', user: 'gha_admin', password: ENV['PG_PASS'] )

  # Parse input JSON
  data = JSON.parse File.read json_file

  # Strip JSON
  newj = []
  data.each do |row|
  end

  # Write JSON back
  pretty = JSON.pretty_generate newj
  File.write json_file, newj
end

if ARGV.size < 1
  puts "Missing arguments: github_users.json"
  exit(1)
end

geousers(ARGV[0])

