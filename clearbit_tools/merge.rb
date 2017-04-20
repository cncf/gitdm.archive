require 'csv'
require 'pry'

puts "email,"
File.foreach('unknown.dat').with_index do |line, line_num|
  sp1 = line.split('@')
  user = sp1[0]
  rest = sp1[1]
  domain = rest.split(' ')[0]
  puts "#{user}@#{domain},"
end
