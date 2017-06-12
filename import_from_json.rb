require 'csv'
require 'pry'
require 'json'
require 'scanf'

def mgetc()
  begin
    system("stty raw -echo")
    str = STDIN.getc
  ensure
    system("stty -raw echo")
  end
  str.chr
end

def import_from_json(dom_file, csv_file, json_file, new_domain_map)
  # domain-map [domain name [< YYYY-MM-DD]
  # ansolabs.com Nebula
  # ansolabs.com Rackspace < 2012-07-20
  doms = {}
  File.readlines(dom_file).each do |line|
    line = line.strip
    next if line == ''
    next if line[0] == '#'
    arr = line.split
    dom = arr[0]
    name = arr[1..-1].join ' '
    date = nil
    if arr.length > 3 && arr[-2] == '<'
      name = arr[1..-3].join ' '
      date = arr[-1]
    end
    doms[dom] = [] unless doms.key?(dom)
    doms[dom] << [name, date]
  end

  # email,company,final_company,date_from,date_to
  affs = {}
  CSV.foreach(csv_file, headers: true) do |row|
    h = row.to_h
    e = h['email']
    affs[e] = [] unless affs.key?(e)
    affs[e] << h
  end

  # JSON
  data = JSON.parse File.read json_file

  # domain-map
  companies = data['companies']
  skip = false
  companies.each do |c|
      next if skip
    cn = c['company_name']
    ds = c['domains']
    next if ds.length < 1 || ds.first == '' || cn == ''
    ds.each do |d|
      next if skip
      if doms.key?(d)
        if doms[d].length > 1
          puts "Special case detected - must be analysed manually"
          puts "Existing data"
          p doms[d]
          puts "New data:"
          p c
          next
        end
        ecn = doms[d][0][0]
        unless cn == ecn
          puts "Incompatible data found, existing mapping is:"
          puts "domain '#{d}', company '#{ecn}'"
          puts "New mapping is:"
          puts "domain '#{d}', company '#{cn}'"
          puts "JSON data:"
          p c
          puts "Use old(o), use new(n), enter new name(e), skip(q)?"
          c = mgetc
          puts "==> #{c}"
          if c == 'n'
            doms[d][0] = [cn, nil]
            puts "New company name used"
          elsif c == 'e'
            puts "Enter new company name for domain '#{d}':"
            nn = STDIN.gets
            puts "==> #{nn}"
            doms[d][0] = [nn.strip, nil]
            puts "Custom company name used"
          elsif c == 'q'
            skip = true
            next
          else
            puts "Old company name used"
          end
          puts "New mapping is domain '#{d}' company '#{doms[d][0][0]}'"
        end
      else
        puts "Added new domain mapping: domain '#{d}' company '#{cn}'"
        doms[d] = [[cn, nil]]
      end
    end
  end

  # Write new domain mapping
  # domain-map [domain name [< YYYY-MM-DD]
  File.open(new_domain_map, 'w') do |file|
    file.write("# domain-map [domain name [< YYYY-MM-DD]\n")
    doms.each do |d, list|
      list.each do |row|
        if row[1]
          file.write("#{d} #{row[0]} < #{row[1]}\n")
        else
          file.write("#{d} #{row[0]}\n")
        end
      end
    end
  end

  binding.pry
end

if ARGV.size < 4
  puts "Missing argument: cncf-config/domain-map stats/all_devs_gitdm.csv ~/dev/stackalytics/etc/default_data.json new-domain-map"
  exit(1)
end

import_from_json(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
