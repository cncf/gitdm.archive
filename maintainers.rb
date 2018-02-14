require 'pry'
require 'json'
require 'csv'
require './comment'
require './email_code'
require './ghapi'

def maintainers(maintainers_file, users_file, config_file)
  # Process maintainers file
  affs = {}
  CSV.foreach(maintainers_file, headers: true) do |row|
    next if is_comment row
    h = row.to_h
    c = h['company'].strip
    l = h['login'].strip
    affs[l] = c
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
  email.each do |e, c|
    email[e] = c.sort
  end

  # Check/update
  oinited = false
  data = []
  affs.each do |login, company|
    if emails.key?(login)
    else
      unless oinited
        octokit_init()
        rate_limit()
        oinited = true
      end
      puts "We don't know GitHub login: #{login}, company: #{company}"
      e = "#{login}!users.noreply.github.com"
      u = Octokit.user login
      u['email'] = e
      u['commits'] = 0
      u['affiliation'] = company
      h = u.to_h
      data << h
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
