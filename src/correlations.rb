require 'pry'
require 'csv'
require 'json'

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

def correlations(input_file, input_type, company_column)
  min_correlation = 81.0

  affs = {}
  # skip_set = ['Independent', 'NotFound', '?', '(Unknown)', 'Funky']
  skip_set = []
  if input_type == 'csv'
    CSV.foreach(input_file, headers: true) do |row|
      h = row.to_h
      a = h[company_column]
      next if !a || skip_set.include?(a)
      a = a.strip
      affs[a] = 0 unless affs.key?(a)
      affs[a] += 1
    end
  elsif input_type == 'json'
    data = JSON.parse File.read input_file
    data.each do |row|
      h = row.to_h
      saff = h[company_column]
      next if saff.nil?
      saff.split(', ').each do |aff|
        ary = aff.split('<').map(&:strip)
        a = ary[0]
        next if !a || skip_set.include?(a)
        a = a.strip
        affs[a] = 0 unless affs.key?(a)
        affs[a] += 1
      end
    end
  elsif input_type == 'cfg'
    File.readlines(input_file).each do |row|
      next if row[0] == '#'
      vals = row.split ' '
      em = vals[0]
      ary = vals[1..-1].join(' ').split(' < ')
      com = ary[0]
      vals = [em, com]
      a = vals[company_column.to_i]
      next if !a || skip_set.include?(a)
      a = a.strip
      affs[a] = 0 unless affs.key?(a)
      affs[a] += 1
    end
  end
  affs.each do |a, n|
    sa = a.split(/(?=[A-Z])/).reject { |s| s.length < 3 }.map(&:strip)
    if sa.length > 1
      s = sa.join ' '
      if s != a
        puts "#{a} is similar to #{s}" if affs.key?(s)
      end
    end
  end

  affs2 = {}
  specials = %w(
    corporation limited company development technologies solutions
    consulting systems international software university networks
    financial group informatics consultancy commerce services
    engineering security business entertainment research technologie
    associates investments electronics healthcare design network
  ).uniq
  specials += [
    ' inc', 'gmbh', ' llc', ' zoo', ' ltd', ' labs', ' cloud', ' ag',
    ' it', 'cloud ', ' lp', 'ab', ' corp', ' co', 'the ', ' pvt', ' sa',
    '.com', '.net', '.inc', 'io'
  ].uniq
  affs.each do |a, n|
    c = a.downcase.gsub(/[^0-9a-z ]/, '')
    specials.each do |s|
      c = c.gsub(s, '')
    end
    c = c.gsub(/\s+/, ' ').strip
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

if ARGV.size < 3
  puts "Missing argument: file (file.csv or file.json) file type (cfg, csv or json) company_column (index (1), company, affiliation)"
  exit(1)
end

correlations(ARGV[0], ARGV[1], ARGV[2])
