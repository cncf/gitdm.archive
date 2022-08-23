#!/usr/bin/env ruby

require 'pry'
require 'json'
require 'octokit'
require 'concurrent'
require 'unidecoder'
require 'pg'
require './comment'
require './email_code'
require './mgetc'
require './ghapi'
require './geousers_lib'
require './nationalize_lib'
require './genderize_lib'
require './agify_lib'

# SKIP_TOKENS=17

def stringify_keys(hash)
  ret = {}
  hash.each do |key, val|
    ret[key.to_s] = val
  end
  return ret
end

def enrich(h, prob, skipgdpr)
  unless skipgdpr
    if h[:location]
      if h[:country_id].nil? || h[:country_id] == ''
        print "geousers_lib: #{h[:location]} -> "
        h[:country_id], stub, ok = get_cid h[:location]
        puts "(#{h[:country_id]}, #{stub}, #{ok})"
      end
    else
      h[:country_id] = nil unless h.key?(:country_id)
      h[:tz] = nil unless h.key?(:tz)
    end
  else
    if h[:location]
      if h[:country_id].nil? || h[:country_id] == '' || h[:tz].nil? || h[:tz] == ''
        print "geousers_lib: #{h[:location]} -> "
        h[:country_id], h[:tz], ok = get_cid h[:location]
        puts "(#{h[:country_id]}, #{h[:tz]}, #{ok})"
      end
    else
      h[:country_id] = nil unless h.key?(:country_id)
      h[:tz] = nil unless h.key?(:tz)
    end

    if h[:country_id].nil? || h[:tz].nil? || h[:country_id] == '' || h[:tz] == ''
      print "nationalize_lib: (#{h[:login]}, #{h[:name]}) -> "
      cid, prb, ok = get_nat h[:name], h[:login], prob
      tz, ok2 = get_tz cid unless cid.nil?
      print "(#{cid}, #{tz}, #{prb}, #{ok}, #{ok2}) -> "
      h[:country_id] = cid if h[:country_id].nil?
      h[:tz] = tz if h[:tz].nil?
      puts "(#{h[:country_id]}, #{h[:tz]})"
    end

    if h[:sex].nil? || h[:sex_prob].nil? || h[:sex] == '' || h[:sex_prob] == ''
      print "genderize_lib: (#{h[:login]}, #{h[:name]}, #{h[:country_id]}) -> "
      h[:sex], h[:sex_prob], ok = get_sex h[:name], h[:login], h[:country_id]
      puts "(#{h[:sex]}, #{h[:sex_prob]}, #{ok})"
    end

    if h[:age].nil? || h[:age] == ''
      print "agify_lib: (#{h[:login]}, #{h[:name]}, #{h[:country_id]}) -> "
      h[:age], cnt, ok = get_age h[:name], h[:login], h[:country_id]
      puts "(#{h[:age]}, #{cnt}, #{ok})"
    end
  end

  h[:commits] = 0 unless h.key?(:commits)
  h[:affiliation] = "(Unknown)" unless h.key?(:affiliation)
  h[:email] = "#{h[:login]}!users.noreply.github.com" if !h.key?(:email) || h[:email].nil? || h[:email] == ''
  h[:email] = email_encode(h[:email])
  h[:source] = "config" unless h.key?(:source)
  return h
end

