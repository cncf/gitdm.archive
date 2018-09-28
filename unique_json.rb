#!/usr/bin/env ruby

require 'json'
require 'pry'

ARGV.each do |json_file|
  data = JSON.parse File.read json_file
  new_data = []
  dkeys = {}
  replaces = {}
  data.each do |row|
    key = [row['login'], row['email']]
    dkey = [row['login'].downcase, row['email']]
    unless dkeys.key?(dkey)
      new_data << row
      dkeys[dkey] = true
    else
      if dkey != key
        replaces[dkey] = key
      end
    end
  end
  new_data.each do |row|
    login = row['login']
    email = row['email']
    if replaces.key?([login, email])
      echo "Using non downcased login: '#{row['login']}' --> '#{eplaces[[login, email]][0]}'"
      row['login'] = replaces[[login, email]][0]
    end
  end
  pretty = JSON.pretty_generate new_data
  File.write json_file, pretty
  puts "Rows: #{data.length}, unique by login/email: #{new_data.length}"
end
