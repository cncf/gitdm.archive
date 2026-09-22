require 'csv'
require 'json'
require 'pry'
require './comment'
require './email_code'

def gen_aff_files(csv_file)
  # Process affiliations found by Python cncf/gitdm saved in CSV
  # "email","name","company","date_to"
  comps = {}
  emails = {}
  names = {}
  dt_now = DateTime.now.to_date.to_s
  dt_future = DateTime.now.next_year.to_date.to_s
  skip = {}
  if ENV.key?('SKIP_COMPANIES') 
    ENV['SKIP_COMPANIES'].split(',').each do |sk|
      skip[sk] = true
    end
  end
  CSV.foreach(csv_file, headers: true) do |row|
    next if is_comment row
    h = row.to_h
    c = h['company'] = h['company'].strip
    next if skip.key?(c)
    e = h['email'] = email_encode(h['email'].strip)
    n = h['name'] = email_encode(h['name'].strip.gsub(': ', ' '))
    d = h['date_to'] = h['date_to'].strip
    h['date_to'] = d = dt_future if !d || d == ''
    next unless e.include?('!')
    names[n] = {} unless names.key?(n)
    names[n][e] = [] unless names[n].key?(e)
    names[n][e] << h
    emails[e] = [] unless emails.key?(e)
    emails[e] << h
    comps[c] = {} unless comps.key?(c)
    comps[c][n] = {} unless comps[c].key?(n)
    comps[c][n][e] = [] unless comps[c][n].key?(e)
    comps[c][n][e] << h
  end

  # Read mapping `cncf-config/email-map`
  existing_emails = emails.dup
  File.readlines('cncf-config/email-map').each do |line|
    line = line.strip
    next if line[0] == '#'
    arr = line.split ' '
    h = {}
    e = h['email'] = email_encode(arr[0])
    next if existing_emails.key?(e)
    next unless e.include?('!')
    company = arr[1..-1].join ' '
    data = company.split(' < ')
    c = h['company'] = data.first
    next if skip.key?(c)
    d = h['date_to'] = date = data.length > 1 ? data.last : dt_future
    n = h['name'] = email_encode(h['email'])
    names[n] = {} unless names.key?(n)
    names[n][e] = [] unless names[n].key?(e)
    names[n][e] << h
    emails[e] = [] unless emails.key?(e)
    emails[e] << h
    comps[c] = {} unless comps.key?(c)
    comps[c][n] = {} unless comps[c].key?(n)
    comps[c][n][e] = [] unless comps[c][n].key?(e)
    comps[c][n][e] << h
  end

  # Unique
  emails.each do |k, v|
    emails[k] = v.uniq
  end
  comps.each do |k1, v1|
    v1.each do |k2, v2|
      v2.each do |k3, v3|
        comps[k1][k2][k3] = v3.uniq
      end
    end
  end

  wrongs = []
  w = []
  t = ''
  comps.keys.sort.each do |comp_name|
    devs = comps[comp_name]
    t += "#{comp_name}:\n"
    devs.keys.sort.each do |dev_name|
      d_name = dev_name.split('!').first
      email_list = names[dev_name]
      affs = []
      affse = []
      email_list.keys.sort.each do |email|
        affs << emails[email].map { |a| [a['company'], a['date_to']] }.sort_by { |r| r[1] }.reverse
        affse << emails[email].map { |a| [a['email'], a['company'], a['date_to']] }.sort_by { |r| r[2] }.reverse
      end
      # Very important sanity check
      if affs.uniq.count > 1
        h = {}
        h[dev_name] = affse
        wrongs << JSON.pretty_generate(h)
        w << [dev_name, affse]
      end
      ems = {}
      affs.each_with_index do |aff, idx|
        k = aff.clone
        ems[k] = [] unless ems.key?(k)
        ems[k] << affse[idx].first[0]
      end
      ems.each do |affl, lst|
        has_dev = affl.map { |aff| aff[0] }.include?(comp_name)
        next unless has_dev
        t += "\t#{d_name}: #{lst.sort.join(', ')}"
        len = affl.length
        dates = []
        affl.each_with_index do |aff, index|
          next unless aff[0] == comp_name
          from = ''
          if index != len - 1
            from = "from #{affl[index + 1][1]}"
          end
          to = aff[1] == dt_future ? '' : "until #{aff[1]}"
          dates << [from, to].reject { |d| d == '' }.join(' ')
        end
        datestr = dates.reverse.join(', ')
        datestr = ' ' + datestr unless datestr == ''
        t += "#{datestr}\n"
      end
    end
  end
  hdr =  "# This file is derived from developers_affiliations.txt and so should not be edited directly.\n"
  hdr += "# If you see an error, please update developers_affiliations.txt and this file will be fixed\n"
  hdr += "# when regenerated.\n"
  File.write '../company_developers.txt', hdr + t

  t = ''
  names.keys.sort.each do |dev_name|
    d_name = dev_name.split('!').first
    email_list = names[dev_name]
    affs = []
    affse = []
    email_list.keys.sort.each do |email|
      affs << emails[email].map { |a| [a['company'], a['date_to']] }.sort_by { |r| r[1] }.reverse
      affse << emails[email].map { |a| [a['email'], a['company'], a['date_to']] }.sort_by { |r| r[1] }.reverse
    end
    ems = {}
    split = affs.uniq.count == 1 ? '' : '*'
    affs.each_with_index do |aff, idx|
      k = aff.clone
      ems[k] = [] unless ems.key?(k)
      ems[k] << affse[idx].first[0]
    end
    ems.each do |affl, lst|
      t += "#{d_name}#{split}: #{lst.sort.join(', ')}\n"
      affl.each do |aff|
        datestr = aff[1] == dt_future ? '' : " until #{aff[1]}"
        t += "\t#{aff[0]}#{datestr}\n"
      end
    end
  end
  hdr = "# This is the main developers affiliations file.\n"
  hdr += "# If you see your name with asterisk '*' sign - it means that\n"
  hdr += "# multiple affiliations were found for you with different email addresses.\n"
  hdr += "# Please merge all of them into one then.\n"
  hdr += "# Note that email addresses below are \"best effort\" and are out-of-date\n"
  hdr += "# or inaccurate in many cases. Please do not rely on this email information\n"
  hdr += "# without verification.\n"
  File.write '../developers_affiliations.txt', hdr + t

  if wrongs.count > 0
    wrongs = wrongs.uniq
    w = w.uniq
    e = w.select { |r| r[1].any? { |a| a.length > 1 } } # With more than 1 affiliation on any email
    s = w.select { |r| r[1].count > 2 }                 # With more than 2 emails
    nf = w.select { |r| r[1].any? { |a| a.any? { |b| b[1] == 'NotFound' } } }
    se = w.select { |r| r[1].any? { |a| a.any? { |b| b[1] == 'Independent' } } }
    un = w.select { |r| r[1].any? { |a| a.any? { |b| b[1] == '(Unknown)' } } }
    dt = w.select { |r| r[1].any? { |a| a.any? { |b| b[2] != dt_future } } }
    puts 'Special cases found, consider binding.pry it!'
    binding.pry
  end
end

if ARGV.size < 1
  puts "Missing argument: CSV_file (all_affs.csv)"
  exit(1)
end

gen_aff_files(ARGV[0])
