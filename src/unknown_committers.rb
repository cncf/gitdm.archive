#!/usr/bin/env ruby

require 'csv'
require 'pry'
require 'octokit'
require 'json'
require 'concurrent'
require 'unidecoder'
require 'pg'

require './email_code'
require './ghapi'
require './genderize_lib'
require './geousers_lib'

# type,email,name,github,linkedin1,linkedin2,linkedin3,commits,gender,location,affiliations
gcs = octokit_init()
hint = rate_limit(gcs)[0]
init_sqls()

json = JSON.parse(File.read('github_users.json'))
data = {}
ks = {}
json.each do |row|
  login = row['login'].downcase
  email = row['email'].downcase
  row.keys.each { |k| ks[k] = 0 }
  data[login] = {} unless data.key?(login)
  data[login][email] = row
end

skipenc = !ENV['SKIP_ENC'].nil?

ary = []
new_objs = []
commits = {}
idx = 0
CSV.foreach('unknown_committers.csv', headers: true) do |row|
  #rank_number,actor,commits,percent,cumulative_sum,cumulative_percent,all_commits
  idx += 1
  ghid = row['actor']
  lghid = ghid.downcase
  commits[ghid] = row['commits']
  email = "#{ghid}!users.noreply.github.com"
  lemail = email.downcase
  if data.key?(lghid)
    if data[lghid].key?(lemail)
      puts "Exact match #{lghid}/#{lemail}"
      ary << data[lghid][lemail]
    else
      puts "Partial match: #{lghid}"
      obj = data[lghid][data[lghid].keys[0]].dup
      obj['email'] = email
      # obj['commits'] = commits[ghid]
      obj['commits'] = 0
      new_objs << obj
      ary << obj
    end
  else
    puts "#{idx}) Asking GitHub for #{ghid}"
    begin
      u = gcs[hint].user ghid
    rescue Octokit::NotFound => err
      puts "GitHub doesn't know actor #{ghid}"
      puts err
      next
    rescue Octokit::AbuseDetected => err
      puts "Abuse #{err} for #{ghid}, sleeping 30 seconds"
      sleep 30
      retry
    rescue Octokit::TooManyRequests => err
      hint, td = rate_limit(gcs)
      puts "Too many GitHub requests for #{ghid}, sleeping for #{td} seconds"
      sleep td
      retry
    rescue Zlib::BufError, Zlib::DataError, Faraday::ConnectionFailed => err
      puts "Retryable error #{err} for #{ghid}, sleeping 10 seconds"
      sleep 10
      retry
    rescue => err
      puts "Uups, something bad happened for #{ghid}, check `err` variable!"
      STDERR.puts [err.class, err]
      binding.pry
      next
    end
    h = u.to_h
    unless skipenc
      if h[:location]
        print "Geolocation for #{h[:location]} "
        h[:country_id], h[:tz] = get_cid h[:location]
        puts "-> (#{h[:country_id]}, #{h[:tz]})"
      else
        h[:country_id], h[:tz] = nil, nil
      end
      print "(#{h[:name]}, #{h[:login]}, #{h[:country_id]}) "
      h[:sex], h[:sex_prob], ok = get_sex h[:name], h[:login], h[:country_id]
      puts "-> (#{h[:sex]}, #{h[:sex_prob]})"
    else
      h[:country_id], h[:tz] = nil, nil
      h[:sex], h[:sex_prob] = nil, nil
    end
    h[:commits] = 0
    h[:affiliation] = "(Unknown)"
    h[:email] = "#{ghid}!users.noreply.github.com"
    h[:source] = "config"
    obj = {}
    ks.keys.each { |k| obj[k.to_s] = h[k.to_sym] }
    new_objs << obj
    ary << obj
  end
end

puts "Writting CSV..."
hdr = %w(type email name github linkedin1 linkedin2 linkedin3 commits gender location affiliations)
CSV.open('task.csv', 'w', headers: hdr) do |csv|
  csv << hdr
  ary.each do |row|
    login = row['login']
    email = row['email']
    email = "#{login}!users.noreply.github.com" if email.nil?
    name = row['name'] || ''
    ary2 = email.split '!'
    uname = ary2[0]
    dom = ary2[1]
    escaped_name = URI.escape(name)
    escaped_uname = URI.escape(name + ' ' + uname)
    lin1 = lin2 = lin3 = ''
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
    csv << ['(Unknown)', email, name, lin1, lin2, lin3, commits[login], row['sex'], loc, '']
  end
end

puts "Writting JSON..."
new_objs.each do |row|
  json << row
end
json_data = email_encode(JSON.pretty_generate(json))
File.write 'github_users.json', json_data
