require 'pry'
require 'csv'

def correlation_metric(strings)
  shortest = strings.min_by(&:length)
  longest = strings.max_by(&:length)
  maxlen = shortest.length
  maxlen.downto(0) do |len|
    0.upto(maxlen - len) do |start|
      substr = shortest[start,len]
      if strings.all? { |str| str.include? substr }
        return 100.0 * (substr.length.to_f / longest.length.to_f).round(2)
      end
    end
  end
  return 0.0
end

def correlations(csv_file)
  min_correlation = 61.0

  affs = {}
  skip_set = ['Self', 'NotFound', '?', '(Unknown)', 'Funky']
  CSV.foreach(csv_file, headers: true) do |row|
    h = row.to_h
    a = h['company']
    next if !a || skip_set.include?(a)
    a = a.strip
    affs[a] = 0 unless affs.key?(a)
    affs[a] += 1
  end

  affs2 = {}
  specials = %w(
    corporation limited company development technologies solutions
    consulting systems international software university networks
    financial group informatics consultancy commerce services
    engineering security business entertainment research technologie
    associates investments electronics healthcare
  ).uniq
  specials += [
    ' inc', 'gmbh', ' llc', ' zoo', ' ltd', ' labs', ' cloud', ' ag',
    ' it', 'cloud ', ' lp', 'ab', ' corp', ' co', 'the ', ' pvt', ' sa',
    '.com'
  ].uniq
  affs.each do |a, n|
    c = a.downcase.gsub(/[^0-9a-z ]/, '').gsub(/\s+/, ' ')
    specials.each do |s|
      c = c.gsub(s, '')
    end
    c = c.strip
    affs2[c] = [] unless affs2.key?(c)
    affs2[c] << [a, n]
  end

  if affs2.key? ''
    puts "Those companies are unmappable to ASCII only symbols"
    p affs2['']
  end

  affs2.each do |k, v|
    next if v.length < 2 || k == ''
    puts "Those companies map into the same key '#{k}':"
    p v
  end

  ks = affs2.keys.reject { |k| k.strip == '' }.sort
  nk = ks.length
  corrs = []
  checked = {}
  ks.each_with_index do |k1, i|
    # puts "#{i}/#{nk}" if i % 50 == 0
    ks.each do |k2|
      next if k1 == k2 || checked.key?([k2, k1])
      checked[[k1, k2]] = true
      corrs << [k1, k2, correlation_metric([k1, k2])]
    end
  end
  corrs = corrs.sort_by { |row| -row[2] }.reject { |row| row[2] < min_correlation }

  puts "Similar mappings > #{min_correlation}% similar:"
  corrs.each do |corr|
    p [corr[2], affs2[corr[0]], affs2[corr[1]], "#{corr[0]} <> #{corr[1]}"]
  end
end

if ARGV.size < 1
  puts "Missing argument: CSV_file aliases (all_affs.csv)"
  exit(1)
end

correlations(ARGV[0])
