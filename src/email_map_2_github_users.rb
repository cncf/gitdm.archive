#!/usr/bin/env ruby

require 'json'
require 'pry'

def is_ok_aff(aff)
  aff && aff != '' && aff != 'NotFound' && aff != '?' && aff != 'NotFund' && aff != 'NotFond' && aff != '(Unknown)'
end

dbg = !ENV['DBG'].nil?

# parse current email-map, store data in 'eaffs'
eaffs = {}
File.readlines('cncf-config/email-map').each do |line|
  line.strip!
  if line.length > 0 && line[0] == '#'
    next
  end
  ary = line.split ' '
  email = ary[0]
  eaffs[email] = {} unless eaffs.key?(email)
  aff = ary[1..-1].join(' ')
  eaffs[email][aff] = true
end

saffs = {}
saffsd = {}
eaffs.each do |email, affs|
  # puts "#{email} #{affs}"
  by_dates = {}
  dates = []
  final = ''
  multi_final = false
  affs.each do |affS|
    aff = affS[0]
    # puts "#{aff}"
    ary = aff.split '<'
    if ary.length == 1
      if final == ''
        final = ary[0].strip
      else
        multi_final = true
      end
    else
      date = ary[1].strip
      dates << date
      by_dates[date] = ary[0].strip
    end
  end
  if multi_final
    puts "skipping multi final: #{email} #{affs}" if dbg
    next
  end
  dates.sort!
  affs = []
  dates.each do |date|
    aff = by_dates[date]
    affs << "#{aff} < #{date}" if is_ok_aff(aff)
  end
  affs << final if is_ok_aff(final)
  saffs[email] = affs.join ', ' if affs.length > 0
  saffsd[email.downcase] = affs.join ', ' if affs.length > 0
end

# Parse JSON
data = JSON.parse File.read 'github_users.json'

updates = 0
fixes = 0
skips = 0
data.each_with_index do |user, idx|
  affiliation = user['affiliation'].strip
  next if !is_ok_aff(affiliation)
  email = user['email'].strip
  next if !email || email == ''
  by_dates = {}
  dates = []
  final = ''
  multi_final = false
  ar = affiliation.split ','
  ar.each do |aff|
    aff.strip!
    ary = aff.split '<'
    if ary.length == 1
      if final == ''
        final = ary[0].strip
      else
        multi_final = true
      end
    else
      date = ary[1].strip
      dates << date
      by_dates[date] = ary[0].strip
    end
  end
  if multi_final
    puts "#{idx}: multi final: #{email}: #{affiliation}, skipping" if dbg
    next
  end
  dates.sort!
  affs = []
  dates.each do |date|
    aff = by_dates[date]
    affs << "#{aff} < #{date}" if is_ok_aff(aff)
  end
  affs << final if is_ok_aff(final)
  affiliationS = affs.join ', '
  if affiliationS != affiliation
    puts "#{idx}: update: #{affiliation} -> #{affiliationS}"
    data[idx]['affiliation'] = affiliationS
    updates += 1
  end
  caffiliation = saffs[email]
  if !caffiliation
    caffiliation = saffsd[email.downcase]
  end
  if caffiliation && caffiliation != affiliationS
    fn = affiliationS.split(',').length
    tn = caffiliation.split(',').length
    if tn >= fn
      puts "#{idx}: fix: #{affiliationS} -> #{caffiliation}"
      data[idx]['affiliation'] = caffiliation
      fixes += 1
    else
      puts "#{idx}: not fixing: #{affiliationS} -> #{caffiliation}"
      skips += 1
    end
  end
end

if updates > 0
  puts "updated #{updates} affiliations (reorder, whitespace etc.)"
end
if fixes > 0
  puts "fixed #{fixes} affiliations (not matching config)"
end
if skips > 0
  puts "not fixed/skipped #{skips} affiliations (would downgrade number of affiliations)"
end

puts "type exit-program here, otherwise changes will be saved back to github_users.json"
binding.pry

# Write JSON back
json = JSON.pretty_generate data
File.write 'github_users.json', json
