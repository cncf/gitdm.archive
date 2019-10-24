#!/usr/bin/env ruby

require 'pry'
require 'octokit'
require 'json'
require 'concurrent'
require 'unidecoder'
require 'pg'

require './ghapi'
require './geousers_lib'
require './nationalize_lib'
require './genderize_lib'
require './agify_lib'

gcs = octokit_init()
hint = rate_limit(gcs)[0]
u = gcs[hint].user ARGV[0]
h = u.to_h

init_sqls()

if h[:location]
  print "geousers_lib: #{h[:location]} -> "
  h[:country_id], h[:tz], ok = get_cid h[:location]
  puts "(#{h[:country_id]}, #{h[:tz]}, #{ok})"
else
  h[:country_id], h[:tz] = nil, nil
end

if h[:country_id].nil? || h[:tz].nil?
  print "nationalize_lib: (#{h[:login]}, #{h[:name]}) -> "
  cid, prb, ok = get_nat h[:name], h[:login], 0.5
  tz, ok2 = get_tz cid unless cid.nil?
  print "(#{cid}, #{tz}, #{prb}, #{ok}, #{ok2}) -> "
  h[:country_id] = cid if h[:country_id].nil?
  h[:tz] = tz if h[:tz].nil?
  puts "(#{h[:country_id]}, #{h[:tz]})"
end

print "genderize_lib: (#{h[:login]}, #{h[:name]}, #{h[:country_id]}) -> "
h[:sex], h[:sex_prob], ok = get_sex h[:name], h[:login], h[:country_id]
puts "(#{h[:sex]}, #{h[:sex_prob]}, #{ok})"

print "agify_lib: (#{h[:login]}, #{h[:name]}, #{h[:country_id]}) -> "
h[:age], cnt, ok = get_age h[:name], h[:login], h[:country_id]
puts "(#{h[:sex]}, #{h[:sex_prob]}, #{ok})"

h[:commits] = 0
h[:affiliation] = "(Unknown)"
h[:email] = "change-me"
h[:source] = "config"

STDERR.puts JSON.pretty_generate(h)
