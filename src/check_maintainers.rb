require 'pry'
require 'json'
require 'csv'
require './comment'
require './email_code'
require './ghapi'
require './mgetc'

def maintainers(maintainers_file, users_file)
  dbg = !ENV['DBG'].nil?
  # Process maintainers file
  affs = {}
  CSV.foreach(maintainers_file, headers: true) do |row|
    next if is_comment row
    h = row.to_h
    next if h['company'].nil? || h['login'].nil?
    c = h['company'].strip
    l = h['login'].strip.downcase
    n = h['name'].strip
    affs[l] = c
  end

  # Process JSON file
  data = JSON.parse File.read users_file
  emails = {}
  daffs = {}
  data.each_with_index do |user, idx|
    e = email_encode(user['email']).downcase
    l = user['login'].strip.downcase
    a = user['affiliation']
    emails[l] = [] unless emails.key?(l)
    emails[l] << e
    daffs[l] = [a, idx] unless daffs.key?(l)
    unless a.nil? || ['', '(Unknown)', 'NotFound', '?'].include?(a) || a == daffs[l][0]
      puts "#{l}: conflict: #{a} vs. #{daffs[l][0]} (#{idx} - #{daffs[l][1]}}" if dbg
    end
  end
  
  # Check
  affs.each do |l, c|
    unless daffs.key?(l)
      puts "Add login=#{l}, company=#{c}" if dbg
      next
    end
    ec = daffs[l][0] || ''
    if ec != c
      a = ec.split ', '
      last = a.last
      if last != c
        puts "check login: #{l}: current: '#{last}' (#{ec}), maintainers file: '#{c}'"
      else
        puts "#{l}: last company match: '#{ec}' - '#{c}'" if dbg
      end
    else
      puts "#{l} - #{c}: exact match" if dbg
    end
  end

end

if ARGV.size < 2
  puts "Missing arguments: maintainers.csv github_users.json"
  exit(1)
end

maintainers(ARGV[0], ARGV[1])

