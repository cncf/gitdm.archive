require 'pry'
require 'json'
require 'pg'
require 'unidecoder'

$gcache = {}
$hit = 0
$miss = 0

def check_stmt(c, stmt_name, args)
  begin
    key = [stmt_name, args]
    if $gcache.key?(key)
        $hit += 1
      return $gcache[key]
    end
    $miss += 1
    rs = c.exec_prepared stmt_name, args
    if rs.values && rs.values.count > 0
      $gcache[key] = [rs.values.first]
      return [rs.values.first]
    end
    $gcache[key] = []
  rescue PG::Error => e
    puts e
    binding.pry
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
  binding.pry if loc.length < 1
  loc = loc[1..-1] if loc[0] == '@'
  if loc.length < 3
    puts "Too short: #{loc}"
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

def get_cid(c, loc)
  data = get_cid_from_loc c, loc, true, '', ''
  if data.length < 1
    data = get_cid_from_loc c, dloc, false, '', '%'
    data.each { |row| ret << row }
  end
  if data.length < 1
    data = get_cid_from_loc c, dloc, false, '%', ''
    data.each { |row| ret << row }
  end
  if data.length < 1
    data = get_cid_from_loc c, dloc, false, '%', '%'
    data.each { |row| ret << row }
  end
  return nil if data.length < 1
  data = data.sort_by { |row| -row[1].to_i }
  return data[0][0]
end

def geousers(json_file)
  # Connect to 'geonames' database
  c = PG.connect host: 'localhost', dbname: 'geonames', user: 'gha_admin', password: ENV['PG_PASS']

  # PSQL statements used to get country codes
  c.prepare 'direct_name_fcl', 'select countrycode, population, name from geonames where fcl = $1 and name like $2 order by population desc, geonameid asc limit 1'
  c.prepare 'direct_aname_fcl', 'select countrycode, population, name from geonames where fcl = $1 and asciiname like $2 order by population desc, geonameid asc limit 1'
  c.prepare 'direct_lname_fcl', 'select countrycode, population, name from geonames where fcl = $1 and lower(name) like $2 order by population desc, geonameid asc limit 1'
  c.prepare 'direct_laname_fcl', 'select countrycode, population, name from geonames where fcl = $1 and lower(asciiname) like $2 order by population desc, geonameid asc limit 1'
  c.prepare 'alt_name_fcl', 'select countrycode, population, name from geonames where fcl = $1 and geonameid in (select geonameid from alternatenames where altname like $2) order by population desc, geonameid asc limit 1'
  c.prepare 'alt_lname_fcl', 'select countrycode, population, name from geonames where fcl = $1 and geonameid in (select geonameid from alternatenames where lower(altname) like $2) order by population desc, geonameid asc limit 1'
  c.prepare 'direct_name', 'select countrycode, population, name from geonames where name like $1 order by population desc, geonameid asc limit 1'
  c.prepare 'direct_aname', 'select countrycode, population, name from geonames where asciiname like $1 order by population desc, geonameid asc limit 1'
  c.prepare 'direct_lname', 'select countrycode, population, name from geonames where lower(name) like $1 order by population desc, geonameid asc limit 1'
  c.prepare 'direct_laname', 'select countrycode, population, name from geonames where lower(asciiname) like $1 order by population desc, geonameid asc limit 1'
  c.prepare 'alt_name', 'select countrycode, population, name from geonames where geonameid in (select geonameid from alternatenames where altname like $1) order by population desc, geonameid asc limit 1'
  c.prepare 'alt_lname', 'select countrycode, population, name from geonames where geonameid in (select geonameid from alternatenames where lower(altname) like $1) order by population desc, geonameid asc limit 1'

  #[
  #  'Los Angeles, CA, USA',
  #].each do |loc|
  #  cid = get_cid c, loc
  #  puts "Row #{loc} -> #{cid}"
  #end

  # Parse input JSON
  data = JSON.parse File.read json_file

  # Strip JSON
  newj = []
  n = 0
  l = 0
  f = 0
  data.each do |user|
    loc = user['location']
    login = user['login']
    cid = nil
    if !loc.nil? && loc.length > 0
      l += 1
      cid = get_cid c, loc
      f += 1 unless cid.nil?
    end
    user['country_id'] = cid
    newj << user
    n += 1
    puts "Row #{login}: (#{loc} -> #{cid}) #{n}, locations #{l}, found #{f}, cache: #{$hit}/#{$miss}"
  end

  # Write JSON back
  pretty = JSON.pretty_generate newj
  File.write json_file, pretty

  # Deallocate prepared statements
  c.exec 'deallocate direct_name_fcl'
  c.exec 'deallocate direct_aname_fcl'
  c.exec 'deallocate direct_lname_fcl'
  c.exec 'deallocate direct_laname_fcl'
  c.exec 'deallocate alt_name_fcl'
  c.exec 'deallocate alt_lname_fcl'
  c.exec 'deallocate direct_name'
  c.exec 'deallocate direct_aname'
  c.exec 'deallocate direct_lname'
  c.exec 'deallocate direct_laname'
  c.exec 'deallocate alt_name'
  c.exec 'deallocate alt_lname'
end

if ARGV.size < 1
  puts "Missing arguments: github_users.json"
  exit(1)
end

geousers(ARGV[0])

