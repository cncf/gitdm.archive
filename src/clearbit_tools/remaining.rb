require 'csv'
require 'pry'

first = {}
CSV.foreach('./input.csv', headers: true) do |row|
  h = row.to_h
  email = h['email']
  first[email] = 0 unless first.key? email
  first[email] += 1
end

#first.each do |email, n|
#  puts "dup1: #{email} " if n > 1
#end

second = {}
CSV.foreach('./rest.csv', headers: true) do |row|
  h = row.to_h
  email = h['email']
  second[email] = 0 unless second.key? email
  second[email] += 1
end

#second.each do |email, n|
#  puts "dup2: #{email} " if n > 1
#end

puts "email,"
second.each do |email, n|
  next if first.key? email
  puts "#{email},"
end

#binding.pry
#puts 'bye'

