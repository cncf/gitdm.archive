require 'pry'
require 'csv'
require 'json'
require './comment'
require './email_code'

def company_names_mapping(cmap_file, config_file, csv_file, json_file)
  # Read company mapping file `company-names-mapping`
  cmap = {}
  File.readlines(cmap_file).each do |line|
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

  # Parse JSON
  data = JSON.parse File.read json_file
  n_c = 0
  n = data.count
  comps = {}
  data.each do |user|
    a = user['affiliation']
    next unless a
    next if ['-', '', 'NotFound', '?'].include?(a)
    affs = a.split(', ')
    n_affs = []
    affs.each do |aff|
      ary = aff.split(' < ')
      c = ary[0]
      if cmap.key?(c)
        nc = cmap[c]
        if ary.length > 1
          n_affs << "#{nc} < #{ary[1]}"
          puts "#{user['login']}/#{user['email']}/#{ary[1]}: #{c} -> #{nc}"
        else
          n_affs << "#{nc}"
          puts "#{user['login']}/#{user['email']}: #{c} -> #{nc}"
        end
      else
        n_affs << aff
      end
    end
    affs = n_affs.join(', ')
    user['affiliation'] = affs
  end
  # Write JSON back
  pretty = JSON.pretty_generate data
  File.write json_file, pretty

  # Read existing mapping `cncf-config/email-map`
  existing = {}
  lines = ''
  File.readlines(config_file).each do |line|
    line = line.strip
    if line[0] == '#'
      lines += "#{line}\n"
      next
    end
    arr = line.split ' '
    email = email_encode(arr[0])
    company = arr[1..-1].join ' '
    date = ''
    didx = company.index(' < ')
    date = company[didx + 3..-1] if didx
    company = company[0..didx - 1] if didx
    #next if company.strip == 'NotFound' || company.strip[0..11] == 'Independent'
    existing[email] = company
    unless cmap.key?(company)
      lines += "#{line}\n"
      next
    end
    if didx
      lines += "#{email} #{cmap[company]} < #{date}\n"
      puts "#{email}/#{date}: #{company} --> #{cmap[company]}"
    else
      lines += "#{email} #{cmap[company]}\n"
      puts "#{email}: #{company} --> #{cmap[company]}"
    end
  end
  # Write back updated file
  File.write(config_file, lines)

  # Process all_affs.csv file
  hdr = []
  rows = []
  CSV.foreach(csv_file, headers: true) do |row|
    next if is_comment row
    h = row.to_h
    hdr = h.keys if hdr.length == 0
    company = h['company']
    h['source'] = 'config' if ['', nil].include?(h['source'])
    if cmap.key?(company)
      puts "#{h['email']}: #{company} -> #{cmap[company]}"
      h['company'] = cmap[company]
    end
    rows << h
  end
  CSV.open(csv_file, 'w', headers: hdr, force_quotes: true) do |csv|
    csv << hdr
    rows.each do |row|
      # row = Hash[row.map { |k,v| [k,"#{v}"] }]
      csv << row
    end
  end
end

if ARGV.length < 4
  puts "Arguments required: company-names-mapping cncf-config/email-map all_affs.csv github_users.json"
  exit 1
end

company_names_mapping(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
