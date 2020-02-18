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
  $g_genderize_cache_mtx.with_read_lock { $g_genderize_cache.each { |key, val| ary << [key, val] unless val === false } }
  ary
end

# Not thread safe
def generate_global_cache(cache)
  cache.each { |key, val| $g_genderize_cache[key] = val unless val === false }
end

def genderize(json_file, json_file2, json_cache, backup_freq)
  freq = backup_freq.to_i
  # set to false to retry gender lookups where name is set but no gender is found
  always_cache = true
  # set to true to retry cached nils
  retry_nils = false
  # Parse input JSONs
  binding.pry

  data = JSON.parse File.read json_file
  data2 = JSON.parse File.read json_file2
  cache = JSON.parse File.read json_cache
  generate_global_cache cache

  # Handle CTRL+C
  $g_genderize_json_cache_filename = json_cache
  Signal.trap('INT') do
    puts "Caught signal, saving cache and exiting"
    pretty = JSON.pretty_generate get_gcache
    File.write $g_genderize_json_cache_filename, pretty
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
  indices = [*0...data.length]
  indices.shuffle! unless ENV['SHUFFLE'].nil?
  indices.each_with_index do |sidx, idx|
    user = data[sidx]
    next if idx < from
    login = user['login']
    email = user['email']
    name = user['name']
    source = user['source']
    cid = user['country_id']
    csex = user['sex']
    cprob = user['sex_prob']
    ky = nil
    ok = nil
    $g_genderize_cache_mtx.with_read_lock { ky = cache.key?([login, email]) }
    if (csex.nil? || csex == '' || cprob.nil? || cprob == '') && ky
      rec = nil
      $g_genderize_cache_mtx.with_read_lock { rec = cache[[login, email]] }
      sex = user['sex'] = rec['sex'] if csex.nil? || csex == ''
      prob = user['sex_prob'] = rec['sex_prob'] if cprob.nil? || cprob == ''
      mtx.with_write_lock do
        ca += 1
        f += 1 unless sex.nil?
      end
      mtx.with_write_lock { n += 1 }
      mtx.with_read_lock { puts "Row(hit) #{n}/#{all_n}: #{login}: (#{name}, #{login}, #{cid} -> #{sex || csex}, #{prob || cprob}) found #{f}, cache: #{ca}, ok: #{ok}" }
      newj << user
    elsif csex.nil? || cprob.nil?
      thrs << Thread.new(user) do |usr|
        login = usr['login']
        email = usr['email']
        name = usr['name']
        source = usr['source']
        cid = usr['country_id']
        csex = usr['sex']
        cprob = usr['sex_prob']
        ky = nil
        ok = nil
        sex = nil
        sex, prob, ok = get_sex name, login, cid
        mtx.with_write_lock { f += 1 unless sex.nil? }
        if sex.nil? || sex == ''
          usr['sex'] = sex unless usr.key?('sex')
        else
          if %w(manual user_manual user).include?(source)
            usr['sex'] = sex unless sex.nil? || sex == '' || %w(m f b).include?(csex)
          else
            usr['sex'] = sex unless sex.nil? || sex == ''
          end
        end
        if prob.nil? || prob == ''
          usr['sex_prob'] = prob unless usr.key?('sex_prob')
        else
          if %w(manual user_manual user).include?(source)
            usr['sex_prob'] = prob unless prob.nil? || prob == '' || %w(m f b).include?(csex)
          else
            usr['sex_prob'] = prob unless prob.nil? || prob == ''
          end
        end
        mtx.with_write_lock { n += 1 }
        mtx.with_read_lock { puts "Row(miss) #{n}/#{all_n}: #{login}: (#{name}, #{login}, #{cid} -> #{sex || csex}, #{prob || cprob}) found #{f}, cache: #{ca}, ok: #{ok}" }
        [usr, ok]
      end
    else
      mtx.with_write_lock { n += 1 }
      mtx.with_read_lock { puts "Row(skip) #{n}/#{all_n}: #{login}: (#{name}, #{login}, #{cid} -> #{sex || csex}, #{prob || cprob}) found #{f}, cache: #{ca}, ok: #{ok}" }
      newj << user
    end
    begin
      $g_genderize_stats_mtx.with_read_lock { puts "Index: #{idx}, Hits: #{$g_genderize_hit}, Miss: #{$g_genderize_miss}" }
    rescue => ee
      puts "Error: #{ee}"
    end
    while thrs.length >= n_thrs
      tw = ThreadsWait.new(thrs.to_a)
      t = tw.next_wait
      dat = t.value
      usr = dat[0]
      ok = dat[1]
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
    dat = thr.value
    usr = dat[0]
    ok = dat[1]
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
