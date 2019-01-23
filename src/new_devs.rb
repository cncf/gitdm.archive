require 'csv'
require 'pry'
require './email_code'

def new_devs(files)
  known = {}
  companies = {}
  files.each_with_index do |file, index|
    n = 0
    CSV.foreach(file, headers: true) do |row|
      h = row.to_h
      e = email_encode(h['Email'].strip)
      c = h['Affliation'].strip
      known[e] = 1 if index == 0
      unless known.key?(e)
        known[e] = 1
        n += 1
        companies[c] = 0 unless companies.key?(c)
        companies[c] += 1
      end
    end
    puts "#{index + 1}) #{file}: N=#{n}" if index > 0
  end

  arr = []
  companies.each do |name, n|
    arr << [name, n]
  end
  arr = arr.sort_by { |item| -item[1] }

  ks = %w(company new_devs)
  CSV.open("new_devs.csv", "w", headers: ks) do |csv|
    csv << ks
    arr.each do |row|
      csv << row
    end
  end
end

if ARGV.size < 2
  puts "Missing arguments file1 file2 [file3 [...]]"
  exit(1)
end

new_devs(ARGV)
