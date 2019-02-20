require 'pry'
require 'json'
require './email_code'

def import_from_github_json(json_file)
  # Read company mapping file `company-names-mapping`
  cmap = {}
  File.readlines('company-names-mapping').each do |line|
    next if line[0] == '#'
    index = line.index(' -> ')
    unless index
      puts "Broken line: #{line}"
      binding.pry
      exit 1
    end
    from = line[0..index - 1].strip
    to = line[index + 4..-1].strip
    if cmap.key?(from) && cmap[from] != to
      puts "Broken map: already present cmap[#{from}] = #{cmap[from]}, new value different: #{to}"
      binding.pry
      exit 1
    end
    cmap[from] = to
  end

  # Read existing mapping `cncf-config/email-map` - it has higher priority
  existing = {}
  File.readlines('cncf-config/email-map').each do |line|
    line = line.strip
    next if line[0] == '#'
    arr = line.split ' '
    email = email_encode(arr[0])
    company = arr[1..-1].join ' '
    didx = company.index(' < ')
    company = company[0..didx - 1] if didx
    next if company.strip == 'NotFound' || company.strip[0..11] == 'Independent'
    existing[email] = company
  end

  # Parse JSON
  data = JSON.parse File.read json_file
  n_c = 0
  n = data.count
  comps = {}
  data.each do |user|
    c = user['company']
    next unless c
    next if ['-', ''].include?(c)
    c = c.strip
    c = c[1..-1] if ['@', '!'].include?(c[0])
    next unless cmap[c]
    c = cmap[c]
    n_c += 1
    comps[c] = [] unless comps.key?(c)
    comps[c] << email_encode(user['email'].strip)
  end
  n_unique = comps.keys.count
  puts "Found #{n_c}/#{n} affiliations, #{n_unique} unique"

  the_same = different = new_affs = 0
  diffs = {}
  File.open('new-email-map', 'w') do |file|
    comps.keys.sort.each do |company_name|
      comps[company_name].sort.each do |email|
        email = email_encode(email)
        if existing.key?(email)
          if existing[email] == company_name
            the_same += 1
          else
            exist = existing[email]
            puts "Different values existing: #{exist}, new #{company_name} for email: #{email}"
            different += 1
            diffs[exist] = {} unless diffs.key?(exist)
            diffs[exist][company_name] = 0 unless diffs[exist].key?(company_name)
            diffs[exist][company_name] += 1
          end
        else
          new_affs += 1
          file.write("#{email} #{company_name}\n")
        end
      end
    end
  end
  puts "New affiliations: #{new_affs}, the same: #{the_same}, conflicts: #{different}"
  diffs.keys.sort_by { |i| i.downcase }.each do |c|
    output = diffs[c].keys.length > 1
    unless output
      diffs[c].keys.sort_by { |j| j.downcase }.each do |c2|
        if diffs[c][c2] > 1
          output = true
          break
        end
      end
    end
    if output
      s = c + ': ['
      s += diffs[c].keys.sort_by { |j| j.downcase }.join(', ')
      s += ']'
      puts s
    end
  end

  # File.open('company-names', 'w') do |file|
  #   comps.keys.sort_by { |i| i.downcase }.each do |company_name|
  #     file.write("#{company_name} -> #{company_name}\n")
  #   end
  # end
  puts "Note that this import only attempts to find affiliation from GitHub 'company' field and only maps companies defined in 'company-names-mapping' file."
end

if ARGV.size < 1
  puts "Missing argument: JSON file"
  exit(1)
end

import_from_github_json(ARGV[0])
