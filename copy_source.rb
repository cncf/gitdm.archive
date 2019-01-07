require 'json'
require 'csv'
require 'pry'
require './comment'
require './email_code'

def copy_source(json_file, json_file2, csv_file)
  sources = {}
  CSV.foreach(csv_file, headers: true) do |row|
    next if is_comment row
    h = row.to_h
    e = email_encode(h['email'].strip)
    s = h['source']
    sources[e] = s
  end
  data = JSON.parse File.read json_file
  data2 = JSON.parse File.read json_file2
  data2.each do |user|
    e = email_encode(user['email'])
    if (!user.key?('source') || user['source'] == 'config') && sources[e] == 'domain'
      sources[e] = 'domain'
    else
      sources[e] = user['source'] if user.key?('source')
    end
  end
  data.each do |user|
    e = email_encode(user['email'])
    s = user['source']
    ns = sources[e]
    if (!s && ns) || (s == 'config' && ns == 'domain')
      user['source'] = ns
    end
  end
  json = JSON.pretty_generate data
  File.write json_file, json
end

if ARGV.size < 3
  puts "Missing arguments: json_file json_file2 csv_file (github_users.json stripped.json all_affs.csv)"
  exit(1)
end

copy_source(ARGV[0], ARGV[1], ARGV[2])
