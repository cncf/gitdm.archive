#!/usr/bin/env ruby

require 'csv'
require 'json'
require 'pry'

unknowns = {}
# wget https://teststats.cncf.io/backups/cii_top_3_repo_groups_committers.csv
CSV.foreach('cii_top_3_repo_groups_committers.csv', headers: true) do |row|
  # repo,rank_number,actor,company,commits,percent,all_commits
  actor = row['actor']
  company = row['company']
  next unless company == '(Unknown)'
  next if unknowns.key?(actor)
  unknowns[actor] = [row['repo'], row['rank_number'], row['commits']]
end

ary = []
json = JSON.parse(File.read('stripped.json'))
data = {}
ks = {}
json.each do |row|
  login = row['login'].downcase
  email = row['email'].downcase
  row.keys.each { |k| ks[k] = 0 }
  data[login] = {} unless data.key?(login)
  data[login][email] = row
end

unknowns.each do |ghid, d|
  repo, rank, commits = *d
  lghid = ghid.downcase
  email = "#{ghid}!users.noreply.github.com"
  lemail = email.downcase
  emails = []
  if data.key?(lghid)
    data[lghid].keys.each do |em|
      lem = em.downcase
      if lem != lemail
        emails << em
      end
    end
    emails = [email] if emails.length == 0
    data[lghid][lemail]['repo'] = repo
    data[lghid][lemail]['rank'] = rank
    data[lghid][lemail]['commits'] = commits
    data[lghid][lemail]['emails'] = emails
    data[lghid][lemail]['email'] = emails.join(', ')
    ary << data[lghid][lemail]
  else
    puts "Cannot find #{lghid}/#{lemail}"
    exit 1
  end
end

puts "Writting CSV..."
hdr = %w(type email name github linkedin1 linkedin2 linkedin3 repo rank commits gender location affiliations)
hdr << 'new emails'
CSV.open('top_task.csv', 'w', headers: hdr) do |csv|
  csv << hdr
  ary.each do |row|
    aff = row['affiliation']
    next unless [nil, '', '?', 'NotFound', '(Unknown)'].include?(aff)
    login = row['login']
    email = row['email']
    email = "#{login}!users.noreply.github.com" if email.nil?
    name = row['name'] || ''
    emails = row['emails']
    ary2 = emails[0].split '!'
    uname = ary2[0]
    dom = ary2[1]
    escaped_name = URI.escape(name)
    escaped_uname = URI.escape(name + ' ' + uname)
    lin1 = lin2 = lin3 = ''
    gh = "https://github.com/#{login}"
    if !dom.nil? && dom.length > 0 && dom != 'users.noreply.github.com'
      ary3 = dom.split '.'
      domain = ary3[0]
      escaped_domain = URI.escape(name + ' ' + domain)
      lin1 = "https://www.linkedin.com/search/results/index/?keywords=#{escaped_name}"
      lin2 = "https://www.linkedin.com/search/results/index/?keywords=#{escaped_uname}"
      lin3 = "https://www.linkedin.com/search/results/index/?keywords=#{escaped_domain}"
    else
      lin1 = "https://www.linkedin.com/search/results/index/?keywords=#{escaped_name}"
      lin2 = "https://www.linkedin.com/search/results/index/?keywords=#{escaped_uname}"
    end
    loc = ''
    loc += row['location'] unless row['location'].nil?
    if loc != ''
      loc += '/' + row['country_id'] unless row['country_id'].nil?
    else
      loc += row['country_id'] unless row['country_id'].nil?
    end
    commits = row['commits']
    repo = "https://github.com/#{row['repo']}"
    rank = row['rank'].to_i
    csv << ['(Unknown)', email, name, gh, lin1, lin2, lin3, repo, rank, commits, row['sex'], loc, '', '']
  end
end
