#!/usr/bin/env ruby

require 'csv'
require 'json'
# require 'pry'

email2line = {}
File.readlines('unknowns.txt').each do |line|
  line.strip!
  ary = line.split "\t"
  email = ary[1]
  if email2line.key?(email)
    puts "Duplicate email: #{line}"
  else
    email2line[email] = line
  end
end

email2gh = {}
gh = JSON.parse File.read 'github_users.json'
gh.each do |user|
  email = user['email']
  email2gh[email] = [] unless email2gh.key?(email)
  email2gh[email] << "https://github.com/#{user['login'].downcase}"
end

email2gh.each do |email, logins|
  email2gh[email] = logins.uniq
end

f = nf = 0
email2line.each do |email, line|
  ary = line.split "\t"
  name = ary[2]
  email = ary[1]
  ary2 = email.split '!'
  uname = ary2[0]
  dom = ary2[1]
  escaped_name = URI.escape(name)
  escaped_uname = URI.escape(name + ' ' + uname)
  if !dom.nil? && dom.length > 0
    ary3 = dom.split '.'
    domain = ary3[0]
    escaped_domain = URI.escape(name + ' ' + domain)
    search = "https://www.linkedin.com/search/results/index/?keywords=#{escaped_name}\thttps://www.linkedin.com/search/results/index/?keywords=#{escaped_uname}\thttps://www.linkedin.com/search/results/index/?keywords=#{escaped_domain}"
  else
    search = "https://www.linkedin.com/search/results/index/?keywords=#{escaped_name}\thttps://www.linkedin.com/search/results/index/?keywords=#{escaped_uname}\t-"
  end
  if email2gh.key?(email)
    logins = email2gh[email]
    email2line[email] = "#{line}\t#{logins.join(',')}\t#{search}"
    f += 1
  else
    email2line[email] = "#{line}\t-\t#{search}"
    nf += 1
  end
end

puts "Found #{f}, not found #{nf}"

arr = []
email2line.each { |email, line| arr << line.split("\t") }
arr = arr.sort_by { |item| [item[0], -item[3].to_i] }

hdr = %w(type email name github linkedin1 linkedin2 linkedin3 patches)
CSV.open('unknowns.csv', 'w', headers: hdr) do |csv|
  csv << hdr
  arr.each do |ary|
    csv << [ary[0], ary[1], ary[2], ary[4], ary[5], ary[6], ary[7], ary[3]]
  end
end

