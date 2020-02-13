#!/usr/bin/env ruby

require 'pry'
require 'octokit'
require 'json'
require 'concurrent'
require 'unidecoder'
require 'pg'

require './email_code'
require './ghapi'
require './geousers_lib'
require './nationalize_lib'
require './genderize_lib'
require './agify_lib'

def symbolize_keys(hash)
  ret = {}
  hash.each do |key, val|
    ret[key.to_sym] = val
  end
  return ret
end

init_sqls()

gcs = octokit_init()
hint = rate_limit(gcs)[0]
u = gcs[hint].user ARGV[0]
h = u.to_h
prob = 0.5
unless ENV['PROB'].nil?
  prob = ENV['PROB'].to_f
end

# json_data = JSON.parse File.read 'in.json'
# h = json_data[0]
# h = symbolize_keys h

if h[:location]
  if h[:country_id.nil?] || h[:country_id] == '' || h[:tz].nil? || h[:tz] == ''
    print "geousers_lib: #{h[:location]} -> "
    h[:country_id], h[:tz], ok = get_cid h[:location]
    puts "(#{h[:country_id]}, #{h[:tz]}, #{ok})"
  end
else
  h[:country_id] = nil unless h.key?(:country_id)
  h[:tz] = nil unless h.key?(:tz)
end

if h[:country_id].nil? || h[:tz].nil? || h[:country_id] == '' || h[:tz] == ''
  print "nationalize_lib: (#{h[:login]}, #{h[:name]}) -> "
  cid, prb, ok = get_nat h[:name], h[:login], prob
  tz, ok2 = get_tz cid unless cid.nil?
  print "(#{cid}, #{tz}, #{prb}, #{ok}, #{ok2}) -> "
  h[:country_id] = cid if h[:country_id].nil?
  h[:tz] = tz if h[:tz].nil?
  puts "(#{h[:country_id]}, #{h[:tz]})"
end

if h[:sex].nil? || h[:sex_prob].nil? || h[:sex] == '' || h[:sex_prob] == ''
  print "genderize_lib: (#{h[:login]}, #{h[:name]}, #{h[:country_id]}) -> "
  h[:sex], h[:sex_prob], ok = get_sex h[:name], h[:login], h[:country_id]
  puts "(#{h[:sex]}, #{h[:sex_prob]}, #{ok})"
end

if h[:age].nil? || h[:age] == ''
  print "agify_lib: (#{h[:login]}, #{h[:name]}, #{h[:country_id]}) -> "
  h[:age], cnt, ok = get_age h[:name], h[:login], h[:country_id]
  puts "(#{h[:age]}, #{cnt}, #{ok})"
end

h[:commits] = 0 unless h.key?(:commits)
h[:affiliation] = "(Unknown)" unless h.key?(:affiliation)
h[:email] = "#{h[:login]}!users.noreply.github.com" if !h.key?(:email) || h[:email].nil? || h[:email] == ''
h[:email] = email_encode(h[:email])
h[:source] = "config" unless h.key?(:source)

STDERR.puts JSON.pretty_generate(h)

puts "Update email, affiliation and source on the generated JSON"
