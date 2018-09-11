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
  api_key = ENV['API_KEY']
  ret = []
  alln.each do |name|
    if $gcache.key?(name)
      $hit += 1
      ret << $gcache[name]
      next
    end
    $miss += 1
    suri = "https://api.genderize.io?name=#{URI.encode(name)}"
    suri += "&apikey=#{api_key}" if !api_key.nil? && api_key != ''
    suri += "&country_id=#{URI.encode(cid)}" if !cid.nil? && cid != ''
    uri = URI.parse(suri)
    response = Net::HTTP.get_response(uri)
    data = JSON.parse(response.body)
    $gcache[name] = data
    ret << data
  end
  r = ret.reject { |r| r['gender'].nil? }.sort_by { |r| [-r['probability'], -r['count']] }
  return nil, nil if r.count < 1
  return r.first['gender'][0], r.first['probability']
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
    cprob = user['sex_prob']
    sex = nil
    if csex.nil? || cprob.nil?
      sex, prob = get_sex name, login, cid
      f += 1 unless sex.nil?
      user['sex'] = sex
      user['sex_prob'] = prob
    end
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
