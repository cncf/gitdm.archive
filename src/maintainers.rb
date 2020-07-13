require 'pry'
require 'json'
require 'csv'
require './comment'
require './email_code'
require './ghapi'
require './mgetc'

def maintainers(maintainers_file, users_file, config_file)
  dbg = !ENV['DBG'].nil?
  onlynew = !ENV['ONLYNEW'].nil?
  # Process maintainers file
  affs = {}
  affs_names = {}
  CSV.foreach(maintainers_file, headers: true) do |row|
    next if is_comment row
    h = row.to_h
    next if h['company'].nil? || h['login'].nil?
    c = h['company'].strip
    l = h['login'].strip.downcase
    n = h['name'].strip
    affs[l] = c
    affs_names[l] = n
  end
  # p affs

  # Process JSON file
  data = JSON.parse File.read users_file
  emails = {}
  data.each do |user|
    e = email_encode(user['email']).downcase
    l = user['login'].downcase
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
    e = email_encode(arr[0]).downcase
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
  gcs = []
  hint = -1
  rpts = 0
  new_affs = ''
  del_affs = ''
  affs.each do |login, company|
    if emails.key?(login)
      next if onlynew
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
            STDERR.puts "#{em} affiliations mismatch:\nfirst:   '#{first_affs}' email: #{first_email}\ncurrent: '#{affs_list}' email: #{em}\nEmail list: #{ems}, login: #{login}, maintainer company: #{company}, use first, current, maintainer, skip f/c/m/s?"
            upd = mgetc
            if upd == 'c' || upd == 'C'
              STDERR.puts 'Updated to current'
              first_affs = affs_list
              first_email = em
            end
            if upd == 'm' || upd == 'M'
              STDERR.puts 'Updated to maintainer'
              first_affs = company
              first_email = 'M'
            end
            break if upd == 's' || upd == 'S'
          end
          if final[em] != company
            STDERR.puts "#{em} final affiliation '#{final[em]}' mismatch: '#{affs_list}', should be: #{company}\nemail list: #{ems}, login: #{login}, add to delete list?"
            upd = mgetc
            if upd == 'y' || upd == 'Y'
              del_affs += "#{em} #{final[em]}\n" 
            end
          end
        else
          STDERR.puts "Missing affiliation: email: #{em}, company: #{company}, login: #{login}" if dbg
          miss << em
        end
      end
      if miss.length > 0
        miss.each do |em|
          if first_affs
            first_affs.split(', ').each do |co|
              new_affs += "#{em} #{co}\n"
            end
          else
            new_affs += "#{em} #{company}\n"
          end
        end
      end
    else
      unless oinited
        gcs = octokit_init()
        hint = rate_limit(gcs)[0]
        oinited = true
      end
      STDERR.puts "We don't know GitHub login: #{login}, company: #{company}, asking GitHub"
      e = "#{login}!users.noreply.github.com"
      name = affs_names[login]
      begin
        if rpts <= 0
          hint, rem, pts = rate_limit(gcs)
          rpts = pts / 10
          puts "Allowing #{rpts} calls without checking rate"
        else
          rpts -= 1
          puts "#{rpts} calls remain before next rate check"
        end
        u = gcs[hint].user login
        new_affs += "#{u['email']} #{company}\n" unless u['email'].nil?
        u['email'] = e
        u['commits'] = 0
        u['affiliation'] = company
        u['name'] = name if u['name'].nil?
        h = u.to_h
        new_affs += "#{e} #{company}\n"
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
    STDERR.puts "Written file: #{fn}, update your github_users.json with this new data, then generate stripped.json and update cncf-config/email-map too."
  end
  if new_affs != ''
    File.write 'email-map', new_affs
    STDERR.puts 'email-map written, you should add its contents to cncf-config/email-map \'>> cncf-config/email-map\' and then ./sort_configs.sh'
  end
  if del_affs != ''
    File.write 'delete.txt', del_affs
    STDERR.puts 'delete.txt written, you should add its contents to cncf-config/email-map'
  end
end

if ARGV.size < 3
  puts "Missing arguments: maintainers.csv stripped.json cncf-config/email-map"
  exit(1)
end

maintainers(ARGV[0], ARGV[1], ARGV[2])
