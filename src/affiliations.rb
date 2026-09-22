require 'pry'
require 'csv'
require 'json'
require './comment'
require './email_code'
require './mgetc'

def affiliations(affiliations_file, json_file, email_map)
  # affiliation sources priorities
  prios = {}
  prios['user'] = 3
  prios['user_manual'] = 2
  prios['manual'] = 1
  prios['config'] = 0
  prios[true] = 0
  prios[nil] = 0
  prios['domain'] = -1
  prios['notfound'] = -2
  manual_prio = prios['manual']

  # dbg: set to true to have very verbose output
  dbg = !ENV['DBG'].nil?
  # Parse input JSON, store current data in 'users'
  users = {}
  sources = {}
  prev_sources = {}
  json_data = JSON.parse File.read json_file
  json_data.each_with_index do |user, index|
    email = user['email'].downcase
    login = user['login'].downcase
    source = user['source']
    users[email] = [[index, user]]
    users[login] = [] unless users.key?(login)
    users[login] << [index, user]
    sources[email] = source unless source.nil?
    prev_sources[email] = source unless prev_sources.nil?
  end

  # parse current email-map, store data in 'eaffs'
  eaffs = {}
  prev_eaffs = {}
  File.readlines(email_map).each do |line|
    line.strip!
    if line.length > 0 && line[0] == '#'
      next
    end
    ary = line.split ' '
    email = ary[0]
    source = sources[email]
    eaffs[email] = {} unless eaffs.key?(email)
    prev_eaffs[email] = {} unless prev_eaffs.key?(email)
    aff = ary[1..-1].join(' ')
    eaffs[email][aff] = source ? source : true
    prev_eaffs[email][aff] = source ? source : true
  end
  puts "Default affiliation sources: #{eaffs.values.map { |v| v.values }.flatten.count { |v| v === true }}"
  sourcetypes = eaffs.values.map { |v| v.values }.flatten.uniq
  sourcetypes.each do |source_type|
    next if source_type === true
    puts "#{source_type.capitalize} affiliation sources: #{eaffs.values.map { |v| v.values }.flatten.count { |v| v == source_type }}"
  end

  update = !ENV['UPDATE'].nil?
  recheck = !ENV['RECHECK'].nil?

  # Check for carriage returns in CSV file
  if update
    ln = 0
    File.readlines(affiliations_file).each do |line|
      ln += 1
      next if ln == 1
      line.strip!
      ary = line.split ','
      if !ary[1].match?(/[^\s!]+![^\s!]+/) || !ary[0].match?(/\w+/)
        puts "#{ln} Line start is wrong: '#{line}'"
        binding.pry
        exit 1
      end
    end
  else
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
  ln = 1
  wip = 0
  n_keys = -1
  nu = 0
  replaced = skipped = added = unknown = multiple = 0
  answers = {}
  json_cache = 'affiliations_answers_cache.json'
  begin
    answers = JSON.parse File.read json_cache
  rescue
  end
  begin
    CSV.foreach(affiliations_file, headers: true) do |row|
      ln += 1
      puts ln if dbg
      next if is_comment row
      h = row.to_h
      if n_keys < 0
        n_keys = h.keys.count
      else
        if n_keys != h.keys.count
          puts "Keys number mismatch: #{n_keys} != #{h.keys.count}, line #{ln}"
          binding.pry
        end
      end
      h.each do |k, v|
        next if v.nil?
        if v.include?("\r") || v.include?("\n")
          puts "Key #{k}, value '#{v}' conatins new line, line #{ln}"
          binding.pry
        end
      end
      h['line_no'] = ln
      if h['affiliations'] && h['affiliations'].strip == '/'
        wip += 1
        next
      end

      # In update mode only take rows with column changes=x
      x = h['changes']
      x = x.strip if x
      next if update && x != 'x'
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
      new_emails.strip! if new_emails

      # emails bugs/typos
      curr_emails = (h['email'] || '').split(',').map(&:strip).map(&:downcase)
      possible_emails = (new_emails || '').split(',').map(&:strip).map(&:downcase) + curr_emails
      emails = possible_emails.map { |e| email_encode(e) }.reject { |e| e.nil? || e.empty? || !e.include?('!') }.uniq
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

      # handle skip
      skip_flag = false

      # process affiliations
      aaffs = []
      err = false
      affs_str = affs.join(', ')
      replaced_emails = {}
      affs.each do |aff|
        next if skip_flag
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
          emails.each_with_index do |e, idx|
            next if skip_flag
            if eaffs.key?(e) && !eaffs[e].key?(aff) && !replaced_emails.key?(e)
              ans = 'y'
              ans = 'n' if aff == 'NotFound' && !recheck
              if prios[sources[e]] > manual_prio
                if answers.key?(e) && !recheck
                  ans = answers[e]
                else
                  s = "Line #{ln}, user #{users[e][0][1]['login']}, email #{e} has affiliation source type '#{sources[e]}' which has higher priority than 'manual'\n"
                  s += "Config affiliations: #{eaffs[e].keys.join(', ')}\nJSON affiliations: #{users[e][0][1]['affiliation']}\nNew affiliations: #{affs_str}\nReplace? (y/n/q/s)"
                  puts s
                  ans = mgetc.downcase
                  puts "> #{ans}"
                  exit 0 if ans == 'q' or ans == 'Q'
                  if ans == 's' or ans == 's'
                    skip_flag = true
                    break
                  end
                  answers[e] = ans
                  pretty = JSON.pretty_generate answers
                  File.write json_cache, pretty
                end
              end
              if ans == 'y'
                source_type = %w(user user_manual).include?(sources[e]) ? 'user_manual' : 'manual'
                sources[e] = source_type
                eaffs[e] = {}
                eaffs[e][aff] = source_type
                replaced_emails[e] = source_type
                replaced += 1
              else
                skipped += 1
              end
            end
            if eaffs.key?(e) && !eaffs[e].key?(aff) && replaced_emails.key?(e) && aff != 'NotFound'
              source_type = %w(user user_manual).include?(sources[e]) ? 'user_manual' : 'manual'
              eaffs[e][aff] = source_type
              multiple += 1
            end
            if !eaffs.key?(e)
              source_type = %w(user user_manual).include?(sources[e]) ? 'user_manual' : 'manual'
              sources[e] = source_type
              eaffs[e] = {}
              eaffs[e][aff] = source_type
              if dbg && aff == 'NotFound'
                puts "Note: new unknown email #{e}"
                unknown += 1
                eaffs[e][aff] = 'notfound'
                sources[e] = 'notfound'
              else
                added += 1
              end
            end
            aaffs << [DateTime.strptime('2100-01-01', '%Y-%m-%d'), "#{aff}"] if idx == 0
          end
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
            emails.each_with_index do |e, idx|
              next if skip_flag
              aff = "#{com} < #{sdt}"
              if eaffs.key?(e) && !eaffs[e].key?(aff) && !replaced_emails.key?(e)
                ans = 'y'
                if prios[sources[e]] > manual_prio
                  if answers.key?(e) && !recheck
                    ans = answers[e]
                  else
                    s = "Line #{ln}, user #{users[e][0][1]['login']}, email #{e} has affiliation source type '#{sources[e]}' which has higher priority than 'manual'\n"
                    s += "Config affiliations: #{eaffs[e].keys.join(', ')}\nJSON affiliations: #{users[e][0][1]['affiliation']}\nNew affiliations: #{affs_str}\nReplace? (y/n/q/s)"
                    puts s
                    ans = mgetc.downcase
                    puts "> #{ans}"
                    exit 0 if ans == 'q' or ans == 'Q'
                    if ans == 's' or ans == 's'
                      skip_flag = true
                      break
                    end
                    answers[e] = ans
                    pretty = JSON.pretty_generate answers
                    File.write json_cache, pretty
                  end
                end
                if ans == 'y'
                  source_type = %w(user user_manual).include?(sources[e]) ? 'user_manual' : 'manual'
                  sources[e] = source_type
                  eaffs[e] = {}
                  eaffs[e][aff] = source_type
                  replaced_emails[e] = source_type
                  replaced += 1
                else
                  skipped += 1
                end
              end
              if eaffs.key?(e) && !eaffs[e].key?(aff) && replaced_emails.key?(e)
                source_type = %w(user user_manual).include?(sources[e]) ? 'user_manual' : 'manual'
                eaffs[e][aff] = source_type
                multiple += 1
              end
              if !eaffs.key?(e)
                source_type = %w(user user_manual).include?(sources[e]) ? 'user_manual' : 'manual'
                sources[e] = source_type
                eaffs[e] = {}
                eaffs[e][aff] = source_type
                added += 1
              end
              aaffs << [ddt, "#{com} < #{sdt}"] if idx == 0
            end
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

      next if skip_flag

      # info if adding affiliation to the existing email
      aaffs.each do |aaff|
        emails.each do |email|
          if eaffs.key?(email)
            unless eaffs[email].key?(aaff[1])
              puts "Note: Adding '#{aaff[1]}' affiliation to the existing email #{email}: #{eaffs[email].keys}, line #{ln}" if dbg
              source_type = %w(user user_manual).include?(sources[email]) ? 'user_manual' : 'manual'
              eaffs[email][aaff[1]] = source_type
              multiple += 1
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
      gender = nil if gender == ''
      gender = gender.downcase if gender
      gender = gender.strip if gender
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
          if users[email] == nil
            puts "Unknown #{email} email - not present in JSON file"
            # FIXME/TODO we should avoid this
            # next
          end
          entry = users[email][0]
          login = gh.split('/').last.downcase
          entries = users[login]
          prev_source = prev_sources[email]
          source = sources[email]
          #next unless source
          source = 'config' if source.nil?
          source = 'notfound' if saffs == 'NotFound'
          entry = nil
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
              # binding.pry
              next
            end
          end
          entries.each do |entry|
            index = entry[0]
            user = entry[1]
            higher_prio = prios[prev_source] > prios[source]
            if gender && gender.length == 1 && user['sex'] != gender
              puts "Note: overwriting gender #{user['sex']} --> #{gender} for #{login}/#{user['email']}, commits #{user['commits']}, line #{ln}" if dbg && !user['sex'].nil?
              ans = 'y'
              if higher_prio
                answers[login] = 'y' if user['sex'].nil? || user['sex'] == ''
                if answers.key?(login) && !recheck
                  ans = answers[login]
                else
                  puts "Overwrite gender #{user['sex']} --> #{gender} for #{login}/#{user['email']}, commits #{user['commits']}, line #{ln}?"
                  puts "Current data has higher priority '#{prev_source}' than '#{source}', replace? (y/n)"
                  ans = mgetc.downcase
                  answers[login] = ans
                  pretty = JSON.pretty_generate answers
                  File.write json_cache, pretty
                end
              end
              if ans == 'y'
                puts "Note: '#{prev_source}' -> '#{source}' overwritten gender #{user['sex']} --> #{gender} for #{login}/#{user['email']}, commits #{user['commits']}, line #{ln}" unless user['sex'].nil?
                json_data[index]['sex'] = gender
                json_data[index]['sex_prob'] = 1
                json_data[index]['source'] = source
              end
            end
            if user['affiliation'] != saffs
              caffs = user['affiliation']
              if caffs != '(Unknown)' && caffs != 'NotFound' && caffs != '?' && caffs != '' && !caffs.nil? && saffs != 'NotFound' && dbg
                puts "Note: overwriting affiliation '#{user['affiliation']}' --> '#{saffs}' for #{login}/#{user['email']}, commits #{user['commits']}, line #{ln}"
              end
              if caffs != '(Unknown)' && caffs != 'NotFound' && caffs != '?' && caffs != '' && !caffs.nil? && saffs == 'NotFound' && !recheck
                puts "Wrong: not overwritten affiliation '#{user['affiliation']}' --> '#{saffs}' for #{login}/#{user['email']}, commits #{user['commits']}, line #{ln}"
                eaffs[user['email']].delete('NotFound') if eaffs.key?(user['email'])
              else
                ans = 'y'
                if higher_prio
                  answers[login] = 'y' if saffs == 'NotFound' && ['?', '(Unknown)', '', nil].include?(user['affiliation'])
                  if answers.key?(login) && !recheck
                    ans = answers[login]
                  else
                    puts "Overwritte affiliation '#{user['affiliation']}' --> '#{saffs}' for #{login}/#{user['email']}, commits #{user['commits']}, line #{ln}?"
                    puts "Current data has higher priority '#{prev_source}' than '#{source}', replace? (y/n)"
                    ans = mgetc.downcase
                    answers[login] = ans
                    pretty = JSON.pretty_generate answers
                    File.write json_cache, pretty
                  end
                end
                if ans == 'y'
                  a = user['affiliation']
                  puts "Note: '#{prev_source}' -> '#{source}' overwritten affiliation '#{user['affiliation']}' --> '#{saffs}' for #{login}/#{user['email']}, commits #{user['commits']}, line #{ln}" unless ['', '?', 'NotFound', '(Unknown)', nil].include?(a)
                  json_data[index]['affiliation'] = saffs
                  json_data[index]['source'] = source
                end
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
  puts "Replaced: #{replaced}, skipped: #{skipped}, added new: #{added}, added affiliation: #{multiple}, new unknown: #{unknown}"

  puts "### Just before this final write ###"
  binding.pry

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
