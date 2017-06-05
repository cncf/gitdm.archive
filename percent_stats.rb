require 'csv'
require 'pry'
require 'scanf'

def percent_stats(fn)
  csets = []
  lines = []
  File.readlines(fn).each do |line|
    if line.include?('Processed')
      # "Processed 1114 csets from 172 developers\n"
      csets << line.scanf("Processed %d csets from %d developers")
    end
    if line.include?('A total of')
      # "A total of 1864577 lines added, 358891 removed (delta 1505686)\n"
      lines << line.scanf("A total of %d lines added, %d removed (delta %d)")
    end
  end
  ndev = (((csets[1][1].to_f / csets[0][1].to_f) - 1.0) * 100.0).round(2)
  puts "After joining CNCF, number of developers is #{ndev}% higher than before joining" if ndev > 0.0
  puts "After joining CNCF, number of developers is #{-ndev}% lower than before joining" if ndev < 0.0

  ncomm = (((csets[1][0].to_f / csets[0][0].to_f) - 1.0) * 100.0).round(2)
  puts "After joining CNCF, number of commits is #{ncomm}% higher than before joining" if ncomm > 0.0
  puts "After joining CNCF, number of commits is #{-ncomm}% lower than before joining" if ncomm < 0.0

  nloca = (((lines[1][0].to_f / lines[0][0].to_f) - 1.0) * 100.0).round(2)
  puts "After joining CNCF, number of lines of code (LoC) added is #{nloca}% higher than before joining" if nloca > 0.0
  puts "After joining CNCF, number of lines of code (LoC) added is #{-nloca}% lower than before joining" if nloca < 0.0

  nlocr = (((lines[1][1].to_f / lines[0][1].to_f) - 1.0) * 100.0).round(2)
  puts "After joining CNCF, number of lines of code (LoC) removed is #{nlocr}% higher than before joining" if nlocr > 0.0
  puts "After joining CNCF, number of lines of code (LoC) removed is #{-nlocr}% lower than before joining" if nlocr < 0.0
end

if ARGV.size < 1
  puts "Missing argument: prometheus_repos/result.txt"
  exit(1)
end

percent_stats(ARGV[0])
