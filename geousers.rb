require 'pry'
require 'json'
require 'pg'
require 'unidecoder'

def check_stmt(c, stmt_name, args)
  begin
    rs = c.exec_prepared stmt_name, args
    if rs.values && rs.values.count > 0
      binding.pry
      return rs.values.first.first
    end
  rescue PG::Error => e
    binding.pry
  ensure
    rs.clear if rs
  end
  return nil
end

def get_cid_from_loc(c, iloc)
  loc = iloc.strip
  aloc = loc.to_ascii.strip
  lloc = loc.downcase
  laloc = aloc.downcase

  ['A', 'P'].each do |fcl|
    cid = check_stmt c, 'direct_name', [fcl, loc]
    return cid unless cid.nil?
    if aloc != loc
      cid = check_stmt c, 'direct_aname', [fcl, aloc]
      return cid unless cid.nil?
    end
    cid = check_stmt c, 'direct_lname', [fcl, lloc]
    return cid unless cid.nil?
    if aloc != loc
      cid = check_stmt c, 'direct_laname', [fcl, laloc]
      return cid unless cid.nil?
    end
    cid = check_stmt c, 'alt_name', [fcl, loc]
    return cid unless cid.nil?
    if aloc != loc
      cid = check_stmt c, 'alt_name', [fcl, aloc]
      return cid unless cid.nil?
    end
    cid = check_stmt c, 'direct_lname', [fcl, lloc]
    return cid unless cid.nil?
    if aloc != loc
      cid = check_stmt c, 'direct_lname', [fcl, laloc]
      return cid unless cid.nil?
    end
  end
end

def geousers(json_file)
  # Connect to 'geonames' database
  c = PG.connect host: 'localhost', dbname: 'geonames', user: 'gha_admin', password: ENV['PG_PASS']

  # PSQL statements used to get country codes
  c.prepare 'direct_name', 'select countrycode from geonames where fcl = $1 and name = $2 order by population desc, geonameid asc limit 1'
  c.prepare 'direct_aname', 'select countrycode from geonames where fcl = $1 and asciiname = $2 order by population desc, geonameid asc limit 1'
  c.prepare 'direct_lname', 'select countrycode from geonames where fcl = $1 and lower(name) = $2 order by population desc, geonameid asc limit 1'
  c.prepare 'direct_laname', 'select countrycode from geonames where fcl = $1 and lower(asciiname) = $2 order by population desc, geonameid asc limit 1'
  c.prepare 'alt_name', 'select countrycode from geonames where fcl = $1 and geonameid in (select geonameid from alternatenames where altname = $2) order by population desc, geonameid asc limit 1'
  c.prepare 'alt_lname', 'select countrycode from geonames where fcl = $1 and geonameid in (select geonameid from alternatenames where lower(altname) = $2) order by population desc, geonameid asc limit 1'
  # Parse input JSON
  data = JSON.parse File.read json_file

  # Strip JSON
  newj = []
  data.each do |user|
    loc = user['location']
    cid = nil
    if !loc.nil? && loc.length > 0
      cid = get_cid_from_loc c, loc
    end
    user['country_id'] = cid
    newj << user
  end

  # Write JSON back
  pretty = JSON.pretty_generate newj
  # File.write json_file, newj

  # Deallocate prepared statements
  c.exec 'deallocate direct_name'
  c.exec 'deallocate direct_aname'
  c.exec 'deallocate direct_lname'
  c.exec 'deallocate direct_laname'
end

if ARGV.size < 1
  puts "Missing arguments: github_users.json"
  exit(1)
end

geousers(ARGV[0])

