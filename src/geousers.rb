require 'pry'
require 'json'
require 'pg'
require 'unidecoder'
require 'concurrent'
require 'set'
require 'thwait'

$gjson_cache_filename = nil

$gcache = {}
$gcache_mtx = Concurrent::ReadWriteLock.new

$hit = 0
$miss = 0
$gstats_mtx = Concurrent::ReadWriteLock.new

$gsqls = {}

def running_thread_count
  Thread.list.select {|thread| thread.status == "run"}.count
end

# Thread safe!
def check_stmt(c, stmt_name, args)
  begin
    key = [stmt_name, args]
    $gcache_mtx.acquire_read_lock
    if $gcache.key?(key)
      v = $gcache[key]
      $gcache_mtx.release_read_lock
      $gstats_mtx.with_write_lock { $hit += 1 }
      return v
    end
    $gcache_mtx.release_read_lock
    $gstats_mtx.with_write_lock { $miss += 1 }
    rs = c.async_exec $gsqls[stmt_name], args
    if rs.values && rs.values.count > 0
      $gcache_mtx.with_write_lock { $gcache[key] = [rs.values.first] }
      return [rs.values.first]
    end
    $gcache_mtx.with_write_lock { $gcache[key] = [] }
  rescue PG::Error => e
    puts e
    return []
  ensure
    rs.clear if rs
  end
  return []
end

def get_cid_from_loc(c, iloc, rec, pref, suff)
  ret = []
  loc = iloc.strip
  loc.gsub! ';', ','
  loc = loc.delete '%_[^]'
  return [] if loc.length < 1
  loc = loc[1..-1] if loc[0] == '@'
  # Change 3 --> 2 for next pass
  if loc.length < 3
    #puts "Too short: #{loc}"
    return []
  end
  ary = loc.split(',').map(&:strip)
  if ary.length > 1
    ary.each do |part|
      data = get_cid_from_loc c, part, rec, pref, suff
      data.each { |row| ret << row }
    end
    return ret
  end
  loc = pref + loc if pref != ''
  loc = loc  + suff if suff != ''
  aloc = loc.to_ascii.strip
  lloc = loc.downcase
  laloc = aloc.downcase

  ['P', 'A'].each do |fcl|
    data = check_stmt c, 'direct_name_fcl', [fcl, loc]
    data.each { |row| ret << row }
    if data.length < 1 && aloc != loc
      data = check_stmt c, 'direct_aname_fcl', [fcl, aloc]
      data.each { |row| ret << row }
    end
    if data.length < 1
      data = check_stmt c, 'direct_lname_fcl', [fcl, lloc]
      data.each { |row| ret << row }
      if data.length < 1 && aloc != loc
        data = check_stmt c, 'direct_laname_fcl', [fcl, laloc]
        data.each { |row| ret << row }
      end
      if data.length < 1
        data = check_stmt c, 'alt_name_fcl', [fcl, loc]
        data.each { |row| ret << row }
        if data.length < 1 && aloc != loc
          data = check_stmt c, 'alt_name_fcl', [fcl, aloc]
          data.each { |row| ret << row }
        end
        if data.length < 1
          data = check_stmt c, 'alt_lname_fcl', [fcl, lloc]
          data.each { |row| ret << row }
          if data.length < 1 && aloc != loc
            data = check_stmt c, 'alt_lname_fcl', [fcl, laloc]
            data.each { |row| ret << row }
          end
        end
      end
    end
  end
  data = check_stmt c, 'direct_name', [loc]
  data.each { |row| ret << row }
  if data.length < 1 && aloc != loc
    data = check_stmt c, 'direct_aname', [aloc]
    data.each { |row| ret << row }
  end
  if data.length < 1
    data = check_stmt c, 'direct_lname', [lloc]
    data.each { |row| ret << row }
    if data.length < 1 && aloc != loc
      data = check_stmt c, 'direct_laname', [laloc]
      data.each { |row| ret << row }
    end
    if data.length < 1
      data = check_stmt c, 'alt_name', [loc]
      data.each { |row| ret << row }
      if data.length < 1 && aloc != loc
        data = check_stmt c, 'alt_name', [aloc]
        data.each { |row| ret << row }
      end
      if data.length < 1
        data = check_stmt c, 'direct_lname', [lloc]
        data.each { |row| ret << row }
        if data.length < 1 && aloc != loc
          data = check_stmt c, 'direct_lname', [laloc]
          data.each { |row| ret << row }
        end
      end
    end
  end
  if data.length < 1 && rec
    dloc = loc.delete '$*+={}:"|\\`~?/.<>'
    if loc != dloc
      data = get_cid_from_loc c, dloc, false, pref, suff
      data.each { |row| ret << row }
    end
  end
  return ret
