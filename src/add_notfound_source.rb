require 'json'
require 'pry'
json_file = 'github_users.json'
json_data = JSON.parse File.read json_file
json_data.each do |row|
  next unless row['source'].nil?
  a = row['affiliation']
  if a == 'NotFound'
    row['source'] = 'notfound'
  end
end
pretty = JSON.pretty_generate json_data
File.write json_file, pretty
