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
    binding.pry if s == 'notfound'
    known[c] = 0 unless known.key?(c)
    known[c] += 1
  end
end

k = {}
u = {}
known.each do |c, n|
  k[c] = n if c <= 10
  if c > 10 && c <= 15
    k[15] = 0 unless k.key?(11)
    k[15] += n
  end
  if c > 15 && c <= 20
    k[20] = 0 unless k.key?(20)
    k[20] += n
  end
  if c > 20 && c <= 50
    k[50] = 0 unless k.key?(50)
    k[50] += n
  end
  if c > 50 && c <= 100
    k[100] = 0 unless k.key?(100)
    k[100] += n
  end
  if c > 100 && c <= 1000
    k[1000] = 0 unless k.key?(1000)
    k[1000] += n
  end
  if c > 1000
    k[10000] = 0 unless k.key?(10000)
    k[10000] += n
  end
end

unknown.each do |c, n|
  u[c] = n if c <= 10
  if c > 10 && c <= 15
    u[15] = 0 unless u.key?(15)
    u[15] += n
  end
  if c > 15 && c <= 20
    u[20] = 0 unless u.key?(20)
    u[20] += n
  end
  if c > 20 && c <= 50
    u[50] = 0 unless u.key?(50)
    u[50] += n
  end
  if c > 50 && c <= 100
    u[100] = 0 unless u.key?(100)
    u[100] += n
  end
  if c > 100 && c <= 1000
    u[1000] = 0 unless u.key?(1000)
    u[1000] += n
  end
  if c > 1000
    u[10000] = 0 unless u.key?(10000)
    u[10000] += n
  end
end
sk = ''
k.keys.sort.reverse.each do |ky|
  sk += k[ky].to_s + ";"
end
print sk.chomp(';')+"\n"
su = ''
u.keys.sort.reverse.each do |k|
  su += u[k].to_s + ";"
end
STDERR.print su.chomp(';')+"\n"
