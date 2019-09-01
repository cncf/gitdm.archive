#!/usr/bin/env ruby

require 'json'
require 'pry'

known = {}
unknown = {}
data = JSON.parse File.read ARGV[0]
data.each do |user|
  a = (user['affiliation'] || '').strip
  s = (user['source'] || '').strip
  c = user['commits']
  if a == '' || a == '?' || a == '(Unknown)' || a == 'NotFound'
    unknown[c] = 0 unless unknown.key?(c)
    unknown[c] += 1
  else
    #binding.pry if s == 'notfound'
    known[c] = 0 unless known.key?(c)
    known[c] += 1
  end
end

k = {}
u = {}

ranges = [
  [-1, 0, 0],
  [0, 1, 1],
  [1, 2, 2],
  [2, 3, 3],
  [3, 4, 4],
  [4, 5, 5],
  [5, 6, 6],
  [6, 7, 7],
  [7, 8, 8],
  [8, 9, 9],
  [9, 10, 10],
  [10, 15, 15],
  [15, 20, 20],
  [20, 50, 50],
  [50, 100, 100],
  [100, 1000, 1000],
  [1000, 1e9, 1001]
]

known.each do |c, n|
  ranges.each do |f, t, idx|
    if c > f && c <= t
      k[idx] = 0 unless k.key?(idx)
      k[idx] += n
    end
  end
end

unknown.each do |c, n|
  ranges.each do |f, t, idx|
    if c > f && c <= t
      u[idx] = 0 unless u.key?(idx)
      u[idx] += n
    end
  end
end

sk = ''
k.keys.sort.reverse.each do |ky|
  sk += k[ky].to_s + ","
end
print sk.chomp(',')+"\n"
su = ''
u.keys.sort.reverse.each do |k|
  su += u[k].to_s + ","
end
STDERR.print su.chomp(',')+"\n"
