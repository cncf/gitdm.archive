require 'json'
require 'pry'

data = JSON.parse File.read ARGV[0]
data.each do |row|
  aff = row['affiliation']
  next unless aff.is_a?(String)
  aff2 = aff.gsub(/"/, '')
  if aff != aff2
    row['affiliation'] = aff2
  end
end
pretty = JSON.pretty_generate data
File.write ARGV[0], pretty
