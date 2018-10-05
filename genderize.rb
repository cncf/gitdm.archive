require 'net/http'
require 'json'
require 'uri'
require 'pry'
require 'unidecoder'
require 'scanf'

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
    name.delete! '"\'[]%_^@$*+={}:|\\`~?/.<>'
    next if name == ''
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
      if data.key? 'error'
        puts data['error']
        return nil, nil, false
      end
    rescue StandardError => e
      puts e
      return nil, nil, false
    end
  end
  r = ret.reject { |r| r['gender'].nil? }.sort_by { |r| [-r['probability'], -r['count']] }
  return nil, nil, true if r.count < 1
  return r.first['gender'][0], r.first['probability'], true
end

def get_gcache
  ary = []
  $gcache.each { |key, val| ary << [key, val] }
  ary
end

def generate_global_cache(cache)
  cache.each { |key, val| $gcache[key] = val }
end

def genderize(json_file, json_file2, json_cache, backup_freq)
  freq = backup_freq.to_i
  # set to false to retry gender lookups where name is set but no gender is found
  always_cache = true
  # Parse input JSONs
  data = JSON.parse File.read json_file
  data2 = JSON.parse File.read json_file2
  cache = JSON.parse File.read json_cache
  generate_global_cache cache

  # Process JSONs
  # Create cache from second file
  cache = {}
  data2.each do |user|
    login = user['login']
    email = user['email']
    name = user['name']
    sex = user['sex']
    sex_prob = user['sex_prob']
    if always_cache || (name.nil? || name == '' || (sex != nil && sex != '' && sex_prob != nil && sex_prob != ''))
      cache[[login, email]] = user
    else
      binding.pry
    end
  end
  newj = []
  n = 0
  f = 0
  ca = 0
  all_n = data.length
  data.each_with_index do |user, idx|
    login = user['login']
    email = user['email']
    name = user['name']
    cid = user['country_id']
    csex = user['sex']
    cprob = user['sex_prob']
    if (csex.nil? || csex == '' || cprob.nil? || cprob == '') && cache.key?([login, email])
      rec = cache[[login, email]]
      sex = user['sex'] = rec['sex']
      prob = user['sex_prob'] = rec['sex_prob']
      ca += 1
      f += 1 unless sex.nil?
    else
      sex = nil
      if csex.nil? || cprob.nil?
        sex, prob, ok = get_sex name, login, cid
        f += 1 unless sex.nil?
        user['sex'] = sex
        user['sex_prob'] = prob
        unless ok
          puts "Error state returned, backing up data"
          pretty = JSON.pretty_generate newj
          File.write 'backup.json', pretty
          pretty = JSON.pretty_generate get_gcache
          File.write json_cache, pretty
        end
      end
    end
    newj << user
    n += 1
    puts "Row #{n}/#{all_n}: #{login}: (#{name}, #{login}, #{cid} -> #{sex || csex}, #{prob || cprob}) found #{f}, cache: #{ca}, #{$hit}/#{$miss}"
    if idx > 0 && idx % freq == 0
      pretty = JSON.pretty_generate newj
      File.write 'partial.json', pretty
      pretty = JSON.pretty_generate get_gcache
      File.write json_cache, pretty
    end
  end

  # Write JSON back
  pretty = JSON.pretty_generate newj
  File.write json_file, pretty

  # Write gcache to file for future use
  pretty = JSON.pretty_generate get_gcache
  File.write json_cache, pretty
end

if ARGV.size < 4
  puts "Missing arguments: github_users.json stripped.json genderize_cache.json backup_freq"
  exit(1)
end

genderize ARGV[0], ARGV[1], ARGV[2]
