require 'net/http'
require 'json'
require 'uri'
require 'pry'
require 'unidecoder'
require 'scanf'
require 'concurrent'
require 'pg'
require 'set'
require 'thwait'
require './nationalize_lib'
require './geousers_lib'

# Not thread safe
def get_gcache
  ary = []
  $g_nationalize_cache_mtx.with_read_lock { $g_nationalize_cache.each { |key, val| ary << [key, val] unless val === false } }
  ary
end

# Not thread safe
def generate_global_cache(cache)
  cache.each { |key, val| $g_nationalize_cache[key] = val unless val === false }
end

def nationalize(json_file, json_file2, json_cache, backup_freq)
  init_sqls()
  freq = backup_freq.to_i
  # set to false to retry gender lookups where name is set but no gender is found
  always_cache = true
  # set to true to retry cached nils
  retry_nils = false
  binding.pry

  # Parse input JSONs
  data = JSON.parse File.read json_file
  data2 = JSON.parse File.read json_file2
  cache = JSON.parse File.read json_cache
  generate_global_cache cache

  # Handle CTRL+C
  $g_nationalize_json_cache_filename = json_cache
  Signal.trap('INT') do
    puts "Caught signal, saving cache and exiting"
    pretty = JSON.pretty_generate get_gcache
    File.write $g_nationalize_json_cache_filename, pretty
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
    cid = user['country_id']
    tz = user['tz']
    if always_cache || (name.nil? || name == '' || (cid != nil && cid != '' && tz != nil && tz != ''))
      if retry_nils
        cache[[login, email]] = user unless cid.nil? || tz.nil?
      else
        cache[[login, email]] = user if user.key?('country_id') && user.key?('tz')
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
  prob = 0.5
  unless ENV['PROB'].nil?
    from = ENV['PROB'].to_f
  end
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
    ccid = user['country_id']
    ctz = user['tz']
    ky = nil
    ok = nil
    ok2 = nil
    $g_nationalize_cache_mtx.with_read_lock { ky = cache.key?([login, email]) }
    if (ccid.nil? || ccid == '' || ctz.nil? || ctz == '') && ky
      rec = nil
      $g_nationalize_cache_mtx.with_read_lock { rec = cache[[login, email]] }
      cid = user['country_id'] = rec['country_id'] if ccid.nil? || ccid == ''
      tz = user['tz'] = rec['tz'] if ctz.nil? || ctz == ''
      mtx.with_write_lock do
        ca += 1
        f += 1 unless cid.nil? || tz.nil?
      end
      mtx.with_write_lock { n += 1 }
      mtx.with_read_lock { puts "Row(hit) #{n}/#{all_n}: #{login}: #{name} -> (#{cid || ccid}, #{tz || ctz}) found #{f}, cache: #{ca}, state: #{ok}/#{ok2}" }
      newj << user
    elsif ccid.nil? || ctz.nil?
      thrs << Thread.new(user) do |usr|
        login = usr['login']
        email = usr['email']
        name = usr['name']
        ccid = usr['country_id']
        ctz = usr['tz']
        ky = nil
        ok = nil
        ok2 = nil
        cid = nil
        tz = nil
        cid, prb, ok = get_nat name, login, prob
        tz, ok2 = get_tz cid unless cid.nil?
        puts "Got #{name}, #{login} -> #{cid}@#{prb}, #{tz}, #{ok}, #{ok2}" unless cid.nil? || tz.nil?
        cid = ccid unless ccid.nil? || ccid  == ''
        tz = ctz unless ctz.nil? || ctz  == ''
        mtx.with_write_lock { f += 1 unless cid.nil? || tz.nil? }
        if cid.nil? || cid == ''
          usr['country_id'] = cid unless usr.key?('country_id')
        else
          usr['country_id'] = cid unless cid.nil? || cid == ''
        end
        if tz.nil? || tz == ''
          usr['tz'] = tz unless usr.key?('tz')
        else
          usr['tz'] = tz unless tz.nil? || tz == ''
        end
        mtx.with_write_lock { n += 1 }
        mtx.with_read_lock { puts "Row(miss) #{n}/#{all_n}: #{login}: #{name} -> (#{cid || ccid}, #{tz || ctz}) found #{f}, cache: #{ca}, state: #{ok}/#{ok2}" }
        [usr, ok, ok2]
      end
    else
      mtx.with_write_lock { n += 1 }
      mtx.with_read_lock { puts "Row(skip) #{n}/#{all_n}: #{login}: #{name} -> (#{cid || ccid}, #{tz || ctz}) found #{f}, cache: #{ca}, state: #{ok}/#{ok2}" }
      newj << user
    end
    begin
      $g_nationalize_stats_mtx.with_read_lock { puts "Index: #{idx}, Hits: #{$g_nationalize_hit}, Miss: #{$g_nationalize_miss}" }
    rescue => ee
      puts "Error: #{ee}"
    end
    while thrs.length >= n_thrs
      tw = nil
      begin
        tw = ThreadsWait.new(thrs.to_a)
      rescue => ee
        puts "Error: #{ee}"
        sleep 0.25
        puts "Retry"
        retry
      end
      t = tw.next_wait
      dat = t.value
      usr = dat[0]
      ok = dat[1]
      ok2 = dat[2]
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
    ok2 = dat[2]
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
  puts "Missing arguments: github_users.json stripped.json nationalize_cache.json backup_freq"
  exit(1)
end

nationalize ARGV[0], ARGV[1], ARGV[2], ARGV[3]
