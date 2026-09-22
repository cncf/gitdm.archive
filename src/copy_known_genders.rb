#!/usr/bin/env ruby

require 'json'
require 'pry'

def copy_sex(from_file, to_file)
  from = JSON.parse File.read from_file
  to = JSON.parse File.read to_file

  from_sex = {}
  from.each do |user|
    login = user['login']
    email = user['email']
    sex = user['sex']
    sex_prob = user['sex_prob']
    if %w(m f b).include?(sex)
      from_sex[[login, email]] = [sex, sex_prob]
    end
  end
  u = 0
  to.each_with_index do |user, index|
    login = user['login']
    email = user['email']
    next unless from_sex.key?([login, email])
    sex = user['sex']
    sex_prob = user['sex_prob']
    ary = from_sex[[login, email]]
    fsex = ary[0]
    fsex_prob = ary[1]
    next if sex == fsex
    puts "#{login}, #{email}: #{sex} -> #{fsex}"
    to[index]['sex'] = fsex
    to[index]['sex_prob'] = fsex_prob
    u += 1
  end

  if u > 0
    pretty = JSON.pretty_generate to
    File.write to_file, pretty
  end
end

if ARGV.size < 2
  puts "Missing arguments: from.json to.json"
  exit(1)
end

copy_sex ARGV[0], ARGV[1]
