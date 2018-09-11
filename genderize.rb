require 'net/http'
require 'json'
require 'uri'
require 'pry'
require 'unidecoder'

$gcache = {}
$hit = 0
$miss = 0

def get_sex(name, login, cid)
  login = login.downcase.strip
  ary = [login]
  unless name.nil?
    name = name.downcase.strip
    ary = name.split(' ').map(&:strip).reject(&:empty?) << login
  end
  alln = []
  ary.each do |name|
    alln << name
    aname = name.to_ascii.downcase
    alln << aname if aname != name
  end
  alln = alln.uniq
  p alln
  apikey = ENV['API_KEY']
  alln.each do |name|
    if $gcache.key?(name)
        $hit += 1
      return $gcache[name]
    end
    $miss += 1
    uri = URI.parse("https://api.genderize.io?")
    if !api_key.nil? && api_key != ''
      uri += "apikey=#{api_key}&"
    end
    # name=kim&country_id=dk
    response = Net::HTTP.get_response(uri)
    data = JSON.parse(response.body)
    p data
  end
  return nil
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
      f += 1 unless sex.nil?
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
