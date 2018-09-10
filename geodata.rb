require 'pry'
require 'pg'

def geodata(geodata_file)
  c = PG.connect( host: 'localhost', dbname: 'geonames', user: 'gha_admin', password: ENV['PG_PASS'] )
  cols = 19
  rows = 0
  altnames = []
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
    ary2 = vals[3].split(',').map(&:strip).reject(&:nil?)
    if ary2.length > 0
      altnames << [gnid, vals[3].split(',').map(&:strip).reject(&:nil?)]
    end
  end
  q = "insert into alternatenames(geonameid, altname) values "
  n = 0
  vars = []
  altnames.each do |data|
    gnid = data[0]
    data[1].each do |altname|
      q += "($#{n+1}, $#{n+2}), "
      n += 2
      vars << gnid
      vars << altname
    end
  end
  q = q[0..(q.length-3)] if n > 0
  q = q + " on conflict do nothing"
  c.prepare('alternatenames_q', q) 
  c.exec_prepared('alternatenames_q', vars)
  binding.pry
end

if ARGV.size < 1
  puts "Missing arguments: geodata.tsv"
  exit(1)
end

geodata(ARGV[0])
