require 'csv'
require 'json'
require 'pry'

def cleanup(all_affs, all_changesets, json_file, aliases, email_map)
  contrib = {}
  CSV.foreach(all_changesets, headers: true) do |row|
    h = row.to_h
    email = h['Email'].strip
    contrib[email] = true
  end

  data = JSON.parse File.read json_file
  logins = {}
  emails = {}
  data.each do |user|
    login = user['login'].strip
    email = user['email'].strip
    emails[login] = [] unless emails.key?(login)
    emails[login] << email
    puts "One email #{email} maps to multiple logins: #{login}, #{logins[email]}" if logins.key?(email)
    logins[email] = login
  end
 
  doms = {}
  File.readlines(aliases).each do |line|
    line = line.strip
    next if line == ''
    next if line[0] == '#'
    arr = line.split.map(&:strip)
    email1 = arr[0]
    email2 = arr[1]
    contrib[email1] = true if contrib.key?(email2)
  end

  non_contrib = {}  
  CSV.foreach(all_affs, headers: true) do |row|
    h = row.to_h
    email = h['email'].strip
    unless contrib.key?(email)
      found = false
      login = logins[email]
      if login
	ems = emails[login]
	ems.each do |em|
          next if em == email
	  if contrib.key?(em)
            # puts "Found after JSON aliasing #{email} --> #{em}"
            found = true
	    break
	  end
	end
	if found
          ems.each { |em| contrib[em] = true }
	else
          non_contrib[email] = false
	end
      else
        # puts "Unknown github login for email #{email}" 
        non_contrib[email] = false
      end
    end
  end
  p [contrib.count, non_contrib.count]
end

if ARGV.size < 3
	puts "Missing arguments: all_affs.csv all_changesets.csv github_users.json cncf-config/aliases cncf-config/email-map"
  exit(1)
end

cleanup(ARGV[0], ARGV[1], ARGV[2], ARGV[3], ARGV[4])

