#!/usr/bin/env ruby

require 'json'
require 'csv'
require 'pry'

def update_json(json_file, csv_file)
  dbg = !ENV['DBG'].nil?
  cnts = {}
  CSV.foreach(csv_file, headers: true) do |row|
    login = row['login'].downcase
    cnt = row['cnt'].to_i
    cnts[login] = cnt
  end
  data = JSON.parse File.read json_file
  updates = 0
  data.each_with_index do |row, i|
    login = row['login'].downcase
    cnt = row['commits'].to_i
    next unless cnts.key?(login)
    ncnt = cnts[login]
    next if ncnt <= cnt
    puts "update #{i} #{login} #{cnt} -> #{ncnt}" if dbg
    row['commits'] = ncnt
    updates += 1
  end
  if updates > 0
    data = data.sort_by { |u| [-u['commits'], u['login'], u['email']] }
    pretty = JSON.pretty_generate data
    File.write json_file, pretty
    puts "updated #{updates} entries"
  else
    puts "everything up to date"
  end
end

update_json('github_users.json', 'login_contributions.csv')
