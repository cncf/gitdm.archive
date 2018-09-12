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
    if $gcache.key?([name, cid])
      $hit += 1
      ret << $gcache[[name, cid]]
      next
    end
    $miss += 1
    suri = "https://api.genderize.io?name=#{URI.encode(name)}"
    suri += "&apikey=#{api_key}" if !api_key.nil? && api_key != ''
    suri += "&country_id=#{URI.encode(cid)}" if !cid.nil? && cid != ''
    begin
      uri = URI.parse(suri)
      response = Net::HTTP.get_response(uri)
      data = JSON.parse(response.body)
      #data = { 'gender' => 'x', 'probability' => 1.0, 'count' => 10 }
      $gcache[[name, cid]] = data
      ret << data
    rescue StandardError => e
      puts e
      binding.pry
      return nil, nil, false
    end
  end
  r = ret.reject { |r| r['gender'].nil? }.sort_by { |r| [-r['probability'], -r['count']] }
  return nil, nil, true if r.count < 1
  return r.first['gender'][0], r.first['probability'], true
end

def genderize(json_file, json_file2)
  # Parse input JSONs
  data = JSON.parse File.read json_file
  data2 = JSON.parse File.read json_file2

  # Process JSONs
  # Create cache from second file
  cache = {}
  data2.each do |user|
    login = user['login']
    cache[login] = user
  end
  newj = []
  n = 0
  f = 0
  ca = 0
  all_n = data.length
  data.each_with_index do |user, idx|
    login = user['login']
    name = user['name']
    cid = user['country_id']
    if cache.key?(login)
      rec = cache[login]
      sex = user['sex'] = rec['sex']
      prob = user['sex_prob'] = rec['sex_prob']
      ca += 1
      f += 1 unless sex.nil?
    else
      csex = user['sex']
      cprob = user['sex_prob']
      sex = nil
      if csex.nil? || cprob.nil?
        sex, prob, ok = get_sex name, login, cid
        f += 1 unless sex.nil?
        user['sex'] = sex
        user['sex_prob'] = prob
        unless ok
          pretty = JSON.pretty_generate newj
          File.write 'backup.json', pretty
        end
      end
    end
    newj << user
    n += 1
    puts "Row #{n}/#{all_n}: #{login}: (#{name}, #{login}, #{cid} -> #{sex || csex}, #{prob || cprob}) found #{f}, cache: #{ca}, #{$hit}/#{$miss}"
    if idx > 0 && idx % 2000 == 0
      pretty = JSON.pretty_generate newj
      File.write 'partial.json', pretty
    end
  end

  # Write JSON back
  pretty = JSON.pretty_generate newj
  File.write json_file, pretty
end

if ARGV.size < 2
    puts "Missing arguments: github_users.json stripped.json"
  exit(1)
end

genderize ARGV[0], ARGV[1]
