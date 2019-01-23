require 'pry'
require 'json'
require './email_code'

def aliaser(json_file)
  data = JSON.parse File.read json_file
  users = {}
  data.each do |user|
    l = user['login'].strip
    users[l] = [] unless users.key?(l)
    users[l] << user
  end
  users = users.values.reject { |u| u.count < 2 }
  unknown_affs = ['?', '(Unknown)']
  bad = []
  users.each do |user|
    known = user.reject { |u| unknown_affs.include?(u['affiliation']) }
    unknown = user.select { |u| unknown_affs.include?(u['affiliation']) }
    if known.count < 1
      emails = user.map { |u| email_encode(u['email']) }.uniq
      bad << "There is no known affiliation for entire group: #{emails.join(', ')}"
    else
      base = email_encode(known.first['email'])
      emails = unknown.map { |u| email_encode(u['email']) }.uniq
      emails.each do |email|
        next if email == base
        puts "#{email} #{base}"
      end
    end
  end
  bad.each do |b|
    puts email_encode(b)
  end
end

if ARGV.size < 1
  puts "Missing argument: JSON_file aliases (github_users.json)"
  exit(1)
end

aliaser(ARGV[0])
