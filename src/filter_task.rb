#!/usr/bin/env ruby

require 'json'

if ARGV.size < 3
  puts "Missing argument: unknowns.txt|alldevs.txt unknown_with_xyz.json output.txt"
  exit(1)
end

email2gh = {}
gh = JSON.parse File.read ARGV[1]
gh.each do |user|
  email = user['email']
  email2gh[email] = true
end

open(ARGV[2], 'w') do |f|
  File.readlines(ARGV[0]).each do |line|
    line.strip!
    ary = line.split "\t"
    email = ary[1]
    if email2gh.key?(email)
      f.puts line
    end
  end
end
