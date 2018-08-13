#!/usr/bin/env ruby
require 'pry'
require 'json'

email2line = {}
File.readlines('unknowns.txt').each do |line|
  line.strip!
  ary = line.split "\t"
  email = ary[1]
  if email2line.key?(email)
    puts "Duplicate email: #{line}"
    binding.pry
  else
    email2line[email] = line
  end
end
binding.pry
