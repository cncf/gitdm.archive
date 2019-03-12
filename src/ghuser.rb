#!/usr/bin/env ruby

require 'pry'
require 'json'
require 'octokit'
require 'set'
require 'thwait'
require './ghapi'

def ghuser(users)
  n_thrs = ENV['NCPUS'].nil? ? Etc.nprocessors : ENV['NCPUS'].to_i
  gcs = octokit_init()
  hint = rate_limit(gcs)[0]
  rpts = 0
  thrs = Set[]
  data = []
  n_users = users.length
  users.each_with_index do |actor, index|
    thrs << Thread.new do
      res = []
      begin
        if rpts <= 0
          hint, rem, pts = rate_limit(gcs)
          rpts = pts / 10
          puts "Allowing #{rpts} calls without checking rate"
        else
          rpts -= 1
        end
        e = "#{actor}!users.noreply.github.com"
        puts "Asking for #{index}/#{n_users}: GitHub: #{actor}, email: #{e}"
        u = gcs[hint].user actor
        login = u['login']
        n = u['name']
        u['email'] = e
        u['commits'] = 0
        v = '?'
        u['affiliation'] = v
        puts "Got name: #{u[:name] || u['name']}, login: #{u[:login] || u['login']}"
        h = u.to_h
        res << h
      rescue Octokit::NotFound => err
        puts "GitHub doesn't know actor #{actor}"
        puts err
      rescue Octokit::AbuseDetected => err
        puts "Abuse #{err} for #{actor}, sleeping 30 seconds"
        sleep 30
        retry
      rescue Octokit::TooManyRequests => err
        hint, td = rate_limit(gcs)
        puts "Too many GitHub requests for #{actor}, sleeping for #{td} seconds"
        sleep td
        retry
      rescue Zlib::BufError, Zlib::DataError, Faraday::ConnectionFailed => err
        puts "Retryable error #{err} for #{actor}, sleeping 10 seconds"
        sleep 10
        retry
      rescue => err
        puts "Uups, something bad happened for #{actor}, check `err` variable!"
        STDERR.puts [err.class, err]
        exit 1
        end
        res
      end
    while thrs.length >= n_thrs
      tw = ThreadsWait.new(thrs.to_a)
      t = tw.next_wait
      res = t.value
      res.each { |h| data << h }
      thrs = thrs.delete t
    end
  end
  ThreadsWait.all_waits(thrs.to_a) do |thr|
    res = thr.value
    res.each { |h| data << h }
  end

  json = JSON.pretty_generate data
  File.write 'users.json', json
end

if ARGV.size < 1
  puts "Missing arguments: github_login1 github_login2 ..."
  exit(1)
end

ghuser(ARGV)
