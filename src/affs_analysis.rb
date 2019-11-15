#!/usr/bin/env ruby

require 'csv'
require 'json'
require 'pry'
require './email_code'

fn = ARGV[0]
CSV.foreach(fn, headers: true) do |row|
emails = row['email']
  binding.pry if emails.nil?
  emails = email_encode(emails)
  emails = emails.split(',').map(&:strip)
  emails.each do |email|
    lemail = email.downcase
    binding.pry if maps[i].key?(lemail)
    maps[i][lemail] = row
    ks[lemail] = 0 unless ks.key?(lemail)
    ks[lemail] += 1
    up[lemail] = email
  end
end
