#!/usr/bin/env ruby
require 'pry'

def merge(infile1, infile2, outfile)
  # dbg: set to true to have very verbose output
  dbg = !ENV['DBG'].nil?

  cmap1 = {}
  File.readlines(infile1).each do |line|
    next if line[0] == '#'
    index = line.index(' -> ')
    unless index
      puts "Broken line: #{line}"
      binding.pry
      exit 1
    end
    from = line[0..index - 1].strip
    to = line[index + 4..-1].strip
    next if from == to
    if cmap1.key?(from) && cmap1[from] != to
      puts "Broken map: already present cmap1[#{from}] = #{cmap1[from]}, new value different: #{to}"
      binding.pry
      exit 1
    end
    cmap1[from] = to
  end
  cmap2 = {}
  File.readlines(infile2).each do |line|
    next if line[0] == '#'
    index = line.index(' -> ')
    unless index
      puts "Broken line: #{line}"
      binding.pry
      exit 1
    end
    from = line[0..index - 1].strip
    to = line[index + 4..-1].strip
    next if from == to
    if cmap2.key?(from) && cmap2[from] != to
      puts "Broken map: already present cmap2[#{from}] = #{cmap2[from]}, new value different: #{to}"
      binding.pry
      exit 1
    end
    cmap2[from] = to
  end
  maps = []
  cmap2.each do |from, to|
    if cmap1.key?(to)
      fto = cmap1[to]
      cmap1.delete(to)
      ks = []
      cmap1.each do |f, t|
        cmap1[f] = to if t == fto
      end
    end
  end
  cmap1.each do |from, to|
    if cmap2.key?(to)
      to = cmap2[to]
    end
    next if from == to
    maps << from + ' -> ' + to
  end
  cmap2.each do |from, to|
    if cmap1.key?(to)
      puts "Ignoring (#{from}, #{to}, #{cmap1[to]})" if cmap1[to] != from
    end
    next if from == to
    maps << from + ' -> ' + to
  end
  maps.sort!
  File.write outfile, maps.join("\n")
end

if ARGV.length < 3
  puts "Arguments required: infile1 infile2 outfile"
  puts "infile2 is higher priority"
  exit 1
end

merge(ARGV[0], ARGV[1], ARGV[2])
