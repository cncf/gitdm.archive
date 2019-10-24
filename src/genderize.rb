require 'net/http'
require 'json'
require 'uri'
require 'pry'
require 'unidecoder'
require 'scanf'
require 'concurrent'
require 'set'
require 'thwait'
require './genderize_lib'

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
  retry_nils = false
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
      if retry_nils
        cache[[login, email]] = user unless sex.nil? || sex_prob.nil?
      else
        cache[[login, email]] = user if user.key?('sex') && user.key?('sex_prob')
      end
    else
      binding.pry
    end
  end
  newj = []
  f = 0
  ca = 0
  mtx = Concurrent::ReadWriteLock.new
  all_n = data.length
  from = 0
  unless ENV['FROM'].nil?
    from = ENV['FROM'].to_i
  end
  n = from
  thrs = Set[]
  n_thrs = ENV['NCPUS'].nil? ? Etc.nprocessors : ENV['NCPUS'].to_i
  data.each_with_index do |user, idx|
    next if idx < from
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
      mtx.with_read_lock { puts "Row #{n}/#{all_n}: #{login}: (#{name}, #{login}, #{cid} -> #{sex || csex}, #{prob || cprob}) found #{f}, cache: #{ca}, ok: #{ok}" }
      [usr, ok]
    end
    begin
      $gstats_mtx.with_read_lock { puts "Index: #{idx}, Hits: #{$ghit}, Miss: #{$gmiss}" }
    rescue => ee
      puts "Error: #{ee}"
    end
    while thrs.length >= n_thrs
      tw = ThreadsWait.new(thrs.to_a)
      t = tw.next_wait
      data = t.value
      usr = data[0]
      ok = data[1]
      newj << usr
      thrs = thrs.delete t
      if ok === false
        puts "Error state returned, backing up data"
        pretty = JSON.pretty_generate newj
        File.write 'backup.json', pretty
        pretty = JSON.pretty_generate get_gcache
        File.write json_cache, pretty
      end
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
