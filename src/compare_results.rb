require 'csv'
require 'pry'
require './email_code'

def compare_results(f1, f2)
  # email,company,final_company,date_from,date_to

  map1 = {}
  com1 = {}
  CSV.foreach(f1, headers: true) do |row|
    h = row.to_h
    e = email_encode(h['email'])
    fc = h['final_company']
    map1[e] = fc
    com1[fc] = [] unless com1.key?(fc)
    com1[fc] << e
  end

  map2 = {}
  com2 = {}
  CSV.foreach(f2, headers: true) do |row|
    h = row.to_h
    e = email_encode(h['email'])
    fc = h['final_company']
    map2[e] = fc
    com2[fc] = [] unless com2.key?(fc)
    com2[fc] << e
  end

  n1 = map1.keys.length
  n2 = map2.keys.length
  puts "CNCF mapping: #{n1} developers, Facade mapping: #{n2} developers"

  n1 = (com1.keys - ['(Unknown']).length
  n2 = (com2.keys - ['(Unknown)']).length
  puts "CNCF mapping: #{n1} employers, Facade mapping: #{n2} employers"

  n1 = com1['(Unknown)'].length
  n2 = com2['(Unknown)'].length
  puts "CNCF mapping: #{n1} unknown developers, Facade mapping: #{n2} unnown developers"

  n1 = 0
  (com1.keys - ['(Unknown)']).each { |k| n1 += com1[k].length }
  n2 = 0
  (com2.keys - ['(Unknown)']).each { |k| n2 += com2[k].length }
  puts "CNCF mapping: #{n1} mapped developers, Facade mapping: #{n2} mapped developers"

  no = same = other = 0
  map2.each do |email, company|
    company2 = map1[email]
    no += 1 unless company2
    if company == company2
      same += 1 
    elsif company2
      other += 1
    end
  end
  puts "From Facade mapping: #{no} emails not found, #{other} emails other, #{same} emails match CNCF mapping"

  no = same = other = 0
  map1.each do |email, company|
    company2 = map2[email]
    no += 1 unless company2
    if company == company2
      same += 1 
    elsif company2
      other += 1
    end
  end
  puts "From CNCF mapping: #{no} emails not found, #{other} emails other, #{same} emails match Facade mapping"

end

if ARGV.size < 2
  puts "Missing arguments: stats/all_changesets.csv facade_kubernetes.csv"
  exit(1)
end

compare_results(ARGV[0], ARGV[1])
