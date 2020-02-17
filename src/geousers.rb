require 'pry'
require 'json'
require 'pg'
require 'unidecoder'
require 'concurrent'
require 'set'
require 'thwait'
require './geousers_lib'

# Not thread safe!
def get_gcache
  ary = []
  $g_geousers_cache_mtx.with_read_lock { $g_geousers_cache.each { |key, val| ary << [key, val] unless val === false } }
  ary
end

# Not thread safe!
def generate_global_cache(cache)
  cache.each { |key, val| $g_geousers_cache[key] = val unless val === false }
end

def geousers(json_file, json_file2, json_cache, backup_freq)
  $g_geousers_dbg = !ENV['GEOUSERS_DBG'].nil?
  freq = backup_freq.to_i
  # set to false to retry localization lookups where location is set but no country/tz is found
  always_cache = true
  # set to true to retry cached nils
  retry_nils = false
  binding.pry

  init_sqls()

  #['Россия', 'Russia, Moscow', 'San Francisco, CA, USA'].each do |loc|
  #  cid = get_cid loc
  #  puts "Row #{loc} -> #{cid}"
  #end

  # Parse input JSONs
  data = JSON.parse File.read json_file
  data2 = JSON.parse File.read json_file2
  cache = JSON.parse File.read json_cache
  generate_global_cache cache

  # Handle CTRL+C
  $g_geousers_json_cache_filename = json_cache
  Signal.trap('INT') do
    puts "Caught signal, saving cache and exiting"
    pretty = JSON.pretty_generate get_gcache
    File.write $g_geousers_json_cache_filename, pretty
    puts "Saved"
    exit 1
  end

  # Process JSONs
  # Create cache from second file
  cache = {}
  data2.each do |user|
    login = user['login']
    email = user['email']
    loc = user['location']
    cid = user['country_id']
    tz = user['tz']
    if always_cache || (loc.nil? || loc == '' || (cid != nil && cid != '' && tz != nil && tz != ''))
      if retry_nils
        cache[[login, email]] = user unless cid.nil? || tz.nil?
      else
        cache[[login, email]] = user if user.key?('country_id') && user.key?('tz')
      end
    end
  end
  newj = []
  l = 0
  f = 0
  ca = 0
  skip_save_cache = !ENV['SKIP_SAVE_CACHE'].nil?
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
    loc = user['location']
    ccid = user['country_id']
    ctz = user['tz']
    ky = nil
    ok = nil
    cid = nil
    $g_geousers_cache_mtx.with_read_lock { ky = cache.key?([login, email]) }
    if (ccid.nil? || ccid == '' || ctz.nil? || ctz == '') && ky
      rec = nil
      $g_geousers_cache_mtx.with_read_lock { rec = cache[[login, email]] }
      cid = user['country_id'] = rec['country_id'] if ccid.nil? || ccid == ''
      tz = user['tz'] = rec['tz'] if ctz.nil? || ctz == ''
      mtx.with_write_lock do
        ca += 1
        l += 1 if !loc.nil? && loc.length > 0
        f += 1 unless cid.nil?
      end
      mtx.with_write_lock { n += 1 }
      mtx.with_read_lock { puts "Row(hit) #{n}/#{all_n}: #{login}: (#{loc} -> #{cid || ccid}, #{tz || ctz}) locations #{l}, found #{f}, cache: #{ca}, ok: #{ok}" }
      newj << user
    elsif (ccid.nil? || ctz.nil? || ccid == '' || ctz == '') && !loc.nil? && loc.length > 0
      thrs << Thread.new(user) do |usr|
        login = usr['login']
        email = usr['email']
        loc = usr['location']
        ccid = usr['country_id']
        ctz = usr['tz']
        ky = nil
        ok = nil
        cid = nil
        puts "Querying #{login}, #{email}, #{loc}" if $g_geousers_dbg
        cid, tz, ok = get_cid loc
        mtx.with_write_lock do
          l += 1
          f += 1 unless cid.nil?
        end
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
        mtx.with_read_lock { puts "Row(miss) #{n}/#{all_n}: #{login}: (#{loc} -> #{cid || ccid}, #{tz || ctz}) locations #{l}, found #{f}, cache: #{ca}, ok: #{ok}" }
        usr
      end
    else
      mtx.with_write_lock { n += 1 }
      mtx.with_read_lock { puts "Row(skip) #{n}/#{all_n}: #{login}: (#{loc} -> #{cid || ccid}, #{tz || ctz}) locations #{l}, found #{f}, cache: #{ca}, ok: #{ok}" }
      newj << user
    end
    begin
      $g_geousers_stats_mtx.with_read_lock { puts "Index: #{idx}, Hits: #{$g_geousers_hit}, Miss: #{$g_geousers_miss}" }
    rescue => ee
      puts "Error: #{ee}"
    end
    while thrs.length >= n_thrs
      tw = ThreadsWait.new(thrs.to_a)
      t = tw.next_wait
      usr = t.value
      newj << usr
      thrs = thrs.delete t
    end
    if idx > 0 && idx % freq == 0
      pretty = JSON.pretty_generate newj
      File.write 'partial.json', pretty

      # Write gcache to file for future use
      unless skip_save_cache
        pretty = JSON.pretty_generate get_gcache
        File.write json_cache, pretty
      end
    end
  end
  ThreadsWait.all_waits(thrs.to_a) do |thr|
    usr = thr.value
    newj << usr
  end

  # Write JSON back
  pretty = JSON.pretty_generate newj
  File.write json_file, pretty

  # Write gcache to file for future use
  unless skip_save_cache
    pretty = JSON.pretty_generate get_gcache
    File.write json_cache, pretty
  end
end

if ARGV.size < 4
  puts "Missing arguments: github_users.json stripped.json geousers_cache.json backup_freq"
  exit(1)
end

geousers ARGV[0], ARGV[1], ARGV[2], ARGV[3]
