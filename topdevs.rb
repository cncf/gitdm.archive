require 'csv'
require 'pry'

def analysis(fn)
  # "Name","Email","Affliation","Date","Added","Removed","Changesets"
  added = []
  removed = []
  changesets = []
  sa = sr = sc = 0
  CSV.foreach(fn, headers: true) do |row|
    h = row.to_h
    a = h['Added'].to_i
    r = h['Removed'].to_i
    c = h['Changesets'].to_i
    sa += a
    sr += r
    sc += c
    added << [a, h]
    removed << [r, h]
    changesets << [c, h]
  end

  added = added.sort_by { |item| -item[0] }
  removed = removed.sort_by { |item| -item[0] }
  changesets = changesets.sort_by { |item| -item[0] }
  ks = added[0][1].keys + ['% Added', '% Removed', '% Changesets']
  %w(added removed changesets).each do |obj|
    fn = "#{obj}.csv"
    obj = binding.local_variable_get(obj)
    CSV.open(fn, "w", headers: ks) do |csv|
      csv << ks
      obj.each do |row|
        pa = (row[1]['Added'].to_f * 100.0 / sa).round(3)
        pr = (row[1]['Removed'].to_f * 100.0 / sr).round(3)
        pc = (row[1]['Changesets'].to_f * 100.0 / sc).round(3)
        csv << row[1].values + [pa, pr, pc]
      end
    end
  end
end

if ARGV.size < 1
  puts "Missing argument: devs_csv_file.csv"
  exit(1)
end

analysis(ARGV[0])
