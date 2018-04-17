require 'pry'
require 'json'
require 'csv'
require './comment'
require './email_code'
require './ghapi'

def maintainers(maintainers_file, users_file, config_file)
  # Process maintainers file
  affs = {}
  affs_names = {}
  CSV.foreach(maintainers_file, headers: true) do |row|
    next if is_comment row
    h = row.to_h
    next if h['company'].nil?
    c = h['company'].strip
    l = h['login'].strip
    n = h['name'].strip
    affs[l] = c
    affs_names[l] = n
  end
  # p affs

  # Process JSON file
  data = JSON.parse File.read users_file
  emails = {}
  data.each do |user|
    e = email_encode(user['email'])
    l = user['login']
    emails[l] = [] unless emails.key?(l)
    emails[l] << e
  end
  # p emails

  # Process config
  email = {}
  File.readlines(config_file).each do |line|
    line = line.strip
    next if line[0] == '#'
    arr = line.split ' '
    h = {}
    e = email_encode(arr[0])
    c = arr[1..-1].join ' '
    email[e] = [] unless email.key?(e)
    email[e] << c
  end
  final = {}
  email.each do |e, c|
    c.each do |co|
      final[e] = co unless co.include?(' < ')
    end
    email[e] = c.sort.join(', ')
  end

  # Check/update
  oinited = false
  data = []
  affs.each do |login, company|
    if emails.key?(login)
      ems = emails[login]
      first_affs = nil
      first_email = nil
      miss = []
      ems.each do |em|
        affs_list = email[em]
        if affs_list
          unless first_affs
            first_affs = affs_list
            first_email = em
          end
          if affs_list != first_affs
            STDERR.puts "Affiliations mismatch: first: #{first_affs}(#{first_email}), current: #{affs_list}(#{em}), email list: #{ems}, login: #{login}"
            binding.pry
          end
          if final[em] != company
            STDERR.puts "Final affiliations mismatch: #{affs_list}, should be: #{company}, email list: #{ems}, login: #{login}"
            binding.pry
          end
        else
          STDERR.puts "Missing affiliation: email: #{em}, company: #{company}, login: #{login}"
          miss << em
        end
      end
      if miss.length > 0
        miss.each do |em|
          if first_affs
            first_affs.split(', ').each do |co|
              puts "#{em} #{co}"
            end
          else
            puts "#{em} #{company}"
          end
        end
        STDERR.puts "Correct affiliations generated to STDOUT, redirect them '>> cncf-config/email-map' and then ./sort_configs.sh"
      end
    else
      unless oinited
        octokit_init()
        rate_limit()
        oinited = true
      end
      STDERR.puts "We don't know GitHub login: #{login}, company: #{company}"
      e = "#{login}!users.noreply.github.com"
      name = affs_names[login]
      begin
        u = Octokit.user login
        puts "#{u['email']} #{company}" unless u['email'].nil?
        u['email'] = e
        u['commits'] = 0
        u['affiliation'] = company
        u['name'] = name if u['name'].nil?
        h = u.to_h
        puts "#{e} #{company}"
        data << h
      rescue Octokit::NotFound => err
        STDERR.puts "GitHub API exception"
        next
      end
    end
  end
  if data.length > 0
    # Write JSON back
    json = JSON.pretty_generate data
    fn = 'unknowns.json'
    File.write fn, json
    puts "Written file: #{fn}, update your github_users.json with this new data, then generate stripped.json and update cncf-config/email-map too."
  end
end

if ARGV.size < 3
  puts "Missing arguments: maintainers.csv stripped.json cncf-config/email-map"
  exit(1)
end

maintainers(ARGV[0], ARGV[1], ARGV[2])
