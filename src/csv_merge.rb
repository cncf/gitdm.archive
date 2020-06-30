#!/usr/bin/env ruby

require 'pry'
require 'csv'

def merge(csvs)
  col = csvs[0]
  target = csvs[1]
  sources = csvs[2..-1]
  data = []
  sources.each do |source|
    CSV.foreach(source, headers: true) do |row|
      h = row.to_h
      data << h
    end
  end
  ary = data.sort_by { |row| -row[col].to_i }
  hdr = data.first.keys
  CSV.open(target, 'w', headers: hdr) do |csv|
    csv << hdr
    ary.each { |item| csv << item.values }
  end
end

if ARGV.size < 4
  puts "Missing arguments: column target.csv source1.csv ... sourceN.csv"
  puts "Example: commits task.csv *_task.csv"
  exit(1)
end

merge(ARGV)
