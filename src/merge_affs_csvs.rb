#!/usr/bin/env ruby

require 'csv'
require 'pry'
require './email_code'
require './mgetc'

if ENV['OUT'].nil?
  puts "Specify output file via OUT=filename.csv"
  exit
end
ofn = ENV['OUT']
maps = []
ks = {}
up = {}
ARGV.each_with_index do |fn, i|
  # p fn
  maps[i] = {}
  CSV.foreach(fn, headers: true) do |row|
    emails = row['email']
    binding.pry if emails.nil?
    emails = email_encode(emails)
    emails = emails.split(',').map(&:strip)
    emails.each do |email|
      lemail = email.downcase
      binding.pry if maps[i].key?(lemail)
      maps[i][lemail] = row
      ks[lemail] = 0 unless ks.key?(lemail)
      ks[lemail] += 1
      up[lemail] = email
    end
  end
end
data = []
ks.each do |k, v|
  idx = 0
  if v > 1
    rs = []
    maps.each_with_index do |mp, i|
      rs << [i, mp[k].to_h] if mp.key?(k)
    end
    puts "\n\nEmail conflict: #{k}:"
    rs.each do |r|
      puts "#{ARGV[r[0]]}: #{r[1]}"
    end
    puts "\n"
    rs.each do |r|
      puts "#{r[0]+1}: #{r[1]['affiliations']}"
    end
    done = false
    while !done
      print "Choose index (q for quit): "
      ans = mgetc
      puts ""
      exit if ans == 'q'
      a = ans.to_i
      puts "Answer: #{a}"
      done = true if a > 0
    end
    idx = a - 1
  else
    maps.each_with_index do |mp, i|
      if mp.key?(k)
        idx = i
        break
      end
    end
  end
  row = maps[idx][k].to_h
  # puts "#{k}: #{row['affiliations']}"
  # type,email,name,github,linkedin1,linkedin2,linkedin3,patches,gender,location,affiliations
  # type,email,name,github,linkedin1,linkedin2,linkedin3,commits,gender,location,affiliations
  # email,name,github,linkedin1,linkedin2,linkedin3,repo,rank,commits,gender,location,affiliations
  typ = row['type']
  typ = '(Unknown)' if typ.nil?
  email = up[k]
  name = row['name'] || ''
  new_row = [
    typ,
    email,
    row['name'] || '',
    row['github'] || '',
    row['linkedin1'] || '',
    row['linkedin2'] || '',
    row['linkedin3'] || '',
    row['patches'] || row['commits'] || '',
    row['gender'] || '',
    row['location'] || '',
    row['affiliations'] || '',
  ]
  data << new_row
end

hdr = %w(type email name github linkedin1 linkedin2 linkedin3 patches gender location affiliations)
CSV.open(ofn, 'w', headers: hdr) do |csv|
  csv << hdr
  data.each { |row| csv << row }
end
