#!/usr/bin/env ruby

require 'pry'
require 'json'
require 'date'
require './email_code'
require './mgetc'
require './ghapi'

def make_affiliation(companies)
  final = ''
  dates = {}
  companies.each do |company|
    if company['end_date'].nil?
      final = company['company_name']
    else
      dates[Date.parse(company['end_date'])] = company['company_name']
    end
  end
  affs = []
  dates.keys.sort.each do |date|
    company = dates[date]
    sdate = date.strftime '%Y-%m-%d'
    affs << "#{company} < #{sdate}"
  end
  return affs.join(', ') if final == ''
  return affs.join(', ') + ", #{final}" if affs.length > 0
  final
end

$gcfg = {}
def handle_conflict(ghid, email, saaff, ghaff)
  puts '0 - do nothing'
  puts '1 - use SA data'
  puts '2 - use GH data'
  puts 'q - quit'
  return $gcfg[[saaff, ghaff]] if $gcfg.key?([saaff, ghaff])
  c = mgetc
  #c = '0'
  exit(1) if c == 'q'
  $gcfg[[saaff, ghaff]] = c
  return c
end

gcs = octokit_init()

sa = JSON.parse File.read 'default_data.json'
# Some name transformations
slf = {}
slf['Self'] = true
slf['*independent'] = true
sa['companies'][0]['aliases'].each do |als|
  slf[als] = true
end
sa['users'].each do |user|
  comps = []
  user['companies'].each do |company|
    cname = company['company_name']
    dtto = company['end_date']
    if slf.key?(cname)
      cname = 'Independent'
    end
    rec = {}
    rec['company_name'] = cname
    rec['end_date'] = dtto
    comps << rec
  end
  user['companies'] = comps
end

sa_users = {}
sa['users'].each do |user|
  next unless user.key?('github_id')
  ghid = user['github_id']
  aff = make_affiliation(user['companies'])
  user['emails'].each do |email|
    email = email_encode email
    sa_users[[ghid, email]] = aff
  end
end

gh = JSON.parse File.read 'github_users.json'
gh_users = {}
gh_logins = {}
gh_index = {}
gh_login_index = {}
gh.each_with_index do |user, index|
  ghid = user['login']
  email = user['email']
  aff = user['affiliation']
  gh_users[[ghid, email]] = aff
  gh_logins[ghid] = aff
  gh_index[[ghid, email]] = index
  gh_login_index[ghid] = index
end

same = 0
conf1 = 0
conf2 = 0
newemail = 0
newghid = 0
news = []
sa_users.each do |key, saaff|
  ghid = key[0]
  email = key[1]
  if gh_users.key?(key)
    ghaff = gh_users[key]
    if saaff != ghaff
      puts "conflict with existing entry:"
      puts "[#{ghid}, #{email}]: SA: '#{saaff}', GH: '#{ghaff}'"
      res = handle_conflict(ghid, email, saaff, ghaff)
      if res == '1'
        gh[gh_index[key]]['affiliation'] = saaff
      end
      conf1 += 1
    else
      same += 1
    end
  else
    if gh_logins.key?(ghid)
      ghaff = gh_logins[ghid]
      puts "found by login: #{ghid} --> #{ghaff}"
      newemail += 1
      if saaff != ghaff
        puts "conflict with other entry with different email:"
        puts "[#{ghid}, #{email}]: SA: '#{saaff}', GH: '#{ghaff}'"
        res = handle_conflict(ghid, email, saaff, ghaff)
        if res == '1'
          news << [ghid, email, saaff]
        elsif res == '2'
          news << [ghid, email, ghaff]
        end
        conf2 += 1
      else
        news << [ghid, email, saaff]
        same += 1
      end
    else
      news << [ghid, email, saaff]
      newghid += 1
    end
  end
end

puts "same: #{same}, new emails: #{newemail}, new logins: #{newghid}, conflict: #{conf1}+#{conf2}=#{conf1+conf2}"

gh_cache = {}
n = 0
g = 0
nf = 0
hint = -1
rpts = 0
news.each do |data|
  n += 1
  ghid = data[0]
  email = data[1]
  aff = data[2]
  gh_data = {}
  if gh_login_index.key?(ghid)
    gh_data = gh[gh_login_index[ghid]].clone
  else
    if gh_cache.key?(ghid)
      gh_data = gh_cache[ghid].clone
    else
      begin
        g += 1
        if rpts <= 0
          hint, rem, pts = rate_limit(gcs)
          rpts = pts / 10
          puts "Allowing #{rpts} calls without checking rate"
        else
          rpts -= 1
          puts "#{rpts} calls remain before next rate check"
        end
        puts "Asking for #{ghid}"
        u = gcs[hint].user ghid
        gh_data = u.to_h
      rescue Octokit::TooManyRequests => err
        hint, td, pts = rate_limit(gcs)
        puts "Too many GitHub requests, sleeping for #{td} seconds"
        sleep td
        retry
      rescue => err
        p err
        nf += 1
        next
      end
    end
  end
  gh_data['email'] = email
  gh_data['commits'] = 0
  gh_data['affiliation'] = aff
  gh_cache[ghid] = gh_data
  gh << gh_data
end

puts "Added #{n} entries, asked for #{g} GitHub users, #{nf} GitHub requests failed"

json = JSON.pretty_generate(gh)
File.write 'github_users.json', json
