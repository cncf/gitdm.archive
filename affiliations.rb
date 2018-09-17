require 'pry'
require 'csv'
require 'json'
require './comment'
require './email_code'

def affiliations(affiliations_file, json_file)
  # Parse input JSON
  users = {}
  data = JSON.parse File.read json_file
  data.each_with_index do |user, index|
    email = user['email']
    login = user['login']
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
      user = users[email]
      if !user && gh != '-'
        login = gh.split('/').last
        user = users[login]
        binding.pry unless user
      end
    end

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
  end
  puts "Imported #{all_affs.length} affiliations (#{wip} marked as work in progress)"
  all_affs.each { |d| STDERR.puts d }
end

if ARGV.size < 2
    puts "Missing arguments: affiliations.csv github_users.json"
  exit(1)
end

affiliations(ARGV[0], ARGV[1])
