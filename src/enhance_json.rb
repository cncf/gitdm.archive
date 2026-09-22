require 'pry'
require 'json'
require 'csv'
require 'octokit'
require 'set'
require 'thwait'
require './comment'
require './email_code'
require './ghapi'
require './merge'
require './mgetc'

def enchance_json(json_file, csv_file, actors_file, map_file)
  # This enables guessing if multiple final affiliations are given
  # Best option is to avoid this, by specifying exact affiliations everywhere!
  guess_by_email = true
  guess_by_name = !ENV['GUESS_BY_EMAIL'].nil?

  # When asking for current 'c' or new 'n' -> just use the longer one
  use_longer = !ENV['USE_LONGER'].nil?

  # Process actors file: it is a "," separated list of GitHub logins
  actors_data = File.read actors_file
  actors_array = actors_data.split(',').map(&:strip)
  actors = {}
  actors_array.each do |actor|
    actors[actor] = true
  end
  actors_array = actors_data = nil

  # parse current email-map, store data in 'eaffs'
  eaffs = {}
  File.readlines(map_file).each do |line|
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

  # Process affiliations found by Python cncf/gitdm saved in CSV
  # "email","name","company","date_to","source"
  email_affs = {}
  name_affs = {}
  names = {}
  emails = {}
  sources = {}
  CSV.foreach(csv_file, headers: true) do |row|
    next if is_comment row
    h = row.to_h
    e = email_encode(h['email'].strip)
    c = h['company'].strip
    n = h['name'].strip
    d = h['date_to'].strip
    s = h['source']

    # email -> names mapping (unique always, but dict just in case)
    names[e] = {} unless names.key?(e)
    names[e][n] = true

    # name --> emails mapping (one name can have multiple emails)
    emails[n] = {} unless emails.key?(n)
    emails[n][e] = true

    # affiliations by email
    email_affs[e] = [] unless email_affs.key?(e)
    if d && d.length > 0
      email_affs[e] << "#{c} < #{d}"
    else
      email_affs[e] << c
    end

    # affiliations by name
    name_affs[n] = [] unless name_affs.key?(n)
    if d && d.length > 0
      name_affs[n] << "#{c} < #{d}"
    else
      name_affs[n] << c
    end

    sources[e] = s
  end

  # Make results as strings
  puts "Checking affiliations by email #{guess_by_email} - this should not generate warnings"
  email_affs.each do |email, comps|
    a = check_affs_list email, comps, guess_by_email, guess_by_email
    email_affs[email] = sort_affs(a)
  end

  puts "Checking affiliations by name #{guess_by_name} - this can generate a lot of warnings"
  name_affs.each do |name, comps|
    a = check_affs_list name, comps, guess_by_name, guess_by_name
    name_affs[name] = sort_affs(a)
  end
  
  # Parse JSON
  data = JSON.parse File.read json_file

  # Enchance JSON
  answers = {}
  json_cache = 'enchance_cache.json'
  begin
    answers = JSON.parse File.read json_cache
  rescue
  end
  n_users = data.count
  enchanced = csv_not_found = 0
  email_unks = []
  name_unks = []
  json_emails = {}
  known_logins = {}
  n_users = data.length
  data.each_with_index do |user, idx|
    e = email_encode(user['email'])
    n = user['name']
    l = user['login']
    known_logins[l] = true
    json_emails[e] = true
    v = '?'
    if guess_by_email && email_affs.key?(e)
      # p [e, n, emails[n], names[e], email_affs[e], name_affs[n]]
      enchanced += 1
      v = email_affs[e]
    else
      if guess_by_name && name_affs.key?(n)
        # p [e, n, emails[n], names[e], email_affs[e], name_affs[n]]
        enchanced += 1
        v = name_affs[n]
      else
        csv_not_found += 1
        email_unks << e
        name_unks << n
      end
    end
    cv = sort_affs(user['affiliation'])
    cs = user['source']
    if cv.nil? || cv == '(Unknown)' || cv == 'NotFound' || cv == '?'
      user['affiliation'] = v unless v == '(Unknown)' || v == '?'
    else
      if cv != v && v != '?' && v != '(Unknown)'
        puts "Warning #{idx}/#{n_users}: #{e}: #{cs}\nCurrent '#{cv}'\nNew     '#{v}'\nc/n/q?"
        binding.pry if v.is_a?(Array)
        answer = '?'
        if use_longer
          cvi = cv.include? ' < '
          nvi = v.include? ' < '
          if cvi && !nvi
            answer = 'c'
          elsif !cvi && nvi
            answer = 'n'
          elsif cvi && nvi
            answer = (cv.length >= v.length) ? 'c' : 'n'
          end
        end
        if answer == '?'
          if answers.key?(e)
            answer = answers[e]
            puts "#{answer}\n"
          else
            answer = mgetc.downcase
            answers[e] = answer unless answer == 'q'
            pretty = JSON.pretty_generate answers
            File.write json_cache, pretty
          end
        end
        # answer = 'c'
        if answer == 'n'
          user['affiliation'] = v
        elsif answer == 'c'
          if eaffs.key?(e)
            eaffs.delete e
          end
          eaffs[e] = {}
          cv.split(', ').each { |a| eaffs[e][a] = true }
        else
          puts "Exiting due to answer #{answer}"
          exit 1
        end
      end
    end
  end
  puts 'Done main loop'

  # Write new email-map
  File.open(map_file, 'w') do |file|
     file.puts "# Here is a set of mappings of domain names onto employer names."
     file.puts "# [user!]domain  employer  [< yyyy-mm-dd]"
     eaffs.each do |email, affs|
        affs.each do |aff, _|
          file.puts "#{email} #{aff}"
        end
     end
  end

  # Merge multiple logins
  merge_multiple_logins data, false

  skip_logins = {}
  str = File.read 'skip_github_logins.txt'
  skip_logins_arr = str.strip.split(',') + [nil]
  skip_logins_arr.each { |skip_login| skip_logins[skip_login] = true }
  File.write 'skip_github_logins.txt', skip_logins_arr.reject { |l| l.nil? }.sort.uniq.join(',')

  # Actors from cncf/devstats that are missing in our JSON
  unknown_actors = {}
  actors.keys.each do |actor|
    unknown_actors[actor] = true unless known_logins.key?(actor) || skip_logins.key?(actor)
  end
  puts "We are missing #{unknown_actors.keys.count} contributors from #{actors_file}"

  # Actors from our JSON that have no contributions in cncf/devstats
  unknown_logins = {}
  known_logins.keys.each do |login|
    unknown_logins[login] = true unless actors.key?(login)
  end
  puts "We have #{unknown_logins.keys.count} actors in our JSON not listed in #{actors_file}"

  actor_not_found = 0
  actors_found = 0
  if unknown_actors.keys.count > 0
    n_thrs = ENV['NCPUS'].nil? ? Etc.nprocessors : ENV['NCPUS'].to_i
    gcs = octokit_init()
    hint = rate_limit(gcs)[0]
    puts "We need to process additional actors using GitHub API, type exit-program if you want to exit"
    puts "uacts.join(\"', '\")"
    uacts = unknown_actors.keys
    uacts.shuffle! unless ENV['SHUFFLE'].nil?
    n_users = uacts.size
    rpts = 0
    thrs = Set[]
    binding.pry
    uacts.each_with_index do |actor, index|
      thrs << Thread.new do
        while true
          res = []
          begin
            if rpts <= 0
              hint, rem, pts = rate_limit(gcs)
              rpts = pts / 10
              puts "Allowing #{rpts} calls without checking rate"
            else
              rpts -= 1
              #puts "#{rpts} calls remain before next rate check"
            end
            e = "#{actor}!users.noreply.github.com"
            puts "Asking for #{index}/#{n_users}: GitHub: #{actor}, email: #{e}, found so far: #{actors_found}"
            u = gcs[hint].user actor
            login = u['login']
            n = u['name']
            u['email'] = e
            u['commits'] = 0
            v = '?'
            if guess_by_email && email_affs.key?(e)
              p [e, n, emails[n], names[e], email_affs[e], name_affs[n]]
              actors_found += 1
              v = email_affs[e]
            else
              if guess_by_name && name_affs.key?(n)
                p [e, n, emails[n], names[e], email_affs[e], name_affs[n]]
                actors_found += 1
                v = name_affs[n]
                e2 = emails[n].keys.first
                u['email'] = e2 unless e2 == e
              else
                actor_not_found += 1
              end
            end
            u['affiliation'] = v
            puts "Got name: #{u[:name] || u['name']}, login: #{u[:login] || u['login']}"
            h = u.to_h
            res << h
            if login != actor
              u2 = u.clone
              u2['login'] = actor
              h2 = u2.to_h
              res << h2
            end
          rescue Octokit::NotFound => err
            puts "GitHub doesn't know actor #{actor}"
            puts err
            break
          rescue Octokit::AbuseDetected => err
            puts "Abuse #{err} for #{actor}, sleeping 30 seconds"
            sleep 30
            next
          rescue Octokit::TooManyRequests => err
            hint, td = rate_limit(gcs)
            puts "Too many GitHub requests for #{actor}, sleeping for #{td} seconds"
            sleep td
            next
          rescue Octokit::InternalServerError => err
            puts "Internal Server Error #{err} for #{actor}, sleeping 60 seconds"
            sleep 60
            next
          rescue Octokit::BadGateway => err
            puts "Bad Gateway #{err} for #{actor}, sleeping 60 seconds"
            sleep 60
            next
          rescue Octokit::ServerError => err
            puts "Server Error #{err} for #{actor}, sleeping 60 seconds"
            sleep 60
            next
          rescue Zlib::BufError, Zlib::DataError, Faraday::ConnectionFailed => err
            puts "Retryable error #{err} for #{actor}, sleeping 10 seconds"
            sleep 10
            next
          rescue => err
            puts "Uups, something bad happened for #{actor}, check `err` variable!"
            STDERR.puts [err.class, err]
            # Write JSON back
            json = JSON.pretty_generate data
            File.write json_file, json
            exit 1
          end
          break
        end
        res
      end # end of thread
      while thrs.length >= n_thrs
        tw = ThreadsWait.new(thrs.to_a)
        t = tw.next_wait
        res = t.value
        res.each { |h| data << h }
        thrs = thrs.delete t
      end
      if index > 0 && index % 1000 == 0
        puts "Backup at #{index}, found #{actors_found}, not found #{actor_not_found} from #{n_users} additional actors"
        # Write JSON back
        json = JSON.pretty_generate data
        File.write json_file, json
      end
    end
    ThreadsWait.all_waits(thrs.to_a) do |thr|
      res = thr.value
      res.each { |h| data << h }
    end
    puts "Found #{actors_found}, not found #{actor_not_found} from #{n_users} additional actors"
  end

  json_not_found = 0
  unks2 = []
  email_affs.each do |email, aff|
    next unless aff == '(Unknown)'
    unless json_emails.key?(email)
      json_not_found += 1
      unks2 << "#{email} #{names[email]}"
    end
  end
  puts "Processed #{n_users} users, enchanced: #{enchanced}, not found in CSV: #{csv_not_found}, unknowns not found in JSON: #{json_not_found}."
  # puts "Unknown emails from JSON not found in CSV (VIM search pattern):"
  # puts email_unks.join '\|'
  # puts "Unknown names from JSON not found in CSV (VIM search pattern):"
  # puts name_unks.join '\|'
  # puts "Unknown emails from CSV not found in JSON"
  # puts unks2.join("\n")
  # File.write 'not_found_in_json.txt', unks2.join("\n")

  # Write JSON back
  json = JSON.pretty_generate data
  File.write json_file, json
end

if ARGV.size < 4
  puts "Missing arguments: json_file csv_file actors_file map_file (github_users.json all_affs.csv actors.txt cncf-config/email-map)"
  exit(1)
end

enchance_json(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
