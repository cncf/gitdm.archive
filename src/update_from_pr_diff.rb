#!/usr/bin/env ruby

require 'pry'
require 'json'
require './comment'
require './email_code'
require './mgetc'

def update_from_pr_diff(diff_file, json_file, email_map)
  # affiliation sources priorities
  prios = {}
  prios['user'] = 3
  prios['user_manual'] = 2
  prios['manual'] = 1
  prios['config'] = 0
  prios[true] = 0
  prios[nil] = 0
  prios['domain'] = -1
  prios['notfound'] = -2
  manual_prio = prios['manual']

  # dbg: set to true to have very verbose output
  dbg = !ENV['DBG'].nil?

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
        puts "This diff contains '-' which means it also deletes data, this is not supported"
        exit 1
      end
    end
    logins[login] = [line, emails]
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
    emails = data[1]
    emails.each do |email|
      if eaffs.key?(email)
        obj = eaffs[email]
        unless obj.key?(company)
          puts "Conflict detected:\nCurrent affiliations:"
          obj.each do |aff, source|
            puts "#{aff}, source: #{source === true ? 'default' : source}"
          end
          puts "New affiliation:\n#{company}, source: user\nReplace (y/n)"
          ans = mgetc.downcase
          puts "> #{ans}"
          if ans == 'y'
            eaffs[email] = {}
            eaffs[email][company] = 'user'
          end
        end
      else
        eaffs[email] = {}
        eaffs[email][company] = 'user'
      end
    end
  end

  # write eaffs back to cncf-config/email-map
  File.open(email_map, 'w') do |file|
    file.puts "# Here is a set of mappings of domain names onto employer names."
    file.puts "# [user!]domain  employer  [< yyyy-mm-dd]"
    eaffs.each do |email, affs|
      affs.each do |aff, _|
        file.puts "#{email} #{aff}"
      end
    end
  end

end

if ARGV.size < 3
  puts "Missing arguments: pr.diff github_users.json cncf-config/email-map"
  exit(1)
end

update_from_pr_diff(ARGV[0], ARGV[1], ARGV[2])
