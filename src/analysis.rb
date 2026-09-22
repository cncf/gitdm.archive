require 'scanf'
require 'csv'
require 'pry'

def make_summary(prefix, data)
  data.keys.each do |key|
    sum = 0
    unknown = 0
    perc = 100.0
    n = data[key].keys.length
    data[key].each do |name, value|
      if ['(Unknown)', '(Not Found)'].include?(name)
        unknown += value[0]
        n -= 1
      else
        sum += value[0]
      end
    end
    perc = sum * 100.0 / (sum + unknown)

    hdr = ['N companies', 'sum', 'percent']
    fn = "report/#{prefix}_#{key}_sum.csv"
    CSV.open(fn, "w", headers: hdr) do |csv|
      csv << hdr
      csv << [n, sum, perc]
    end

    data[key]["(All known #{n})"] = [sum, perc.round(2)]
    # [key, n, sum, unknown, perc, "(All known #{n})", data[key]["(All known #{n})"]]
    # binding.pry
  end
end

def map_name(name)
  return '(independent)' if name == 'Independent'
  return '(Not Found)' if name == 'NotFound'
  return name
end

def analysis(args)
  files = args[1..-1]
  prefix = args[0]
  out = {}
  files.each_with_index do |file, index|
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
      if ['changeset', 'lines', 'signoffs', 'employers'].include? mode
        data = line.split(' ')
        data2 = data[-1]
        data3 = data2.scanf('(%f%%)')
        next if data2.length == 0
        perc = data3[0]
        n = data[-2].scanf("%d")[0]
        next if n.to_s != data[-2]
        name = data[0..-3].join(' ')
        out[mode] = {} unless out.key? mode
        if out[mode].key? name
          puts "WARNING: already have [#{mode}][#{name}] = #{out[mode][name]}, new value: #{[n, perc]} in file: #{file}" if out[mode][name] != [n, perc]
        else
          name = map_name(name)
          out[mode][name] = [n, perc]
        end
      end
    end
    # We assume that 1st file is "no map" file, which means file with only Companies and '(Unknown)'
    make_summary(prefix, out) if index == 0
  end

  hdr = ['idx', 'company', 'n', 'percent']
  out.keys.each do |key|
    arr = []
    out[key].each do |name, value|
      arr << [name, value[0], value[1]]
    end
    arr = arr.sort_by { |item| -item[1] }

    fn = "report/#{prefix}_#{key}_all.csv"
    CSV.open(fn, "w", headers: hdr) do |csv|
      csv << hdr
      arr.each_with_index { |row, index| csv << [index] + row }
    end

    fn = "report/#{prefix}_#{key}_top.csv"
    required = ['(Unknown)', 'Gmail *', 'Qq *', 'Outlook *', 'Yahoo *', 'Hotmail *', '(Independent)', '(Not Found)']
    CSV.open(fn, "w", headers: hdr) do |csv|
      csv << hdr
      arr.each_with_index do |row, index|
        csv << [index] + row if index <= 20 || required.include?(row[0])
      end
    end
  end
end

if ARGV.size < 2
  puts "Missing arguments prefix file1 [file2 [ file3 [...]]]"
  exit(1)
end

analysis(ARGV)
