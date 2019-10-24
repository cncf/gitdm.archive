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
  $gcache.each { |key, val| ary << [key, val] }
  ary
end

# Not thread safe!
def generate_global_cache(cache)
  cache.each { |key, val| $gcache[key] = val }
end

def geousers(json_file, json_file2, json_cache, backup_freq)
  $gdbg = !ENV['DBG'].nil?
  freq = backup_freq.to_i
  # set to false to retry localization lookups where location is set but no country/tz is found
  always_cache = true
  retry_nils = false

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
      loc = usr['location']
      ccid = usr['country_id']
      ctz = usr['tz']
      ky = nil
      ok = nil
      $gcache_mtx.with_read_lock { ky = cache.key?([login, email]) }
      if (ccid.nil? || ccid == '' || ctz.nil? || ctz == '') && ky
        rec = nil
        $gcache_mtx.with_read_lock { rec = cache[[login, email]] }
        cid = usr['country_id'] = rec['country_id']
        tz = usr['tz'] = rec['tz']
        mtx.with_write_lock do
          ca += 1
          l += 1 if !loc.nil? && loc.length > 0
          f += 1 unless cid.nil?
        end
      else
        cid = nil
        if (ccid.nil? || ctz.nil? || ccid == '' || ctz == '') && !loc.nil? && loc.length > 0
          puts "Querying #{login}, #{email}, #{loc}" if $gdbg
          cid, tz, ok = get_cid loc
          mtx.with_write_lock do
            l += 1
            f += 1 unless cid.nil?
          end
          usr['country_id'] = cid
          usr['tz'] = tz
        end
        usr['country_id'] = nil if usr['country_id'].nil?
        usr['tz'] = nil if usr['tz'].nil?
      end
      mtx.with_write_lock { n += 1 }
      mtx.with_read_lock { puts "Row #{n}/#{all_n}: #{login}: (#{loc} -> #{cid || ccid}, #{tz || ctz}) locations #{l}, found #{f}, cache: #{ca}, ok: #{ok}" }
      usr
    end
    begin
      $gstats_mtx.with_read_lock { puts "Index: #{idx}, Hits: #{$hit}, Miss: #{$miss}" }
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
      pretty = JSON.pretty_generate get_gcache
      File.write json_cache, pretty
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
  pretty = JSON.pretty_generate get_gcache
  File.write json_cache, pretty
end

if ARGV.size < 4
  puts "Missing arguments: github_users.json stripped.json geousers_cache.json backup_freq"
  exit(1)
end

geousers ARGV[0], ARGV[1], ARGV[2], ARGV[3]
