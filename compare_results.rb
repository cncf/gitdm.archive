require 'csv'
require 'pry'

def compare_results(f1, f2)
  # email,company,final_company,date_from,date_to
  CSV.foreach(f1, headers: true) do |row|
    h = row.to_h
  end
end

if ARGV.size < 2
  puts "Missing arguments: stats/all_changesets.csv facade_kubernetes.csv"
  exit(1)
end

compare_results(ARGV[0], ARGV[1])
