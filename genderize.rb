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
  #cache.each { |key, val| $gcache[key] = val }
  cache.each do |key, val|
    ary = key.scanf('["%[^"]", "%[^"]"]')
    if ary.length == 2
      $gcache[ary] = val
    elsif ary.length == 1
      ary2 = key.scanf('["%[^"]", %s]')
      if ary2.length == 2 && ary2[1] == 'nil]'
        ary2[1] = nil
        $gcache[ary2] = val
      else
        puts "Wrong cache, skipping"
        p [key, val]
      end
    else
      puts "Wrong cache, skipping"
      p [key, val]
    end
  end
end

def genderize(json_file, json_file2, json_cache)
  # Parse input JSONs
  data = JSON.parse File.read json_file
  data2 = JSON.parse File.read json_file2
  cache = JSON.parse File.read json_cache
  generate_global_cache cache
  pretty = JSON.pretty_generate get_gcache
  File.write json_cache, pretty
  exit 1

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
    if idx > 0 && idx % 1000 == 0
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

if ARGV.size < 3
  puts "Missing arguments: github_users.json stripped.json genderize_cache.json"
  exit(1)
end

genderize ARGV[0], ARGV[1], ARGV[2]
