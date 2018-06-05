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
  company = company[0..didx - 1] if didx
  next if company.strip == 'NotFound' || company.strip[0..11] == 'Independent'
  existing[email] = company
end

binding.pry
