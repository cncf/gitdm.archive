require 'pry'
require 'json'

def run(company, date, new_company)
  lines = []
  File.readlines('cncf-config/email-map').each do |l|
    line = l.strip
    if line.length > 0 && line[0] == '#'
      lines << l
      next
    end
    ary = line.split ' '
    unless ary && ary[0] && ary[1]
      lines << l
      next
    end
    curr = ary[1..-1].map(&:strip).join(' ')
    unless curr == company
      lines << l
      next
    end
    new_l = "#{ary[0]} #{company} < #{date}\n"
    lines << new_l
    new_l = "#{ary[0]} #{new_company}\n"
    lines << new_l
  end
  File.write 'cncf-config/email-map', lines.join('')

  # Parse JSON
  data = JSON.parse File.read 'github_users.json'

  data.each do |user|
    next if user['affiliation'].nil? || user['affiliation'] == ''
    affs = user['affiliation']
    next if !affs.end_with?(company)
    affs += " < #{date}, #{new_company}"
    user['affiliation'] = affs
  end

  pretty = JSON.pretty_generate data
  File.write 'github_users.json', pretty
end

if ARGV.size < 3
  puts "Missing arguments: company_name date new_company"
  exit(1)
end

run(ARGV[0], ARGV[1], ARGV[2])
