require 'csv'
require 'pry'

def analysis(fn)
  # "Name","Email","Affliation","Date","Added","Removed","Changesets"
  added = []
  removed = []
  changesets = []
  CSV.foreach(fn, headers: true) do |row|
    h = row.to_h
    added << [h['Added'].to_i, h]
    removed << [h['Removed'].to_i, h]
    changesets << [h['Changesets'].to_i, h]
  end

  added = added.sort_by { |item| -item[0] }
  removed = removed.sort_by { |item| -item[0] }
  changesets = changesets.sort_by { |item| -item[0] }
  %w(added removed changesets).each do |obj|
    fn = "#{obj}.csv"
    obj = binding.local_variable_get(obj)
    CSV.open(fn, "w", headers: obj[0][1].keys) do |csv|
      csv << obj[0][1].keys
      obj.each do |row|
        csv << row[1].values
      end
    end
  end
end

if ARGV.size < 1
  puts "Missing argument: devs_csv_file.csv"
  exit(1)
end

analysis(ARGV[0])
