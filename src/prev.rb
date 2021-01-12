require 'pry'

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
  final = {}
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
    final[from] = to
  end
  nmap = {}
  cmap.each do |from, to|
    i = 0
    nmap[from] = to
    while cmap.key?(to)
      i += 1
      newto = cmap[to]
      nmap[from] = newto
      puts "key(#{i}) #{from} -> #{to} -> #{newto}: added: #{from} -> #{newto}"
      if from == newto
        nmap.delete(from)
        puts "deleted ciurcular key #{from}"
        break
      end
      if i > 1
        nmap.delete(from)
        puts "loop, deleted key #{from}"
        if final.key?(to)
          if from != final[to]
            nmap[from] = final[to] 
            puts "Using value from key to: #{to}, #{from} -> #{nmap[from]}"
          end
          if newto != final[to]
            nmap[newto] = final[to]
            puts "Using value from key to: #{to}, #{newto} -> #{nmap[from]}"
          end
        end
        if final.key?(newto)
          if from != final[newto]
            nmap[from] = final[newto]
            puts "Using value from key newto: #{newto}, #{from} -> #{nmap[from]}"
          end
          if to != final[newto]
            nmap[to] = final[newto]
            puts "Using value from key newto: #{newto}, #{to} -> #{nmap[from]}"
          end
        end
        puts "loop fixed"
        break
      end
      to = newto
    end
  end
  binding.pry
end

if ARGV.length < 3
  puts "Arguments required: infile1 infile2 outfile"
  puts "infile2 is higher priority"
  exit 1
end

merge(ARGV[0], ARGV[1], ARGV[2])
