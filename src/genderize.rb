require 'net/http'
require 'json'
require 'uri'
require 'pry'
require 'unidecoder'
require 'scanf'
require 'concurrent'
require 'set'
require 'thwait'

$gjson_cache_filename = nil

$gcache = {}
$gcache_mtx = Concurrent::ReadWriteLock.new

$hit = 0
$miss = 0
$gstats_mtx = Concurrent::ReadWriteLock.new

# Thread safe
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
    $gcache_mtx.acquire_read_lock
    if $gcache.key?([name, cid])
      v = $gcache[[name, cid]]
      $gcache_mtx.release_read_lock
      $gstats_mtx.with_write_lock { $hit += 1 }
      ret << v
      next
    end
    $gcache_mtx.release_read_lock
    $gcache_mtx.acquire_write_lock
    $gstats_mtx.with_write_lock { $miss += 1 }
    suri = "https://api.genderize.io?name=#{URI.encode(name)}"
    suri += "&apikey=#{api_key}" if !api_key.nil? && api_key != ''
    suri += "&country_id=#{URI.encode(cid)}" if !cid.nil? && cid != ''
    begin
      uri = URI.parse(suri)
      response = Net::HTTP.get_response(uri)
      data = JSON.parse(response.body)
      #data = { 'gender' => 'x', 'probability' => 1.0, 'count' => 10 }
      $gcache[[name, cid]] = data
      $gcache_mtx.release_write_lock
      ret << data
      if data.key? 'error'
        puts data['error']
        return nil, nil, false
      end
    rescue StandardError => e
      $gcache_mtx.release_write_lock
      puts e
      return nil, nil, false
    end
  end
  r = ret.reject { |r| r['gender'].nil? }.sort_by { |r| [-r['probability'], -r['count']] }
  return nil, nil, true if r.count < 1
  return r.first['gender'][0], r.first['probability'], true
end

# Not thread safe
def get_gcache
  ary = []
  $gcache.each { |key, val| ary << [key, val] }
  ary
end

# Not thread safe
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

  # Handle CTRL+C
  $gjson_cache_filename = json_cache
  Signal.trap('INT') do
    puts "Caught signal, saving cache and exiting"
    pretty = JSON.pretty_generate get_gcache
    File.write $gjson_cache_filename, pretty
    puts "Saved"
    exit 1
  end

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
  mtx = Concurrent::ReadWriteLock.new
  all_n = data.length
  thrs = Set[]
  n_thrs = ENV['NCPUS'].nil? ? Etc.nprocessors : ENV['NCPUS'].to_i
  data.each_with_index do |user, idx|
    thrs << Thread.new(user) do |usr|
      login = usr['login']
      email = usr['email']
      name = usr['name']
      cid = usr['country_id']
      csex = usr['sex']
      cprob = usr['sex_prob']
      ky = nil
      ok = nil
      $gcache_mtx.with_read_lock { ky = cache.key?([login, email]) }
      if (csex.nil? || csex == '' || cprob.nil? || cprob == '') && ky
        rec = nil
        $gcache_mtx.with_read_lock { rec = cache[[login, email]] }
        sex = usr['sex'] = rec['sex']
        prob = usr['sex_prob'] = rec['sex_prob']
        mtx.with_write_lock do
          ca += 1
          f += 1 unless sex.nil?
        end
      else
        sex = nil
        if csex.nil? || cprob.nil?
          sex, prob, ok = get_sex name, login, cid
          mtx.with_write_lock { f += 1 unless sex.nil? }
          usr['sex'] = sex
          usr['sex_prob'] = prob
        end
      end
      mtx.with_write_lock { n += 1 }
      mtx.with_read_lock { puts "Row #{n}/#{all_n}: #{login}: (#{name}, #{login}, #{cid} -> #{sex || csex}, #{prob || cprob}) found #{f}, cache: #{ca}" }
      [usr, ok]
    end
    puts "Index: #{idx}, Hits: #{$hit}, Miss: #{$miss}"
    while thrs.length >= n_thrs
      tw = ThreadsWait.new(thrs.to_a)
      t = tw.next_wait
      data = t.value
      usr = data[0]
      ok = data[1]
      newj << usr
      if ok === false
        puts "Error state returned, backing up data"
        pretty = JSON.pretty_generate newj
        File.write 'backup.json', pretty
        pretty = JSON.pretty_generate get_gcache
        File.write json_cache, pretty
      end
      thrs = thrs.delete t
    end
    if idx > 0 && idx % freq == 0
      pretty = JSON.pretty_generate newj
      File.write 'partial.json', pretty
      pretty = JSON.pretty_generate get_gcache
      File.write json_cache, pretty
    end
  end
  ThreadsWait.all_waits(thrs.to_a) do |thr|
    data = thr.value
    usr = data[0]
    ok = data[1]
    newj << usr
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

genderize ARGV[0], ARGV[1], ARGV[2], ARGV[3]
