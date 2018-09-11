require 'net/http'
require 'json'
require 'uri'
require 'pry'

def get_sex(name, login, cid)
  #uri = URI.parse("https://api.genderize.io?apikey=8d41a90f2dc1f41ecbf5d145ac1c47aa&name=kim&country_id=dk")
  #response = Net::HTTP.get_response(uri)
  #data = JSON.parse(response.body)
  #p data
    #return nil
end

def genderize(json_file)
  # Parse input JSON
  data = JSON.parse File.read json_file

  # Process
  newj = []
  n = 0
  f = 0
  all_n = data.length
  data.each do |user|
    login = user['login']
    name = user['name']
    cid = user['country_id']
    csex = user['sex']
    sex = nil
    if csex.nil?
      sex = get_sex name, login, cid
      f += 1 unless cid.nil?
    end
    user['sex'] = sex unless sex.nil?
    newj << user
    n += 1
    puts "Row #{n}/#{all_n}: #{login}: (#{name}, #{login}, #{cid} -> #{sex}) found #{f}, cache: #{$hit}/#{$miss}"
  end

  # Write JSON back
  pretty = JSON.pretty_generate newj
  File.write json_file, pretty
end

if ARGV.size < 1
    puts "Missing arguments: github_users.json"
  exit(1)
end

genderize(ARGV[0])