def update_from_pr_diff(diff_file, json_file, email_map)
  if ENV['PG_PASS'].nil?
    puts "You need to set PG_PASS=... variable to run this script"
    exit 1
  end

  # dbg: set to true to have very verbose output
  dbg = !ENV['DBG'].nil?
  skipgdpr = !ENV['SKIP_GDPR'].nil?

  init_sqls()
  gcs = octokit_init()
  hint = rate_limit(gcs)[0]
  prob = 0.5
  unless ENV['PROB'].nil?
    prob = ENV['PROB'].to_f
  end

  # read diff file
  login = ''
  emails = []
  logins = {}
  File.readlines(diff_file).each do |line|
    line.strip!
    if line.length > 1 && line[0] == '-' &&  line[1] != '-'
      p line
      puts "This diff contains '-' which means it also deletes data, this is not supported"
      exit 1
    end
    if line.length > 0 && line[0] != '+'
      next
    end
    line = line[1..-1].strip
    if line.length > 0 && line[0] == '+'
      next
    end
    ary = line.split ':'
    if ary.length == 2
      login = ary[0]
      emails = ary[1].split(',').map(&:strip)
      next
    else
      if ary.length != 1
        p line
        puts "This diff contains line with >1 ':' this is not supported"
        exit 1
      end
    end
    ary = line.split('until').map(&:strip)
    if ary.length == 1
      ary2 = line.split('from').map(&:strip)
      if ary2.length == 2
        line = ary2[0]
      elsif ary2.length > 2
        p line
        puts "This diff contains line with multiple 'from' phrases"
        exit 1
      end
    elsif ary.length == 2
      ary2 = ary[0].split('from').map(&:strip)
      if ary2.length == 1
        line = ary[0] + " < " + ary[1]
      elsif ary2.length == 2
        line = ary2[0] + " < " + ary[1]
      else
        p line
        puts "This diff contains line with 'until' phrase and multiple 'from' phrases"
        exit 1
      end
    else
      p line
      puts "This diff contains line with multiple 'until' phrases"
      exit 1
    end
    if logins.key?(login)
      ary = logins[login]
      new_line = ary[0] + ', ' + line
      logins[login] = [new_line, ary[1]]
    else
      logins[login] = [line, emails]
    end
  end

  # Parse input JSON, store current data in 'users'
  users = {}
  sources = {}
  json_data = JSON.parse File.read json_file
  json_data.each_with_index do |user, index|
    email = user['email'].downcase
    login = user['login'].downcase
    source = user['source']
    users[email] = [index, user]
    users[login] = [] unless users.key?(login)
    users[login] << [index, user]
    sources[email] = source unless source.nil?
  end

  # parse current email-map, store data in 'eaffs'
  eaffs = {}
  File.readlines(email_map).each do |line|
    line.strip!
    if line.length > 0 && line[0] == '#'
      next
    end
    ary = line.split ' '
    email = ary[0]
    source = sources[email]
    eaffs[email] = {} unless eaffs.key?(email)
    aff = ary[1..-1].join(' ')
    eaffs[email][aff] = source ? source : true
  end
  puts "Default affiliation sources: #{eaffs.values.map { |v| v.values }.flatten.count { |v| v === true }}"
  sourcetypes = eaffs.values.map { |v| v.values }.flatten.uniq
  sourcetypes.each do |source_type|
    next if source_type === true
    puts "#{source_type.capitalize} affiliation sources: #{eaffs.values.map { |v| v.values }.flatten.count { |v| v == source_type }}"
  end

  # now update all
  logins.each do |login, data|
    company = data[0]
    companies = company.split ', '
    emails = data[1]
    dlogin = login.downcase
    first_index = -1
    if users.key?(dlogin)
      users[dlogin].each do |data|
        index = data[0]
        if first_index < 0
          first_index = index
        end
        user = data[1]
        if user['affiliation'] != company
          aff = user['affiliation'] || 'nil'
          source = user['source'] || 'default'
          puts "Conflict detected(login):\n#{login}/#{user['email']}\nCurrent affiliations:\n#{aff}, source: #{source}\nNew affiliation\n#{company}, source: user\nReplace?"
          ans = mgetc.downcase
          puts "> #{ans}"
          if ans == 'y'
            json_data[index]['affiliation'] = company
            json_data[index]['source'] = 'user'
            puts "Updated existing index #{index}"
          end
        end
      end
    else
      puts "GitHub login #{login} not known yet, querying GitHub API"
      begin
        u = gcs[hint].user login
      rescue Octokit::NotFound => err
        puts "GitHub doesn't know actor #{login}"
        puts err
        next
      rescue Octokit::AbuseDetected => err
        puts "Abuse #{err} for #{login}, sleeping 30 seconds"
        sleep 30
        retry
      rescue Octokit::TooManyRequests => err
        hint, td = rate_limit(gcs)
        puts "Too many GitHub requests for #{login}, sleeping for #{td} seconds"
        sleep td
        retry
      rescue Zlib::BufError, Zlib::DataError, Faraday::ConnectionFailed => err
        puts "Retryable error #{err} for #{login}, sleeping 10 seconds"
        sleep 10
        retry
      rescue => err
        puts "Uups, something bad happened for #{login}, check `err` variable!"
        STDERR.puts [err.class, err]
        binding.pry
        next
      end
      h = u.to_h
      h = stringify_keys(enrich(h, prob, skipgdpr))
      h['affiliation'] = company
      h['source'] = 'user'
      h['commits'] = 0
      users[dlogin] = []
      emails.each do |email|
        user = h.clone
        user['email'] = email
        index = json_data.length
        json_data << user
        users[email.downcase] = [index, user]
        users[dlogin] << [index, user]
        if first_index < 0
          first_index = index
        end
        puts "Added new index #{index}"
      end
    end
    emails.each do |email|
      demail = email.downcase
      if users.key?(demail)
        data = users[demail]
        index = data[0]
        user = data[1]
        if user['affiliation'] != company
          aff = user['affiliation'] || 'nil'
          source = user['source'] || 'default'
          puts "Conflict detected(email):\n#{login}/#{email}\nCurrent affiliations:\n#{aff}, source: #{source}\nNew affiliation\n#{company}, source: user\nReplace?"
          ans = mgetc.downcase
          puts "> #{ans}"
          if ans == 'y'
            json_data[index]['affiliation'] = company
            json_data[index]['source'] = 'user'
            puts "Updated existing index #{index}"
          end
        end
      else
        if first_index > 0
          index = first_index
          user = json_data[index]
          if user['affiliation'] != company
            aff = user['affiliation'] || 'nil'
            source = user['source'] || 'default'
            puts "Conflict detected(copy from existing):\n#{login}/#{user['email']}\nCurrent affiliations:\n#{aff}, source: #{source}\nNew affiliation\n#{company}, source: user\nReplace?"
            ans = mgetc.downcase
            puts "> #{ans}"
            if ans == 'y'
              json_data[index]['affiliation'] = company
              json_data[index]['source'] = 'user'
              puts "Updated existing index #{index}"
            end
          end
          user = user.clone
          user['email'] = email
          user['commits'] = 0
          index = json_data.length
          json_data << user
          users[demail] = [index, user]
          users[dlogin] << [index, user]
          puts "Added new index #{index}"
        else
          puts "#{email}/#{login} has no GitHub configuration to copy from, will skip it"
        end
      end
      if eaffs.key?(email)
        obj = eaffs[email]
        companies.each do |comp|
          unless obj.key?(comp)
            puts "Conflict detected(config):\n#{login}/#{email}\nCurrent affiliations:"
            obj.each do |aff, source|
              puts "#{aff}, source: #{source === true ? 'default' : source}"
            end
            puts "New affiliation:\n#{comp}, source: user\nReplace (y/n)"
            ans = mgetc.downcase
            puts "> #{ans}"
            if ans == 'y'
              eaffs[email] = {}
              eaffs[email][comp] = 'user'
              puts "Updated existing index #{index}"
            end
          end
        end
      else
        eaffs[email] = {}
        companies.each do |comp|
          eaffs[email][comp] = 'user'
          puts "Added new email #{email} #{comp}"
        end
      end
    end
  end

  puts "Just before final save"
  binding.pry

  # write eaffs back to cncf-config/email-map
  puts "Write config file..."
  File.open(email_map, 'w') do |file|
    file.puts "# Here is a set of mappings of domain names onto employer names."
    file.puts "# [user!]domain  employer  [< yyyy-mm-dd]"
    eaffs.each do |email, affs|
      affs.each do |aff, _|
        file.puts "#{email} #{aff}"
      end
    end
  end

  # Write JSON back
  puts "Write JSON file..."
  pretty = JSON.pretty_generate json_data
  File.write json_file, pretty
end

if ARGV.size < 3
  puts "Missing arguments: pr.diff github_users.json cncf-config/email-map"
  exit(1)
end

update_from_pr_diff(ARGV[0], ARGV[1], ARGV[2])
