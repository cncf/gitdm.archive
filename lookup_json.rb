require 'pry'
require 'to_regexp'
require 'json'

def lookup_json(json_file, args, output_json)
  # Parse RegExp filter(s)
  filters = {}
  key = nil
  args.each_with_index do |arg, index|
    if index % 2 == 0
      # Column name(s), 1st arg can be ruby method name if starts with ':'
      # So key can be: 
      # column name 'blog'
      # multiple column names 'login,bio, blog' - in this case default ruby operator is :all? which means all columns must match regexp
      # multiple column names with operator: ':any?,blog,bio' - means that blog OR bio must match regexp
      key = arg.split(',').map(&:strip)
    else
      # And now regexp to check on defined columns
      filters[key] = arg.to_regexp
    end
  end

  # Parse input JSON
  data = JSON.parse File.read json_file

  # Filter json
  users = []
  n = m = 0
  data.each do |user|
    n += 1
    # Assume match by default
    match = true
    filters.each do |keys, re|
      # default mode for multi column keys is AND (means all columns must match regexp)
      mode = :all?
      index = 0
      if keys.first[0] == ':'
        # if we have ruby method (starts with :) then skip this key (index=1) and extract method name and convert to Symbol
        index = 1
        mode = keys.first[1..-1].to_sym
      end
      matches = []
      # matches holds regexp match result for all keys
      keys.each_with_index do |key, i|
        # skip ruby method name if needed and also value can be nil so value || ''
        next if i < index
        matches << (user[key] || '').match(re)
      end
      # now we have array of match results and apply ruby method to it (default :all?) and get final match for all keys
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

lookup_json(ARGV[0], ARGV[1..-2], ARGV[-1])
