require 'csv'
require 'pry'

def analysis(fn)
  # "Name","Email","Affliation","Date","Added","Removed","Changesets"
  obj = {}
  aff = {}
  sa = sr = sc = 0
  unknowns = {}
  goo = {}
  companies = {}
  sums = %w(added removed changesets)
  CSV.foreach(fn, headers: true) do |row|
    h = row.to_h
    h.each do |k, v|
      h[k] = v.to_i if v.to_i.to_s == v
    end
    a = h['Added']
    r = h['Removed']
    c = h['Changesets']
    e = h['Email']
    d = h['Date']
    co = h['Affliation'].to_s
    sa += a
    sr += r
    sc += c
    if obj.key?(e)
      obj[e].each do |k, v|
        obj[e][k] += h[k] unless v.is_a?(String)
      end
    else
      obj[e] = h
    end
    # If run with: kubernetes/all_time/first_run_patch.csv
    em = h['Affliation']
    if em == '(Unknown)'
      unknowns[h['Name']] = h
    elsif em == 'Google' && !e.include?('@google.com')
      goo[h['Name']] = h
    end
    companies[co] = [] unless companies.key?(co)
    companies[co] << e
  end

  companies.each do |company, emails|
    companies[company] = emails.sort.uniq
  end

  ary = []
  companies.each do |company, emails|
      ary << [company, emails, emails.length]
  end
  ary = ary.sort_by { |item| -item[2] }

  hdr = %w(company n emails)
  CSV.open('companies_by_count.csv', 'w', headers: hdr) do |csv|
    csv << hdr
    ary.each { |item| csv << [item[0], item[2], item[1].join(', ')] }
  end

  ary = ary.sort_by { |item| item[0].downcase.strip }
  CSV.open('companies_by_name.csv', 'w', headers: hdr) do |csv|
    csv << hdr
    ary.each { |item| csv << [item[0], item[2], item[1].join(', ')] }
  end

  unknowns = unknowns.values.sort_by { |item| item['Name'] }
  goo = goo.values.sort_by { |item| item['Name'] }

  File.open('unknown_devs.txt', 'w') do |file|
    unknowns.each do |dev|
      file.write("#{dev['Name']} <#{dev['Email']}>\n")
    end
  end

  File.open('google_other.txt', 'w') do |file|
    goo.each do |dev|
      file.write("#{dev['Name']} <#{dev['Email']}>\n")
    end
  end

  hdr = %w(email name)
  CSV.open('unknown_devs.csv', 'w', headers: hdr) do |csv|
    csv << hdr
    unknowns.each { |dev| csv << [dev['Email'], dev['Name']] }
  end

  hdr = %w(email)
  CSV.open('unknown_emails.csv', 'w', headers: hdr) do |csv|
    csv << hdr
    unknowns.each { |dev| csv << [dev['Email']] }
  end

  added = []
  removed = []
  changesets = []
  obj.each do |k, v|
    a = v['Added']
    r = v['Removed']
    c = v['Changesets']
    e = v['Email']
    added << [a, v]
    removed << [r, v]
    changesets << [c, v]
  end

  added = added.sort_by { |item| -item[0] }
  removed = removed.sort_by { |item| -item[0] }
  changesets = changesets.sort_by { |item| -item[0] }

  ks = added[0][1].keys + ['% Added', '% Removed', '% Changesets']
  sums.each do |key|
    fn = "#{key}.csv"
    data = binding.local_variable_get(key)
    CSV.open(fn, "w", headers: ks) do |csv|
      csv << ks
      data.each do |row|
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
