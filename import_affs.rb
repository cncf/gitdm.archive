require 'pry'
require 'scanf'

def import_affs(dev_affs, comp_devs)
  d_affs = []
  emails = []
  File.readlines(dev_affs).each do |line|
    data = line.split(': ').map(&:strip)
    if data.length == 2
      dname = data[0]
      emails = data[1].split(', ')
    elsif data.length == 1
      data2 = data.first.split(' until ')
      binding.pry if data2.length > 2
      emails.each do |email|
        if data2.length == 1
          d_affs << "#{email} #{data2.first}\n"
        else
          d_affs << "#{email} #{data2.first} < #{data2.last}\n"
        end
      end
    else
      binding.pry
    end
  end
  d_affs = d_affs.sort
  puts d_affs
end

if ARGV.size < 2
  puts "Missing arguments: developers_affiliations.txt company_developers.txt"
  exit(1)
end

import_affs(ARGV[0], ARGV[1])
