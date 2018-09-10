require 'pry'
require 'pg'

def geodata(geodata_file)
  c = PG.connect( host: 'localhost', dbname: 'geonames', user: 'gha_admin', password: ENV['PG_PASS'] )
  cols = 19
  rows = 0
  File.readlines(geodata_file).each do |row|
    vals = row.split "\t"
    if vals.count != cols
      puts "Wrong values count: #{vals.count}, shoould be #{cols}"
      binding.pry
    end
    rows += 1
  end
end

if ARGV.size < 1
  puts "Missing arguments: geodata.tsv"
  exit(1)
end

geodata(ARGV[0])
