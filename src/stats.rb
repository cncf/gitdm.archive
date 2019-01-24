#!/usr/bin/env ruby

require 'json'
require 'pry'

stats = {}
stats['unknown'] = 0
stats['notfound'] = 0
stats['config'] = 0

data = JSON.parse File.read ARGV[0]
data.each do |user|
  a = (user['affiliation'] || '').strip
  s = (user['source'] || '').strip
  if a == '' || a == '?' || a == '(Unknown)'
    stats['unknown'] += 1
  elsif a == 'NotFound' || s == 'notfound'
    stats['notfound'] += 1
  else
    if s == ''
      stats['config'] += 1
    else
      stats[s] = 0 unless stats.key?(s)
      stats[s] += 1
    end
  end
end
p stats
