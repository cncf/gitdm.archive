require 'pry'
require 'csv'
require 'json'
require './comment'
require './email_code'
require './mgetc'

def affiliations(affiliations_file, json_file, email_map)
  # dbg: set to true to have very verbose output
  dbg = true
  # Parse input JSON, store current data in 'users'
  users = {}
  json_data = JSON.parse File.read json_file
  json_data.each_with_index do |user, index|
    email = user['email'].downcase
    login = user['login'].downcase
    users[email] = [index, user]
    users[login] = [] unless users.key?(login)
    users[login] << [index, user]
  end

  # parse current email-map, store data in 'eaffs'
  eaffs = {}
  File.readlines(email_map).each do |line|
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

  update = !ENV['UPDATE'].nil?

  # Check for carriage returns in CSV file
  unless update
    ln = 0
    File.readlines(affiliations_file).each do |line|
      ln += 1
      next if ln == 1
      line.strip!
      if !line.start_with?('(Unknown),') && !line.start_with?('NotFound,')
        puts "#{ln} Line start is wrong: '#{line}'"
        binding.pry
        exit 1
      end
    end
  end

  # Process new affiliations CSV
  all_affs = []
  ln = 1
  wip = 0
  n_keys = -1
  nu = 0
  begin
    CSV.foreach(affiliations_file, headers: true) do |row|
      ln += 1
      next if is_comment row
      h = row.to_h
      if n_keys < 0
        n_keys = h.keys.count
      else
        if n_keys != h.keys.count
          puts "Keys number mismatch: #{n_keys} != #{h.keys.count}"
          binding.pry
        end
      end
      h['line_no'] = ln
      if h['affiliations'] && h['affiliations'].strip == '/'
        wip += 1
        next
      end

      # In update mode only take rows with column changes=x
      next if update && h['changes'] != 'x'
      nu += 1

      # Bots
      gender = h['gender'].downcase if h['gender']
      if gender == 'b'
        h['affiliations'] = '(Robots)'
        h['gender'] = nil
      end

      # affiliations in new emails
      new_emails = h['new emails']
      if new_emails && new_emails.include?('<')
        puts "Wrong new emails config (includes <)"
        p h
        binding.pry
        next
      end

      # emails bugs/typos
      possible_emails = (new_emails || '').split(',').map(&:strip) << h['email'].strip
      emails = ((new_emails || '').split(',').map(&:strip).map { |e| email_encode(e) } << email_encode(h['email'].strip)).reject { |e| e.nil? || e.empty? || !e.include?('!') }.uniq
      if emails.length != possible_emails.length
        puts "Wrong emails config (some discarded)"
        p h
        binding.pry
        next
      end

      # dates in emails
      err = false
      emails.each do |email|
        begin
          ddt = DateTime.strptime(email, '%Y-%m-%d')
          sdt = ddt.strftime("%Y-%m-%d")
          puts "Wrong affiliation config - YYYY-MM-DD date found where new email expected"
          err = true
          p h
          binding.pry
          next
        rescue
        end
      end
      next if err

      # affiliations bugs/typos
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

      # process affiliations
      aaffs = []
      err = false
      affs_str = affs.join(', ')
      affs.each do |aff|
        begin
          ddt = DateTime.strptime(aff, '%Y-%m-%d')
          sdt = ddt.strftime("%Y-%m-%d")
          puts "Wrong affiliation config - YYYY-MM-DD date found where company name expected"
          err = true
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
          err = true
          p data
          p h
          binding.pry
          next
        end
        if data.length == 1
          emails.each do |e|
            if eaffs.key?(e) && !eaffs[e].key?(aff)
              if aff == 'NotFound'
                puts "Note: New not found for existing #{e} with '#{eaffs[e].keys}', line #{ln}"
                eaffs[e][aff] = true
              else
                if eaffs[e].key?('NotFound')
                  puts "Note: No longer not found #{e} now '#{aff}', line #{ln}"
                  eaffs[e].delete 'NotFound'
                  eaffs[e][aff] = true
                else
                  eaffs_str = eaffs[e].keys.join(', ')
                  puts "Note: #{e} already have affiliation: #{eaffs_str}, adding '#{aff}', line #{ln}" if dbg
                  dels = []
                  add = true
                  eaffs[e].each do |k|
                    ary = k[0].split('<').map(&:strip)
                    if ary.length != 2
                      upd = 'y'
                      if update
                        puts "Note update: #{e} already have a final affiliation '#{k[0]}' (all: #{eaffs_str}) while trying to add another final one: '#{aff}' (all: #{affs_str}), line #{ln}"
                      else
                        puts "Wrong: #{e} already have a final affiliation '#{k[0]}' (all: #{eaffs_str}) while trying to add another final one: '#{aff}' (all: #{affs_str}), line #{ln}"
                        puts "Update? (y/n)"
                        upd = mgetc
                      end
                      if upd == 'y' || upd == 'Y'
                        dels << k[0]
                      else
                        add = false
                      end
                    end
                  end
                  dels.each { |d| eaffs[e].delete d }
                  eaffs[e][aff] = true if add
                end
              end
            else
              if dbg
                if aff == 'NotFound'
                  puts "Note: new unknown email #{e}"
                else
                  puts "Note: new email #{e} with '#{aff}'"
                end
              end
              eaffs[e] = {}
              eaffs[e][aff] = true
            end
            all_affs << "#{e} #{aff}"
          end
          aaffs << [DateTime.strptime('2100-01-01', '%Y-%m-%d'), "#{aff}"]
        elsif data.length == 2
          dt = data[1]
          if dt.length != 10
            puts "Wrong date format expected YYYY-MM-DD, got #{dt} (wrong length)"
            p data
            p h
            binding.pry
            err = true
            next
          end
          begin
            ddt = DateTime.strptime(dt, '%Y-%m-%d')
            if ddt.year < 2000 || ddt.year > 2100
              puts "Wrong date format expected YYYY-MM-DD, got #{ddt} (invalid year: < 2000 or > 2100)"
              err = true
              p data
              p h
              p err
              binding.pry
              next
            end
            sdt = ddt.strftime("%Y-%m-%d")
            com = data[0]
            emails.each do |e|
              aff = "#{com} < #{sdt}"
              if eaffs.key?(e) && !eaffs[e].key?(aff)
                if eaffs[e].key?('NotFound')
                  puts "Note: No longer not found #{e} now '#{aff}', line #{ln}"
                  eaffs[e].delete 'NotFound'
                  eaffs[e][aff] = true
                else
                  eaffs_str = eaffs[e].keys.join(', ')
                  puts "Note: #{e} already have affiliation: #{eaffs_str}, adding '#{aff}', line #{ln}" if dbg
                  eaffs[e][aff] = true
                end
              else
                if dbg
                  if aff == 'NotFound'
                    puts "Note: new unknown email #{e}"
                  else
                    puts "Note: new email #{e} with '#{aff}'"
                  end
                end
                eaffs[e] = {}
                eaffs[e][aff] = true
              end
              all_affs << "#{e} #{com} < #{sdt}"
            end
            aaffs << [ddt, "#{com} < #{sdt}"]
          rescue => err
            puts "Wrong date format expected YYYY-MM-DD, got #{dt} (invalid date)"
            err = true
            p data
            p h
            p err
            binding.pry
            next
          end
        end
      end
      next if err

      if n_final != 1
        puts "Wrong affiliation config - there must be exactly one final affiliation"
        p affs
        p h
        binding.pry
        next
      end

      # info if adding affiliation to the existing email
      aaffs.each do |aaff|
        emails.each do |email|
          if eaffs.key?(email)
            unless eaffs[email].key?(aaff[1])
              puts "Note: Adding '#{aaff[1]}' affiliation to the existing email #{email}: #{eaffs[email].keys}, line #{ln}"
            end
          end
        end
      end
      saffs = aaffs.sort_by { |r| r[0] }.map { |r| r[1] }.join(', ')

      # non unique end dates for affiliations
      dta = aaffs.map { |r| r[0] }
      dtau = dta.uniq
      if dta.length != dtau.length
        puts "Wrong affiliation config - non unique end dates"
        p affs
        p dta
        p h
        binding.pry
      end

      # gender
      gender = h['gender']
      gender = gender.downcase if gender
      if gender && gender != 'm' && gender != 'w' && gender != 'f'
        puts "Wrong affiliation config - gender must be m, w, f or nil"
        p affs
        p h
        binding.pry
      end
      gender = 'f' if gender == 'w'

      # process affiliations vs existing JSON data
      ghs = h['github']
      gha = ghs.split(',').map(&:strip)
      puts "Note: multiple GH logins #{gha} for emails #{emails}, line #{ln}" if dbg && gha.length > 1
      gha.each do |gh|
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
              puts "Note: overwritten gender #{user['sex']} --> #{gender} for #{login}/#{user['email']}, commits #{user['commits']}, line #{ln}" unless user['sex'].nil?
              json_data[index]['sex'] = gender
              json_data[index]['sex_prob'] = 1
            end
            if user['affiliation'] != saffs
              caffs = user['affiliation']
              unless caffs == '(Unknown)' || caffs == 'NotFound' || caffs == '?' || saffs == 'NotFound' || caffs.nil?
                puts "Note: overwritten affiliation '#{user['affiliation']}' --> '#{saffs}' for #{login}/#{user['email']}, commits #{user['commits']}, line #{ln}"
              end
              if caffs != '(Unknown)' && caffs != 'NotFound' && caffs != '?' && !caffs.nil? && saffs == 'NotFound'
                puts "Wrong: not overwritten affiliation '#{user['affiliation']}' --> '#{saffs}' for #{login}/#{user['email']}, commits #{user['commits']}, line #{ln}"
              else
                json_data[index]['affiliation'] = saffs
              end
            end
          end
        end
      end
    end
  rescue CSV::MalformedCSVError => e
    puts "CSV error on line #{ln}: #{e}"
    binding.pry
  end
  puts "Processed #{nu} update rows " if update
  puts "Imported #{all_affs.length} affiliations (#{wip} marked as work in progress)"
  # File.open(email_map, 'a') do |file|
  #   all_affs.each { |d| file.puts d }
  # end
  File.open(email_map, 'w') do |file|
     file.puts "# Here is a set of mappings of domain names onto employer names."
     file.puts "# [user!]domain  employer  [< yyyy-mm-dd]"
     eaffs.each do |email, affs|
        affs.each do |aff, _|
          file.puts "#{email} #{aff}"
        end
     end
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
