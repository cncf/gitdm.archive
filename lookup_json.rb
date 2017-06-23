require 'pry'
require 'to_regexp'
require 'json'

def lookup_json(json_file, args)
  # Parse RegExp filter(s)
  filters = {}
  key = nil
  args.each_with_index do |arg, index|
    if index % 2 == 0
      key = arg.split(',').map(&:strip)
    else
      filters[key] = arg.to_regexp
    end
  end
  output_json = args[-1]

  # Parse JSON
  data = JSON.parse File.read json_file

  # Filter json
  users = []
  n = m = 0
  data.each do |user|
    n += 1
    match = true
    filters.each do |keys, re|
      mode = :all?
      index = 0
      if keys.first.include?(':')
        index = 1
        mode = keys.first[1..-1].to_sym
      end
      matches = []
      keys.each_with_index do |key, i|
        next if i < index
        matches << (user[key] || '').match(re)
      end
      matched = matches.send(mode)
      unless matched
        match = false
        break
      end
    end
    next unless match
    users << user
    m += 1
  end
  if m < 1
    puts "Match not found in #{json_file}"
    return
  end

  # Write matched JSON back
  json = JSON.pretty_generate users
  File.write output_json, json
  puts "Matched #{m}/#{n} users, saved to #{output_json}"
end

if ARGV.size < 3
  puts "Missing arguments: JSON_file key1 regexp1 [key2 regexp2 ...]"
  exit(1)
end

lookup_json(ARGV[0], ARGV[1..-1])
