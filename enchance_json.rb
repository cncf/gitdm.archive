require 'pry'
require 'json'
require 'csv'
require 'octokit'
require './comment'
require './email_code'
require './ghapi'
require './merge'

def enchance_json(json_file, csv_file, actors_file)
  # This enables guessing if multiple final affiliations are given
  # Best option is to avoid this, by specifying exact affiliations everywhere!
  guess_by_email = true
  guess_by_name = false

  # Process actors file: it is a "," separated list of GitHub logins
  actors_data = File.read actors_file
  actors_array = actors_data.split(',').map(&:strip)
  actors = {}
  actors_array.each do |actor|
    actors[actor] = true
  end
  actors_array = actors_data = nil

  # Process affiliations found by Python cncf/gitdm saved in CSV
  # "email","name","company","date_to"
  email_affs = {}
  name_affs = {}
  names = {}
  emails = {}
  CSV.foreach(csv_file, headers: true) do |row|
    next if is_comment row
    h = row.to_h
    e = email_encode(h['email'].strip)
    c = h['company'].strip
    n = h['name'].strip
    d = h['date_to'].strip

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
  end

  # Make results as strings
  puts "Checking affiliations by email #{guess_by_email} - this should not generate warnings"
  email_affs.each do |email, comps|
    email_affs[email] = check_affs_list email, comps, guess_by_email
  end

  if guess_by_name
    puts "Checking affiliations by name #{guess_by_name} - this can generate a lot of warnings"
    name_affs.each do |name, comps|
      name_affs[name] = check_affs_list name, comps, guess_by_name
    end
  end
  
  # Parse JSON
  data = JSON.parse File.read json_file

  # Enchance JSON
  n_users = data.count
  enchanced = csv_not_found = 0
  email_unks = []
  name_unks = []
  json_emails = {}
  known_logins = {}
  data.each do |user|
    e = email_encode(user['email'])
    n = user['name']
    l = user['login']
    known_logins[l] = true
    json_emails[e] = true
    v = '?'
    if email_affs.key?(e)
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
    cv = user['affiliation']
    if cv.nil? || cv == '(Unknown)' || cv == 'NotFound' || cv == '?'
      user['affiliation'] = v
    else
      if cv != v && v != '?' && v != '(Unknown)'
        puts "Warning: #{e}: Current '#{cv}', new '#{v}'"
        binding.pry if v.is_a?(Array)
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

  # Actors from out JSON that have no contributions in cncf/devstats
  unknown_logins = {}
  known_logins.keys.each do |login|
    unknown_logins[login] = true unless actors.key?(login)
  end
  puts "We have #{unknown_logins.keys.count} actors in our JSON not listed in #{actors_file}"

  actor_not_found = 0
  actors_found = 0
  if unknown_actors.keys.count > 0
    octokit_init()
    rate_limit()
    puts "We need to process additional actors using GitHub API, type exit-program if you want to exit"
    puts "uacts.join(\"', '\")"
    uacts = unknown_actors.keys
    n_users = uacts.size
    binding.pry
    uacts.each_with_index do |actor, index|
      begin
        rate_limit()
        e = "#{actor}!users.noreply.github.com"
        puts "Asking for #{index}/#{n_users}: GitHub: #{actor}, email: #{e}, found so far: #{actors_found}"
        u = Octokit.user actor
        login = u['login']
        n = u['name']
        u['email'] = e
        u['commits'] = 0
        v = '?'
        if email_affs.key?(e)
          p [e, n, emails[n], names[e], email_affs[e], name_affs[n]]
          actors_found += 1
          v = email_affs[e]
        else
          if name_affs.key?(n)
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
        data << h
        if login != actor
          u2 = u.clone
          u2['login'] = actor
          h2 = u2.to_h
          data << h2
        end
      rescue Octokit::TooManyRequests => err
        td = rate_limit()
        puts "Too many GitHub requests, sleeping for #{td} seconds"
        sleep td
        retry
      rescue Octokit::NotFound => err
        puts "GitHub doesn't know actor #{actor}"
        puts err
      rescue => err
        puts "Uups, somethis bad happened, check `err` variable!"
        binding.pry
      end
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

if ARGV.size < 3
    puts "Missing arguments: JSON_file CSV_file Actors_file (github_users.json all_affs.csv actors.txt)"
  exit(1)
end

enchance_json(ARGV[0], ARGV[1], ARGV[2])
