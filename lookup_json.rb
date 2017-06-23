require 'pry'
require 'to_regexp'
require 'json'

def lookup_json(json_file, args)
  # Parse RegExp filter(s)
  filters = {}
  key = nil
  args.each_with_index do |arg, index|
    if index % 2 == 0
      key = arg
    else
      filters[key] = arg.to_regexp
    end
  end

  # Parse JSON
  data = JSON.parse File.read json_file

  # Filter json
  users = []
  n = m = 0
  data.each do |user|
    n += 1
    match = true
    filters.each do |key, re|
      unless user[key].match(re)
        match = false
        break
      end
    end
    next unless match
    users << user
    m += 1
  end

  # Write matched JSON back
  json = JSON.pretty_generate users
  File.write 'matched.json', json
  puts "Matched #{m}/#{n} users, saved to matched.json"
end

if ARGV.size < 3
  puts "Missing arguments: JSON_file key1 regexp1 [key2 regexp2 ...]"
  exit(1)
end

lookup_json(ARGV[0], ARGV[1..-1])
