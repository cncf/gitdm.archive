#!/usr/bin/env ruby

require 'pry'
require 'json'
require 'net/http'
require 'uri'
require './email_code'

existing = {}
File.readlines('cncf-config/email-map').each do |line|
  line = line.strip
  next if line[0] == '#'
  arr = line.split ' '
  email = email_encode(arr[0])
  company = arr[1..-1].join ' '
  didx = company.index(' < ')
  dtto = nil
  comp = company
  if didx
    comp = company[0..didx - 1]
    dtto = company[didx + 3..-1]
  end
  next if company.strip == 'NotFound' || company.strip[0..11] == 'Independent'
  existing[email] = {} unless existing.key?(email)
  existing[email][comp] = dtto
end

data = JSON.parse File.read 'default_data.json'

conf = 0
new = 0
same = 0

data['users'].each do |user|
  user['emails'].each do |email|
    email = email_encode email
    if existing.key?(email)
      user['companies'].each do |company|
        if existing[email][company['company_name']] != company['end_date']
          p [email, company, existing[email], existing[email][company['company_name']], company['end_date']]
          conf += 1
        else
          same += 1
        end
      end
    else
      new += 1
    end
  end
end

puts "Same: #{same}, new: #{new}, conflict: #{conf}"
binding.pry
