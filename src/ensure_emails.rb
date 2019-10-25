#!/usr/bin/env ruby

require 'pry'
require 'json'
require 'octokit'
require 'set'
require 'thwait'
require './email_code'
require './ghapi'

# Parse JSON
json_file = ARGV[0]
data = JSON.parse File.read json_file

hsh = {}
emails = 0
data.each do |row|
  emails += 1
  login = row['login']
  email = email_encode(row['email']).downcase
  hsh[login] = {} unless hsh.key?(login)
  hsh[login][email] = row
end

puts "Logins: #{hsh.keys.length}, emails: #{emails}"

n_thrs = ENV['NCPUS'].nil? ? Etc.nprocessors : ENV['NCPUS'].to_i
gcs = octokit_init()
hint = rate_limit(gcs)[0]
uacts = hsh.keys
uacts.shuffle! unless ENV['SHUFFLE'].nil?
n_users = uacts.size
rpts = 0
new_emails = 0
thrs = Set[]
uacts.each_with_index do |actor, index|
  thrs << Thread.new do
    while true
      res = []
      begin
        if rpts <= 0
          hint, rem, pts = rate_limit(gcs)
          rpts = pts / 10
          puts "Allowing #{rpts} calls without checking rate"
        else
          rpts -= 1
          #puts "#{rpts} calls remain before next rate check"
        end
        puts "Asking for #{index}/#{n_users}: GitHub: #{actor}, new: #{new_emails}"
        u = gcs[hint].user actor
        break if u[:email].nil? || u[:email] == ''
        email = email_encode(u[:email])
        emails = hsh[actor]
        break if emails.key?(email)
        puts "New email: #{email}"
        new_emails += 1
        u2 = emails.first[1].clone
        u2['email'] = email
        u2['commits'] = 0
        res << u2.to_h
      rescue Octokit::NotFound => err
        puts "GitHub doesn't know actor #{actor}"
        puts err
        break
      rescue Octokit::AbuseDetected => err
        puts "Abuse #{err} for #{actor}, sleeping 30 seconds"
        sleep 30
        next
      rescue Octokit::TooManyRequests => err
        hint, td = rate_limit(gcs)
        puts "Too many GitHub requests for #{actor}, sleeping for #{td} seconds"
        sleep td
        next
      rescue Octokit::InternalServerError => err
        puts "Internal Server Error #{err} for #{actor}, sleeping 60 seconds"
        sleep 60
        next
      rescue Octokit::BadGateway => err
        puts "Bad Gateway #{err} for #{actor}, sleeping 60 seconds"
        sleep 60
        next
      rescue Octokit::ServerError => err
        puts "Server Error #{err} for #{actor}, sleeping 60 seconds"
        sleep 60
        next
      rescue Zlib::BufError, Zlib::DataError, Faraday::ConnectionFailed => err
        puts "Retryable error #{err} for #{actor}, sleeping 10 seconds"
        sleep 10
        next
      rescue => err
        puts "Uups, something bad happened for #{actor}, check `err` variable!"
        STDERR.puts [err.class, err]
        # Write JSON back
        json = JSON.pretty_generate data
        File.write json_file, json
        exit 1
      end
      break
    end
    res
  end # end of thread
  while thrs.length >= n_thrs
    tw = ThreadsWait.new(thrs.to_a)
    t = tw.next_wait
    res = t.value
    res.each { |h| data << h }
    thrs = thrs.delete t
  end
  if index > 0 && index % 2000 == 0
    puts "Backup at #{index}/#{n_users}"
    # Write JSON back
    json = JSON.pretty_generate data
    File.write json_file, json
  end
end
ThreadsWait.all_waits(thrs.to_a) do |thr|
  res = thr.value
  res.each { |h| data << h }
end
puts "Found #{new_emails} new emails"

# Write JSON back
json = JSON.pretty_generate data
File.write json_file, json
