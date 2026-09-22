$g_geousers_json_cache_filename = nil

$g_geousers_cache = {}
$g_geousers_cache_mtx = Concurrent::ReadWriteLock.new

$g_geousers_hit = 0
$g_geousers_miss = 0
$g_geousers_stats_mtx = Concurrent::ReadWriteLock.new

$g_geousers_sqls = {}
$g_geousers_dbg = false

# Thread safe!
def check_stmt(c, stmt_name, args)
  begin
    key = [stmt_name, args]
    $g_geousers_cache_mtx.acquire_read_lock
    if $g_geousers_cache.key?(key)
      v = $g_geousers_cache[key]
      $g_geousers_cache_mtx.release_read_lock
      while v === false do
        $g_geousers_stats_mtx.with_read_lock { v = $g_geousers_cache[key] }
        # wait until real data become available (not a wip marker)
        sleep 0.001
      end
      $g_geousers_stats_mtx.with_write_lock { $g_geousers_hit += 1 }
      return v
    end
    $g_geousers_cache_mtx.release_read_lock
    $g_geousers_stats_mtx.with_write_lock { $g_geousers_miss += 1 }
    # Write marker that data is computing now: false
    $g_geousers_cache_mtx.with_write_lock { $g_geousers_cache[key] = false }
    # Need to have one connection per thread. If using 'c' created in the main thread
    # It fails sometimes with a PG C library stack dump and segv. Ruby's PG exec is not thread safe
    # unless each thread has its own connection. We're keeping *at most* connection per thread
    # If cache hit - thread creates no connections
    # Otherwise it can create multipel connections for all possible SQLs from $g_geousers_sqls
    begin
      if c[0].nil?
        c[0] = PG.connect host: 'localhost', dbname: 'geonames', user: 'gha_admin', password: ENV['PG_PASS']
      end
      rs = c[0].exec $g_geousers_sqls[stmt_name], args
    rescue => e2
      puts "ERROR: #{e2}"
    end
    if rs && rs.values && rs.values.count > 0
      # write the final computed data instead of marker: false
      $g_geousers_cache_mtx.with_write_lock { $g_geousers_cache[key] = [rs.values.first] }
      return [rs.values.first]
    end
    $g_geousers_cache_mtx.with_write_lock { $g_geousers_cache[key] = [] }
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
  #p loc
  #p data
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
def get_cid(loc)
  c = [nil]
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
  return nil, nil, false if ret.length < 1
  r = ret.sort_by { |row| -row[1].to_i }
  tz = r[0][3]
  if tz == '' || tz.nil?
    r2 = ret.sort_by { |row| [(row[3] == '') ? 1 : 0, -row[1].to_i] }
    tz = r2[0][3]
  end
  return r[0][0].downcase, tz, true
end

def get_tz(cid)
  c = [nil]
  data = check_stmt c, 'tz', [cid.downcase]
  return nil, false if data.length < 1
  return nil, false if data[0].length < 1
  return data[0][0], true
end

def init_sqls()
  if ENV['PG_PASS'].nil?
    puts "You have to specify PG_PASS=..."
    exit 1
  end
  # PSQL statements used to get country codes
  $g_geousers_sqls['direct_name_fcl'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and fcl = $1 and name like $2 order by tz = \'\', population desc, geonameid asc limit 1'
  $g_geousers_sqls['direct_aname_fcl'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and fcl = $1 and asciiname like $2 order by tz = \'\', population desc, geonameid asc limit 1'
  $g_geousers_sqls['direct_lname_fcl'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and fcl = $1 and lower(name) like $2 order by tz = \'\', population desc, geonameid asc limit 1'
  $g_geousers_sqls['direct_laname_fcl'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and fcl = $1 and lower(asciiname) like $2 order by tz = \'\', population desc, geonameid asc limit 1'
  $g_geousers_sqls['alt_name_fcl'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and fcl = $1 and geonameid in (select geonameid from alternatenames where altname like $2) order by tz = \'\', population desc, geonameid asc limit 1'
  $g_geousers_sqls['alt_lname_fcl'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and fcl = $1 and geonameid in (select geonameid from alternatenames where lower(altname) like $2) order by tz = \'\', population desc, geonameid asc limit 1'
  $g_geousers_sqls['direct_name'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and name like $1 order by tz = \'\', population desc, geonameid asc limit 1'
  $g_geousers_sqls['direct_aname'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and asciiname like $1 order by tz = \'\', population desc, geonameid asc limit 1'
  $g_geousers_sqls['direct_lname'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and lower(name) like $1 order by tz = \'\', population desc, geonameid asc limit 1'
  $g_geousers_sqls['direct_laname'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and lower(asciiname) like $1 order by tz = \'\', population desc, geonameid asc limit 1'
  $g_geousers_sqls['alt_name'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and geonameid in (select geonameid from alternatenames where altname like $1) order by tz = \'\', population desc, geonameid asc limit 1'
  $g_geousers_sqls['alt_lname'] = 'select countrycode, population, name, tz from geonames where countrycode != \'\' and geonameid in (select geonameid from alternatenames where lower(altname) like $1) order by tz = \'\', population desc, geonameid asc limit 1'
  $g_geousers_sqls['tz'] = 'select tz from geonames where lower(countrycode) = $1 order by population desc limit 1'
end
