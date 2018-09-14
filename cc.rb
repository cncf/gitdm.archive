#!/usr/bin/env ruby

require 'pry'

special = {
  'And' => 'and',
  'The' => 'the',
  '(keeling)' => '(Keeling)',
  '(malvinas)' => '(Malvinas)',
  'Guinea-bissau' => 'Guinea-Bissau',
  '(vatican' => '(Vatican',
  '(french' => '(French',
  '(dutch' => '(Dutch',
  'Timor-leste' => 'Timor-Leste',
  'U.s.' => 'U.S.',
}

File.readlines('cc.tsv').each do |row|
  vals = row.split "\t"
  if vals.count != 2
    puts "Wrong values count: #{vals.count}, should be 2"
    binding.pry
  end
  name = vals[0].split.map(&:strip).map { |n| n.length > 2 ? n.capitalize : n }.map { |n| special.key?(n) ? special[n] : n } * ' '
  name = name[0].capitalize + name[1..-1]
  code = vals[1].strip
  puts "insert into gha_countries(code, name) values('#{code}', '#{name}');"
end
