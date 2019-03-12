require 'pry'
require 'json'
require 'octokit'
require './comment'
require './email_code'
require './ghapi'

# Not used by the default workflow
def add_actors(json_file, actors_file)
  # Process actors file: it is a "," separated list of GitHub logins
  actors_data = File.read actors_file
  actors_array = actors_data.split(',').map(&:strip)
  actors = {}
  actors_array.each do |actor|
    actors[actor] = true
  end
  actors_array = actors_data = nil

  # Parse JSON
  data = JSON.parse File.read json_file

  # Known logins
  known_logins = {}
  data.each_with_index do |user, idx|
    l = user['login'].strip
    known_logins[l] = true
  end

  # Skip logins config
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

  # Lookup those actors
  jdata = []
  if unknown_actors.keys.count > 0
    gcs = octokit_init()
    hint = rate_limit(gcs)[0]
    puts "We need to process additional actors using GitHub API, type exit-program if you want to exit"
    puts "uacts.join(\"', '\")"
    uacts = unknown_actors.keys
    #uacts = uacts[0..10]
    n_users = uacts.length
    binding.pry
    rpts = 0
    uacts.each_with_index do |actor, index|
      begin
        if rpts <= 0
          hint, rem, pts = rate_limit(gcs)
          rpts = pts / 10
          puts "Allowing #{rpts} calls without checking rate"
        else
          rpts -= 1
          puts "#{rpts} calls remain before next rate check"
        end
        e = "#{actor}!users.noreply.github.com"
        puts "#{gcs[hint].user[:login]}: asking for #{index}/#{n_users}: GitHub: #{actor}, email: #{e}"
        u = gcs[hint].user actor
        login = u['login']
        n = u['name']
        u['email'] = e
        u['commits'] = 0
        puts "Got name: #{u[:name] || u['name']}, login: #{u[:login] || u['login']}"
        h = u.to_h
        jdata << h
      rescue Octokit::TooManyRequests => err
        hint, td = rate_limit(gcs)
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
  end
  # Write added actors JSON
  pretty = JSON.pretty_generate jdata
  File.write 'new_actors.json', pretty
end

if ARGV.size < 2
  puts "Missing arguments: json_file actors_file (github_users.json actors.txt)"
  exit(1)
end

add_actors(ARGV[0], ARGV[1])
