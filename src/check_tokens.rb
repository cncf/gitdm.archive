#!/usr/bin/env ruby

require 'pry'
require 'json'
require 'octokit'
require 'concurrent'
require 'unidecoder'
require 'pg'
require './comment'
require './email_code'
require './mgetc'
require './ghapi'
require './geousers_lib'
require './nationalize_lib'
require './genderize_lib'
require './agify_lib'

# SKIP_TOKENS=17
rate_limit octokit_init
