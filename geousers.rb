require 'pry'
require 'json'
require 'pg'
require 'unidecoder'

def check_stmt(c, stmt_name, args)
  begin
    rs = c.exec_prepared stmt_name, args
    if rs.values && rs.values.count > 0
      return rs.values.first.first
    end
  rescue PG::Error => e
    puts e
    binding.pry
  ensure
    rs.clear if rs
  end
  return nil
end

def get_cid_from_loc(c, iloc, rec)
  loc = iloc.strip
  loc.gsub! ';', ','
  binding.pry if loc.length < 1
  loc = loc[1..-1] if loc[0] == '@'
  if loc.length < 3
    puts "Too short: #{loc}"
    # return nil
  end
  ary = loc.split(',').map(&:strip)
  binding.pry if ary.length > 2
  if ary.length > 1
    ary.each do |part|
      cid = get_cid_from_loc c, part, rec
      return cid unless cid.nil?
    end
    return nil
  end
  aloc = loc.to_ascii.strip
  lloc = loc.downcase
  laloc = aloc.downcase

  ['A', 'P'].each do |fcl|
    cid = check_stmt c, 'direct_name_fcl', [fcl, loc]
    return cid unless cid.nil?
    if aloc != loc
      cid = check_stmt c, 'direct_aname_fcl', [fcl, aloc]
      return cid unless cid.nil?
    end
    cid = check_stmt c, 'direct_lname_fcl', [fcl, lloc]
    return cid unless cid.nil?
    if aloc != loc
      cid = check_stmt c, 'direct_laname_fcl', [fcl, laloc]
      return cid unless cid.nil?
    end
    cid = check_stmt c, 'alt_name_fcl', [fcl, loc]
    return cid unless cid.nil?
    if aloc != loc
      cid = check_stmt c, 'alt_name_fcl', [fcl, aloc]
      return cid unless cid.nil?
    end
    cid = check_stmt c, 'direct_lname_fcl', [fcl, lloc]
    return cid unless cid.nil?
    if aloc != loc
      cid = check_stmt c, 'direct_lname_fcl', [fcl, laloc]
      return cid unless cid.nil?
    end
  end
  cid = check_stmt c, 'direct_name', [loc]
  return cid unless cid.nil?
  if aloc != loc
    cid = check_stmt c, 'direct_aname', [aloc]
    return cid unless cid.nil?
  end
  cid = check_stmt c, 'direct_lname', [lloc]
  return cid unless cid.nil?
  if aloc != loc
    cid = check_stmt c, 'direct_laname', [laloc]
    return cid unless cid.nil?
  end
  cid = check_stmt c, 'alt_name', [loc]
  return cid unless cid.nil?
  if aloc != loc
    cid = check_stmt c, 'alt_name', [aloc]
    return cid unless cid.nil?
  end
  cid = check_stmt c, 'direct_lname', [lloc]
  return cid unless cid.nil?
  if aloc != loc
    cid = check_stmt c, 'direct_lname', [laloc]
    return cid unless cid.nil?
  end
  if rec
    dloc = loc.delete '$%^*+=[]{}:"|\\`~?/.<>_'
    if loc != dloc
      cid = get_cid_from_loc c, dloc, false
      binding.pry
      return cid
    end
  end
  return nil
end

def geousers(json_file)
  # Connect to 'geonames' database
  c = PG.connect host: 'localhost', dbname: 'geonames', user: 'gha_admin', password: ENV['PG_PASS']

  # PSQL statements used to get country codes
  c.prepare 'direct_name_fcl', 'select countrycode from geonames where fcl = $1 and name = $2 order by population desc, geonameid asc limit 1'
  c.prepare 'direct_aname_fcl', 'select countrycode from geonames where fcl = $1 and asciiname = $2 order by population desc, geonameid asc limit 1'
  c.prepare 'direct_lname_fcl', 'select countrycode from geonames where fcl = $1 and lower(name) = $2 order by population desc, geonameid asc limit 1'
  c.prepare 'direct_laname_fcl', 'select countrycode from geonames where fcl = $1 and lower(asciiname) = $2 order by population desc, geonameid asc limit 1'
  c.prepare 'alt_name_fcl', 'select countrycode from geonames where fcl = $1 and geonameid in (select geonameid from alternatenames where altname = $2) order by population desc, geonameid asc limit 1'
  c.prepare 'alt_lname_fcl', 'select countrycode from geonames where fcl = $1 and geonameid in (select geonameid from alternatenames where lower(altname) = $2) order by population desc, geonameid asc limit 1'
  c.prepare 'direct_name', 'select countrycode from geonames where name = $1 order by population desc, geonameid asc limit 1'
  c.prepare 'direct_aname', 'select countrycode from geonames where asciiname = $1 order by population desc, geonameid asc limit 1'
  c.prepare 'direct_lname', 'select countrycode from geonames where lower(name) = $1 order by population desc, geonameid asc limit 1'
  c.prepare 'direct_laname', 'select countrycode from geonames where lower(asciiname) = $1 order by population desc, geonameid asc limit 1'
  c.prepare 'alt_name', 'select countrycode from geonames where geonameid in (select geonameid from alternatenames where altname = $1) order by population desc, geonameid asc limit 1'
  c.prepare 'alt_lname', 'select countrycode from geonames where geonameid in (select geonameid from alternatenames where lower(altname) = $1) order by population desc, geonameid asc limit 1'
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
      cid = get_cid_from_loc c, loc, true
      f += 1 unless cid.nil?
    end
    user['country_id'] = cid
    newj << user
    n += 1
    puts "Row #{login}: (#{loc} -> #{cid}) #{n}, locations #{l}, found #{f}"
  end

  # Write JSON back
  # pretty = JSON.pretty_generate newj
  # File.write json_file, newj

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

