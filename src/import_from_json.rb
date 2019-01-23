require 'csv'
require 'pry'
require 'json'
require 'date'
require './mgetc'
require './email_code'

def import_from_json(dom_file, csv_file, json_file, new_domain_map, new_email_map)
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
  # email,company,date_to
  affs = {}
  spec_affs = {}
  CSV.foreach(csv_file, headers: true) do |row|
    h = row.to_h
    e = email_encode(h['email'])
    d = h['date_to']
    c = h['company']
    if ['(Unknown)', 'NotFound', 'Independent'].include?(c)
      unless c == '(Unknown)'
        spec_affs[e] = {} unless spec_affs.key?(e)
        spec_affs[e][d] = c
      end
      next
    end
    affs[e] = {} unless affs.key?(e)
    affs[e][d] = c
  end

  # Parse JSON
  data = JSON.parse File.read json_file


  # Load already processed remap.csv?
  remap = {}
  puts "Load remap config from remap.csv? (y/n)"
  c = mgetc
  if c == 'y'
    CSV.foreach('remap.csv', headers: true) do |row|
      h = row.to_h
      from = h['from'].strip
      to = h['to'].strip
      remap[from] = to
    end
  end

  # Do we need to process domain mappings from JSON?
  puts "Process domain mapping from JSON? (y/n)"
  c = mgetc
  skip = c == 'y' ? false : true
  
  # domain-map
  companies = data['companies']
  always_remap = false
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
          if remap[cn]
            puts "Remap value is '#{remap[cn]}'"
            puts "Use old(o), use new(n), enter new name(e), use remap(r), always remap(a), skip(q)?"
          else
            puts "Use old(o), use new(n), enter new name(e), skip(q)?"
          end
          if always_remap && remap[cn]
            ans = 'r'
          else
            ans = mgetc
          end
          if ans == 'a'
            always_remap = true
            ans = 'r'
          end
          puts "==> #{ans}"
          if ans == 'n'
            doms[d][0] = [cn, nil]
            puts "New company name used"
          elsif ans == 'e'
            puts "Enter new company name for domain '#{d}':"
            nn = STDIN.gets
            puts "==> #{nn}"
            doms[d][0] = [nn.strip, nil]
            puts "Custom company name used"
          elsif ans == 'q'
            puts "Skipping processing"
            skip = true
            next
          elsif ans == 'r'
            unless remap[cn]
              puts "Remap requested for company '#{cn}', but it is not present in remap.csv mapping"
              p remap
              exit
            end
            doms[d][0] = [remap[cn], nil]
            puts "Used value from remap: '#{cn}' -> '#{remap[cn]}'"
          else
            puts "Old company name used"
          end
          puts "New mapping is domain '#{d}' company '#{doms[d][0][0]}'"
        end
        remap[cn] = doms[d][0][0]
      else
        puts "Added new domain mapping: domain '#{d}' company '#{cn}'"
        doms[d] = [[cn, nil]]
      end
    end
  end

  # Do we need to write domain map file?
  puts "Write new domain mapping file: #{new_domain_map}? (y/n)"
  c = mgetc
  # Write new domain mapping
  # domain-map [domain name [< YYYY-MM-DD]
  if c == 'y'
    File.open(new_domain_map, 'w') do |file|
      file.write("# Here is a set of mappings of domain names onto employer names.\n")
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
  end

  # Do we need to write remap.csv file?
  puts "Write new remap.csv file? (y/n)"
  c = mgetc
  if c == 'y'
    hdr = %w(from to)
    CSV.open('remap.csv', "w", headers: hdr) do |csv|
      csv << hdr
      remap.keys.sort.each do |k|
        csv << [k, remap[k]]
      end
    end
  end

  # Load already processed remap_emails.csv?
  remape = {}
  puts "Load remap emails config from remap_emails.csv? (y/n)"
  c = mgetc
  if c == 'y'
    CSV.foreach('remap_emails.csv', headers: true) do |row|
      h = row.to_h
      email = email_encode(h['email'].strip)
      date = h['date'].strip
      company = h['company'].strip
      remape[[email, date]] = company
    end
  end

  # email-map
  users = data['users']
  skip = false
  always_remap = false
  users.each do |u|
    next if skip
    emails = u['emails']
    cs = u['companies']
    emails.each do |e|
      e = email_encode(e)
      next if cs.length < 1 || cs.first == '' || e == ''
      cs.each do |c|
        next if skip
        cn = c['company_name']
        cn = 'Independent' if cn.strip == '*independent'
        cn = '(Robots)' if cn.strip == '*robots'
        # next if ['*robots'].include?(cn.strip)
        cn = remap[cn] if remap.key?(cn)
        cd = c['end_date'] ? Date.parse(c['end_date']).to_s : ''
        if affs.key?(e)
          if affs[e].key?(cd)
            puts "Existing email & date email '#{e}' company '#{cn}', end-date: #{cd}"
            ecn = affs[e][cd]
            unless cn == ecn
              puts "Incompatible data found, existing mapping is:"
              puts "email '#{e}', end-date '#{cd}', company '#{ecn}'"
              puts "New mapping is:"
              puts "email '#{e}', end-date '#{cd}', company '#{cn}'"
              puts "JSON data:"
              p u['companies']
              puts "CSV data"
              p affs[e]
              if remape[[e, cd]]
                puts "Remap value is '#{remape[[e, cd]]}'"
                puts "Use old(o), use new(n), enter new name(e), use remap(r), always remap(a), skip(q)?"
              else
                puts "Use old(o), use new(n), enter new name(e), skip(q)?"
              end
              if always_remap && remape[[e, cd]]
                ans = 'r'
              else
                ans = mgetc
              end
              if ans == 'a'
                always_remap = true
                ans = 'r'
              end
              puts "==> #{ans}"
              if ans == 'n'
                affs[e][cd] = cn
                puts "New company name used"
              elsif ans == 'e'
                puts "Enter new company name for email '#{e}', end-date '#{cd}':"
                nn = STDIN.gets
                puts "==> #{nn}"
                affs[e][cd] = nn.strip
                puts "Custom company name used"
              elsif ans == 'r'
                unless remape[[e, cd]]
                  puts "Remap requested for email '#{e}', date '#{cd}', but it is not present in remap_emails.csv mapping"
                  p remape
                  exit
                end
                affs[e][cd] = remape[[e, cd]]
                puts "Used value from remap email: '#{e}' date '#{cd}' -> '#{remape[[e, cd]]}'"
              elsif ans == 'q'
                puts "Skipping processing"
                skip = true
                next
              else
                puts "Old company name used"
              end
              puts "New mapping is email '#{e}' end-date '#{cd}' company '#{affs[e][cd]}'"
            end
            remape[[e, cd]] = affs[e][cd]
          else
            puts "New date: email '#{e}' company '#{cn}' end-date: #{cd}"
            affs[e][cd] = cn
            #affs[e].keys.sort.each do |dt|
            #  puts "email '#{e}' date '#{dt}' company '#{affs[e][dt]}'"
            #end
          end
        else
          puts "New email '#{e}' company '#{cn}' end-date: #{cd}"
          affs[e] = {}
          affs[e][cd] = cn
        end
      end
    end
  end

  spec_affs.each do |email, data|
    email = email_encode(email)
    data.each do |date, company|
      if affs.key?(email)
        if affs[email].key?(date)
          puts "Updated special case: email '#{email}' end-date '#{date}' company '#{company}' -> '#{affs[email][date]}'"
        else
          affs[email][date] = company
        end
      else
        affs[email] = {}
        affs[email][date] = company
      end
    end
  end

  # Do we need to write remap_emails.csv file?
  puts "Write new remap_emails.csv file? (y/n)"
  c = mgetc
  if c == 'y'
    hdr = %w(email date company)
    CSV.open('remap_emails.csv', "w", headers: hdr) do |csv|
      csv << hdr
      remape.keys.sort.each do |k|
        csv << [k[0], k[1], remape[k]]
      end
    end
  end

  # Write new domain mapping
  # [user@]domain  employer  [< yyyy-mm-dd]
  File.open(new_email_map, 'w') do |file|
    file.write("# Here is a set of mappings of domain names\n")
    file.write("# [user@]domain  employer  [< yyyy-mm-dd]\n")
    affs.keys.sort.each do |email|
      email = email_encode(email)
      dct = affs[email]
      uvals = {}
      ks = dct.keys.sort.reverse
      ks = [''] + (dct.keys - ['']).sort.reverse if dct.keys.include?('')
      ks.each do |date|
        company = affs[email][date]
        if uvals.key?(company)
          puts "email '#{email}', we already have company '#{company}' with date '#{uvals[company]}', skipping new: '#{date}'"
          next
        end
        uvals[company] = date
        if date != ''
          file.write("#{email} #{company} < #{date}\n")
        else
          file.write("#{email} #{company}\n")
        end
      end
    end

    # emails with no final employer
    affs.keys.sort.each do |email|
      email = email_encode(email)
      dct = affs[email]
      unless dct.keys.include?('')
        last_date = dct.keys.sort.reverse.first
        last_empl = affs[email][last_date]
        puts "Email #{email} has no current employer, last was #{last_empl} till #{last_date}"
        # file.write("#{email} Was: #{last_empl}\n")
        file.write("#{email} Independent\n")
      end
    end
  end

end

if ARGV.size < 5
  puts "Missing argument: cncf-config/domain-map stats/all_devs_gitdm.csv ~/dev/stackalytics/etc/default_data.json new-domain-map new-email-map"
  exit(1)
end

import_from_json(ARGV[0], ARGV[1], ARGV[2], ARGV[3], ARGV[4])
