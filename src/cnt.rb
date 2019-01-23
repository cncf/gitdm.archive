require 'json'

def cnt(json_file)
  # Parse input JSON
  data = JSON.parse File.read json_file
  all = data.length
  p all
end

if ARGV.size < 1
  puts "Missing arguments: github_users.json"
  exit(1)
end

cnt(ARGV[0])

