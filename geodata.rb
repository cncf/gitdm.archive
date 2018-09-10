require 'pry'
require 'pg'

def geodata(geodata_file)
  c = PG.connect( host: 'localhost', dbname: 'geonames', user: 'gha_admin', password: ENV['PG_PASS'] )
  # set skip_conflict to true to skip insert conflicts, this should not be needed on a clean database
  skip_conflict = false
  cols = 19
  rows = 0
  altnames = []
  geodata = []
  File.readlines(geodata_file).each do |row|
    vals = row.split "\t"
    if vals.count != cols
      puts "Wrong values count: #{vals.count}, shoould be #{cols}"
      binding.pry
    end
    rows += 1
    gnid = vals[0].to_i
    ary = [
      gnid,
      vals[1],
      vals[2],
      vals[4].to_f,
      vals[5].to_f,
      vals[8],
      vals[10],
      vals[11],
      vals[12],
      vals[13],
      vals[14].to_i,
      vals[17]
    ]
    geodata << ary if ary.length > 0
    ary2 = vals[3].split(',').map(&:strip).reject(&:nil?)
    altnames << [gnid, vals[3].split(',').map(&:strip).reject(&:nil?)] if ary2.length > 0
    puts "Row #{rows}" if rows % 10000 == 0
  end
  # alternate names
  puts "Rows #{rows}\nMass inserting altername names..."
  q = "insert into alternatenames(geonameid, altname) values "
  n = 0
  vars = []
  altnames.each_with_index do |data, idx|
    puts "Record #{idx}" if idx % 10000 == 0
    gnid = data[0]
    data[1].each do |altname|
      q += "($#{n+1}, $#{n+2}), "
      n += 2
      vars << gnid
      vars << altname
    end
  end
  q = q[0..(q.length-3)] if n > 0
  q = q + " on conflict do nothing" if skip_conflict
  puts "Final SQL exec prepared..."
  c.prepare('alternatenames_q', q) 
  c.exec_prepared('alternatenames_q', vars)
  # geodata
  puts "Mass inserting geonames"
  q = "insert into geonames(geonameid, name, asciiname, latitude, longitude, countrycode, ac1, ac2, ac3, ac4, population, tz) values "
  n = 0
  vars = []
  geodata.each_with_index do |row, idx|
    puts "Record #{idx}" if idx % 10000 == 0
    q += "($#{n+1}, $#{n+2}, $#{n+3}, $#{n+4}, $#{n+5}, $#{n+6}, $#{n+7}, $#{n+8}, $#{n+9}, $#{n+10}, $#{n+11}, $#{n+12}), "
    n += 12
    row.each { |col| vars << col }
  end
  q = q[0..(q.length-3)] if n > 0
  q = q + " on conflict do nothing" if skip_conflict
  puts "Final SQL exec prepared..."
  c.prepare('geodata_q', q)
  c.exec_prepared('geodata_q', vars)
end

if ARGV.size < 1
  puts "Missing arguments: geodata.tsv"
  exit(1)
end

geodata(ARGV[0])
