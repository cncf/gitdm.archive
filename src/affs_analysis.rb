#!/usr/bin/env ruby

require 'csv'
require 'json'
require 'pry'

fn = ARGV[0]
if fn.nil? || fn == ''
  puts "Please provide CSV filename to analyse"
  exit
end

affs_data = {}
if ENV['SKIP_JSON'].nil?
  puts "Using JSON helper"
  json_data = JSON.parse File.read 'affiliated.json'
  json_data.each do |row|
    login = row['login'].downcase.strip
    affs = row['affiliation']
    affs_data[login] = affs unless affs.nil? || ['', 'NotFound', '?', '(Unknown)', '-'].include?(affs)
  end
end

data = []
# repo,rank_number,actor,company,commits,percent,all_commits
CSV.foreach(fn, headers: true) do |row|
  affs = row['company']
  if affs == '(Robots)'
    binding.pry
    next
  end
  unless affs.nil? || ['NotFound', '(Unknown)', '', '?', '-'].include?(affs)
    data << affs
  else
    login = row['actor'].downcase.strip
    affs = ''
    if affs_data.key?(login)
      affs = affs_data[login]
    end
    data << affs
  end
end

all = data.length.to_f
stats = [0.0, 0.0, 0.0]
data.each do |aff|
  if aff == ''
    stats[2] += 1.0
  elsif aff == 'Independent'
    stats[1] += 1.0
  else
    stats[0] += 1.0
  end
end

company = (100.0 * stats[0]) / all
known_company = (100.0 * stats[0]) / (stats[0] + stats[1])
independent = (100.0 * stats[1]) / all
known_independent = (100.0 * stats[1]) / (stats[0] + stats[1])
unknown = (100.0* stats[2]) / all

puts "All: #{all}"
printf("Working for company %.2f%% of all (%.2f%% of known)\n", company, known_company)
printf("Independent %.2f%% of all (%.2f%% of known)\n", independent, known_independent)
printf("Unknown %.2f%%\n", unknown)
