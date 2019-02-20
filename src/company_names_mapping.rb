require 'pry'
require 'json'
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

  # Read existing mapping `cncf-config/email-map` - it has higher priority
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
end

if ARGV.length < 4
  puts "Arguments required: company-names-mapping cncf-config/email-map all_affs.csv github_users.json"
  exit 1
end

company_names_mapping(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
