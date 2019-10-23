#!/usr/bin/env ruby

require 'json'

data = JSON.parse File.read 'github_users.json'
data.each do |row|
  row['country_id'].downcase! unless row['country_id'].nil? || row['country_id'] == ''
end

pretty = JSON.pretty_generate data
File.write 'github_users.json', pretty
