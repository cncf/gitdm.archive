require 'csv'
require 'pry'

def new_devs(files)
  known = {}
  files.each_with_index do |file, index|
    n = 0
    CSV.foreach(file, headers: true) do |row|
      h = row.to_h
      e = h['Email'].strip
      known[e] = 1 if index == 0
      if known.key?(e)
        known[e] += 1
      else
        known[e] = 1
        n += 1
      end
    end
    p n if index > 0
  end
end

if ARGV.size < 2
  puts "Missing arguments file1 file2 [file3 [...]]"
  exit(1)
end

new_devs(ARGV)
