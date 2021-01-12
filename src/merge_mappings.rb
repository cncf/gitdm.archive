def merge(infile1, infile2, outfile)
  # dbg: set to true to have very verbose output
  dbg = !ENV['DBG'].nil?

  cmap = {}
  File.readlines(infile1).each do |line|
    next if line[0] == '#'
    index = line.index(' -> ')
    unless index
      puts "Broken line: #{line}"
      binding.pry
      exit 1
    end
    from = line[0..index - 1].strip
    to = line[index + 4..-1].strip
    next if from == to
    if cmap.key?(from) && cmap[from] != to
      puts "Broken map: already present cmap[#{from}] = #{cmap[from]}, new value different: #{to}"
      binding.pry
      exit 1
    end
    cmap[from] = to
  end
  puts "loaded #{cmap.length} items"
  cmap.each do |from, to|
    while cmap.key?(to)
      newto = cmap[to]
      cmap[from] = newto
      puts "key #{from} -> #{to} -> #{newto}: added: #{from} -> #{newto}"
      to = newto
    end
  end
  File.readlines(infile2).each do |line|
    next if line[0] == '#'
    index = line.index(' -> ')
    unless index
      puts "Broken line: #{line}"
      binding.pry
      exit 1
    end
    from = line[0..index - 1].strip
    to = line[index + 4..-1].strip
    next if from == to
    if cmap.key?(from) && cmap[from] != to
      puts "Broken map: already present cmap[#{from}] = #{cmap[from]}, new value different: #{to}"
      binding.pry
      exit 1
    end
    cmap[from] = to
  end
end

if ARGV.length < 3
  puts "Arguments required: infile1 infile2 outfile"
  exit 1
end

merge(ARGV[0], ARGV[1], ARGV[2])
