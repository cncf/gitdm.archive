require 'csv'
require 'pry'
require 'scanf'

def map_name(name)
  return '(Independent)' if name == 'Independent'
  return '(Not Found)' if name == 'NotFound'
  return name
end

def stacked_chart(args)
  files = args[2..-1]
  smode = args[0]
  pmode = args[1]
  percent_mode = pmode == 'p'
  out = {}
  files.each do |file|
    key = file
    if smode == 'm'
      d1 = Date.parse(file[-25..-16])
      d2 = Date.parse(file[-14..-5])
      days =  (d2 - d1).to_i
      next unless days >= 28 && days <= 31
      key = d1.to_s[0..-4]
    else
      key = file[18..23]
    end
    mode = ''
    File.readlines(file).each do |line|
      line = line.strip
      if line == ''
        mode = ''
        next
      end
      if line.downcase.include? 'top changeset contributors by employer'
        mode = 'changeset'
        next
      elsif line.downcase.include? 'top lines changed by employer'
        mode = 'lines'
        next
      elsif line.downcase.include? 'employers with the most signoffs'
        mode = 'signoffs'
        next
      elsif line.downcase.include? 'employers with the most hackers'
        mode = 'employers'
        next
      end
      if mode == 'changeset'
        data = line.split(' ')
        data2 = data[-1]
        data3 = data2.scanf('(%f%%)')
        next if data2.length == 0
        perc = data3[0]
        n = data[-2].scanf("%d")[0]
        next if n.to_s != data[-2]
        name = data[0..-3].join(' ')
        out[key] = {} unless out.key?(key)
        name = map_name(name)
        out[key][name] = [n, perc]
      end
    end
  end
  
  companies = {}
  n_keys = out.keys.length.to_f
  out.each do |key, data|
    data.each do |company, values|
      companies[company] = 0.0 unless companies.key?(company)
      if percent_mode
        companies[company] += values[1] / n_keys
      else
        companies[company] += values[0]
      end
    end
  end

  companies.each do |company, value|
    companies[company] = value.round(1)
  end

  ary = []
  companies.each do |company, value|
    ary << [company, value.round(1)]
  end
  ary = ary.sort_by { |row| -row[1] }[0...10].map { |row| row[0] }

  hdr = [smode == 'm' ? 'Date' : 'Version'] + ary + ['Others']
  ofname = "stacked_chart_#{smode == 'm' ? 'months' : 'rels'}_#{percent_mode ? 'perc' : 'csets'}.csv"
  CSV.open(ofname, "w", headers: hdr) do |csv|
    csv << hdr
    out.keys.sort.each do |key|
      data = out[key]
      sum = 0.0
      others = 0
      row = [key]
      unless percent_mode
        (data.keys - ary).each do |other|
          others += data[other][0]
        end
      end
      ary.each do |company|
        values = data[company] || [0, 0]
        if percent_mode
          val = values[1]
        else
          val = values[0]
        end
          sum += val
        row << val
      end
      others = (100.0 - sum).round(1) if percent_mode
      row << others
      csv << row
      # p row
    end
  end
end

if ARGV.size < 1
  puts "Missing arguments: list of test files"
  exit(1)
end

stacked_chart(ARGV)
