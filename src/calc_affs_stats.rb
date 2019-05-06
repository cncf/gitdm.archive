require 'pry'
require 'json'

def calc_affs_stats(email_map_file, json_file, all_actors_file, cncf_actors_file, lf_actors_file)

  # Process actors file: it is a "," separated list of GitHub logins
  actors_data = File.read all_actors_file
  actors_array = actors_data.split(',').map(&:strip)
  all_actors = {}
  actors_array.each do |actor|
    all_actors[actor.downcase.strip] = true
  end

  actors_data = File.read cncf_actors_file
  actors_array = actors_data.split(',').map(&:strip)
  cncf_actors = {}
  actors_array.each do |actor|
    cncf_actors[actor.downcase.strip] = true
  end

  # For actors LF this is "\n" separated data
  actors_data = File.read lf_actors_file
  actors_array = actors_data.split("\n").map(&:strip)
  lf_actors = {}
  actors_array.each do |actor|
    lf_actors[actor.downcase.strip] = true
  end

  # parse current email-map, store data in 'eaffs'
  eaffs = {}
  File.readlines(email_map_file).each do |line|
    line.strip!
    if line.length > 0 && line[0] == '#'
      next
    end
    ary = line.split ' '
    next unless ary && ary[0]
    email = ary[0].downcase.strip
    next unless email.include?('!')
    aff = ary[1..-1].join(' ').downcase.strip
    eaffs[email] = [] unless eaffs.key?(email)
    eaffs[email] << (aff == 'notfound' ? 'nf' : 'f')
  end

  # Parse JSON
  data = JSON.parse File.read json_file

  emails = {}
  logins = {}
  data.each do |user|
    e = user['email'].downcase.strip
    next unless e.include?('!')
    l = user['login'].downcase.strip
    a = (user['affiliation'] || '').downcase.strip
    if a == 'notfound'
      r = ['nf']
    elsif ['', '?', '-', '(unknown)'].include?(a)
      r = ['nc']
    else
      r = ['f'] * a.split(',').length
    end
    unless eaffs.key?(e)
      eaffs[e] = r
    end
    logins[e] = l
    emails[l] = [] unless emails.key?(l)
    emails[l] << e
  end

  eaffs.each do |e, a|
    if e.include?('!users.noreply.github.com') && !logins.key?(e)
      logins[e] = e[0..-26]
    end
  end

  # Analyse affiliations
  nl = 0
  f = 0
  nf = 0
  nc = 0
  fa = 0
  nfa = 0
  nca = 0
  fc = 0
  nfc = 0
  ncc = 0
  fl = 0
  nfl = 0
  ncl = 0
  eaffs.each do |e, a|
    l = nil
    unless logins.key?(e)
      # puts "#{e} has no GitHub login"
      nl += 1
    else
      l = logins[e]
    end
    if a == ['nf']
      nf += 1
      nfa += 1 if all_actors.key?(l)
      nfc += 1 if cncf_actors.key?(l)
      nfl += 1 if lf_actors.key?(l)
    elsif a == ['nc']
      nc += 1
      nca += 1 if all_actors.key?(l)
      ncc += 1 if cncf_actors.key?(l)
      ncl += 1 if lf_actors.key?(l)
    else
      f += a.length
      fa += a.length if all_actors.key?(l)
      fc += a.length if cncf_actors.key?(l)
      fl += a.length if lf_actors.key?(l)
    end
  end

  puts "#{nfa},#{fa},#{nca},#{nfc},#{fc},#{ncc},#{nfl},#{fl},#{ncl}"
end

if ARGV.size < 5
  puts "Missing arguments: email_map_file json_file all_actors_file cncf_actors_file (cncf-config/email-map github_users.json actors.txt actors_cncf.txt actors_lf.txt)"
  exit(1)
end

calc_affs_stats(ARGV[0], ARGV[1], ARGV[2], ARGV[3], ARGV[4])
