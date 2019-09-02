#!/usr/bin/env ruby

require 'pry'
require 'octokit'
require 'json'
require 'concurrent'
require 'unidecoder'
require 'pg'

require './ghapi'
require './genderize_lib'
require './geousers_lib'

gcs = octokit_init()
hint = rate_limit(gcs)[0]
u = gcs[hint].user ARGV[0]
h = u.to_h

init_sqls()

if h[:location]
  h[:country_id], h[:tz] = get_cid h[:location]
else
  h[:country_id], h[:tz] = nil, nil
end
h[:sex], h[:sex_prob], ok = get_sex h[:name], h[:login], h[:country_id]

h[:commits] = 0
h[:affiliation] = "(Unknown)"
h[:email] = "change-me"
h[:source] = "config"

print JSON.pretty_generate(h) + "\n"