end

# Thread safe!
def get_cid(c, loc)
  ret = get_cid_from_loc c, loc, true, '', ''
  if ret.length < 1e10
    data = get_cid_from_loc c, loc, false, '', '%'
    data.each { |row| ret << row }
  end
  if ret.length < 1e10
    data = get_cid_from_loc c, loc, false, '%', ''
    data.each { |row| ret << row }
  end
  if ret.length < 1e10
    data = get_cid_from_loc c, loc, false, '%', '%'
    data.each { |row| ret << row }
  end
  return nil if ret.length < 1
  r = ret.sort_by { |row| -row[1].to_i }
  tz = r[0][3]
  if tz == '' || tz.nil?
    r2 = ret.sort_by { |row| [(row[3] == '') ? 1 : 0, -row[1].to_i] }
    tz = r2[0][3]
  end
  return r[0][0].downcase, tz
end

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
  freq = backup_freq.to_i
  # set to false to retry localization lookups where location is set but no country/tz is found
  always_cache = true
  # Connect to 'geonames' database
  c = PG.connect host: 'localhost', dbname: 'geonames', user: 'gha_admin', password: ENV['PG_PASS']

  # PSQL statements used to get country codes
  $gsqls['direct_name_fcl'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and fcl = $1 and name like $2 order by tz = \'\', population desc, geonameid asc limit 1'
  $gsqls['direct_aname_fcl'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and fcl = $1 and asciiname like $2 order by tz = \'\', population desc, geonameid asc limit 1'
  $gsqls['direct_lname_fcl'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and fcl = $1 and lower(name) like $2 order by tz = \'\', population desc, geonameid asc limit 1'
  $gsqls['direct_laname_fcl'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and fcl = $1 and lower(asciiname) like $2 order by tz = \'\', population desc, geonameid asc limit 1'
  $gsqls['alt_name_fcl'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and fcl = $1 and geonameid in (select geonameid from alternatenames where altname like $2) order by tz = \'\', population desc, geonameid asc limit 1'
  $gsqls['alt_lname_fcl'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and fcl = $1 and geonameid in (select geonameid from alternatenames where lower(altname) like $2) order by tz = \'\', population desc, geonameid asc limit 1'
  $gsqls['direct_name'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and name like $1 order by tz = \'\', population desc, geonameid asc limit 1'
  $gsqls['direct_aname'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and asciiname like $1 order by tz = \'\', population desc, geonameid asc limit 1'
  $gsqls['direct_lname'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and lower(name) like $1 order by tz = \'\', population desc, geonameid asc limit 1'
  $gsqls['direct_laname'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and lower(asciiname) like $1 order by tz = \'\', population desc, geonameid asc limit 1'
  $gsqls['alt_name'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and geonameid in (select geonameid from alternatenames where altname like $1) order by tz = \'\', population desc, geonameid asc limit 1'
  $gsqls['alt_lname'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and geonameid in (select geonameid from alternatenames where lower(altname) like $1) order by tz = \'\', population desc, geonameid asc limit 1'

  #['Россия', 'Russia, Moscow', 'San Francisco, CA, USA'].each do |loc|
  #  cid = get_cid c, loc
  #  puts "Row #{loc} -> #{cid}"
  #end

  # Parse input JSONs
  data = JSON.parse File.read json_file
  data2 = JSON.parse File.read json_file2
  cache = JSON.parse File.read json_cache
  generate_global_cache cache

  # handle CTRL+C
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
      cache[[login, email]] = user
    end
  end
  newj = []
  n = 0
  l = 0
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
      loc = usr['location']
      ccid = usr['country_id']
      ctz = usr['tz']
      ky = nil
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
          cid, tz = get_cid c, loc
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
      mtx.with_read_lock { puts "Row #{n}/#{all_n}: #{login}: (#{loc} -> #{cid || ccid}, #{tz || ctz}) locations #{l}, found #{f}, cache: #{ca}" }
      usr
    end
    puts "Index: #{idx}, Threads: #{running_thread_count()}, Hits: #{$hit}, Miss: #{$miss}"
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
