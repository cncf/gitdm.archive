require 'pry'
require 'csv'
require 'json'
require './comment'
require './email_code'

def affiliations(affiliations_file, json_file, email_map)
  # Parse input JSON
  users = {}
  json_data = JSON.parse File.read json_file
  json_data.each_with_index do |user, index|
    email = user['email'].downcase
    login = user['login'].downcase
    users[email] = [index, user]
    users[login] = [] unless users.key?(login)
    users[login] << [index, user]
  end

  all_affs = []
  ln = 1
  wip = 0
  CSV.foreach(affiliations_file, headers: true) do |row|
    ln += 1
    next if is_comment row
    h = row.to_h
    h['line_no'] = ln
    if h['affiliations'] == '/'
      wip += 1
      next
    end
    gh = h['github']
    possible_emails = (h['new emails'] || '').split(',').map(&:strip) << h['email'].strip
    emails = ((h['new emails'] || '').split(',').map(&:strip).map { |e| email_encode(e) } << email_encode(h['email'].strip)).reject { |e| e.nil? || e.empty? || !e.include?('!') }.uniq
    if emails.length != possible_emails.length
      puts "Wrong emails config (some discarded)"
      p h
      binding.pry
      next
    end
    possible_affs = (h['affiliations'] || '').split(',').map(&:strip)
    affs = possible_affs.reject { |a| a.nil? || a.empty? || a == '/' }.uniq
    if affs.length != possible_affs.length
      puts "Wrong affiliations config (some discarded)"
      p h
      binding.pry
      next
    end
    next if affs == []
    n_final = 0
    affs.each do |aff|
      ary = aff.split('<').map(&:strip)
      n_final += 1 if ary.length == 1
    end
    if n_final != 1
      puts "Wrong affiliation config - there must be exactly one final affiliation"
      p affs
      p h
      binding.pry
      next
    end

    aaffs = []
    affs.each do |aff|
      begin
        ddt = DateTime.strptime(aff, '%Y-%m-%d')
        sdt = ddt.strftime("%Y-%m-%d")
        puts "Wrong affiliation config - YYYY-MM-DD date found where company name expected"
        p aff
        p h
        binding.pry
        next
      rescue
      end
      possible_data = aff.split('<').map(&:strip)
      data = possible_data.reject { |a| a.nil? || a.empty? }.uniq
      if data.length < 1 || data.length > 2 || data.length != possible_data.length
        puts "Wrong affiliation config (multiple < or empty discarded values)"
        p data
        p h
        binding.pry
        next
      end
      if data.length == 1
        emails.each { |e| all_affs << "#{e} #{aff}" }
        aaffs << [DateTime.strptime('2099-01-01', '%Y-%m-%d'), "#{aff}"]
      elsif data.length == 2
        dt = data[1]
        if dt.length != 10
          puts "Wrong date format expected YYYY-MM-DD, got #{dt} (wrong length)"
          p data
          p h
          binding.pry
          next
        end
        begin
          ddt = DateTime.strptime(dt, '%Y-%m-%d')
          sdt = ddt.strftime("%Y-%m-%d")
          com = data[0]
          emails.each { |e| all_affs << "#{e} #{com} < #{sdt}" }
          aaffs << [ddt, "#{com} < #{sdt}"]
        rescue => err
          puts "Wrong date format expected YYYY-MM-DD, got #{dt} (invalid date)"
          p data
          p h
          p err
          binding.pry
          next
        end
      end
    end
    saffs = aaffs.sort_by { |r| r[0] }.map { |r| r[1] }.join(', ')

    gender = h['gender']
    gender = gender.downcase if gender
    if gender && gender != 'm' && gender != 'w' && gender != 'f'
      puts "Wrong affiliation config - gender must be m, w, f or nil"
      p affs
      p h
      binding.pry
    end
    gender = 'f' if gender == 'w'
    emails.each do |email|
      next if gh == '-'
      entry = users[email]
      login = gh.split('/').last
      entries = users[login]
      unless entry
        if entries
          user = json_data[entries.first[0]].clone
          user['email'] = email
          user['commits'] = 0
          index = json_data.length
          json_data << user
          users[email] = [index, user]
          users[login] << [index, user]
        else
          puts "Wrong affiliations config, entries not found for email #{email}, login #{login}"
          p affs
          p h
          binding.pry
        end
      end
      entries.each do |entry|
        index = entry[0]
        user = entry[1]
        if gender && user['sex'] != gender
          puts "Overwritten gender #{user['sex']} --> #{gender} for #{login}/#{user['email']}, commits #{user['commits']}" unless user['sex'].nil?
          json_data[index]['sex'] = gender
          json_data[index]['sex_prob'] = 1
        end
        if user['affiliation'] != saffs
          caffs = user['affiliation']
          unless caffs == '(Unknown)' || caffs == 'NotFound' || caffs == '?'
            puts "Overwritten affiliation #{user['affiliation']} --> #{saffs} for #{login}/#{user['email']}, commits #{user['commits']}"
          end
          json_data[index]['affiliation'] = saffs
        end
      end
    end
  end
  puts "Imported #{all_affs.length} affiliations (#{wip} marked as work in progress)"
  File.open(email_map, 'a') do |file|
    all_affs.each { |d| file.puts d }
  end

  # Write JSON back
  pretty = JSON.pretty_generate json_data
  File.write json_file, pretty
end

if ARGV.size < 3
    puts "Missing arguments: affiliations.csv github_users.json cncf-config/email-map"
  exit(1)
end

affiliations(ARGV[0], ARGV[1], ARGV[2])
