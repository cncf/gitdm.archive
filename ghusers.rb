require 'pry'
require 'octokit'
require 'json'
require 'securerandom'
require './email_code'
require './ghapi'

# Ask each repo for commits newer than...
start_date = '2014-01-01'

def commits_since(gcs, repo, sdt)
  days_inc = 365
  days_inc = 30 if repo == 'torvalds/linux'
  now = DateTime.now()
  dt = DateTime.strptime(sdt, '%Y-%m-%d')
  final_comms = []
  thrs = []
  n_thrs = Etc.nprocessors
  while dt < now
    edt = dt + days_inc
    dtf = dt.strftime("%Y-%m-%d")
    dtt = edt.strftime("%Y-%m-%d")
    thrs << Thread.new(edt, dtf, dtt) do |edt, dtf, dtt|
      comms = []
      begin
        hint, rem, pts = rate_limit(gcs, -1, true)
        if edt < now
          puts "#{repo}: #{dtf} - #{dtt}"
          comms = gcs[hint].commits_between(repo, dtf, dtt)
        else
          puts "#{repo}: #{dtf} - now"
          comms = gcs[hint].commits_since(repo, dtf)
        end
      rescue Octokit::TooManyRequests => err2
        hint, td = rate_limit(gcs)
        puts "Too many GitHub requests, sleeping for #{td} seconds"
        sleep td
        retry
      rescue => err2
        puts "Uups, somethis bad happened, check `err2` variable!"
        STDERR.puts err2
      end
      comms
    end
    while thrs.length >= n_thrs
      comms = thrs.first.value
      final_comms << comms if comms.length > 0
      thrs = thrs[1..-1]
    end
    dt = edt
  end
  # puts "Remains #{thrs.length} threads"
  thrs.each do |thr|
    comms = thr.value
    final_comms << comms if comms.length > 0
  end
  final_comms.flatten
end

# args[0]: 1st arg is: 'r' - force repos metadata fetch, 'c' - force commits fetch, 'u' force users fetch, 'n' fetch commits never than newest from cache
def ghusers(start_date, args)
  # List of repositories to retrieve commits from (and get their basic data): from repos.txt file
  str = File.read 'repos.txt'
  repos = str.strip.split(",\n  ")
  File.write 'repos.txt', '  ' + repos.reject.sort.join(",\n  ") + "\n"

  # Args processing
  force_repo = false
  force_commits = false
  force_users = false
  new_commits = false
  force_repo = true if args.length > 0 && args[0].downcase.include?('r')
  force_commits = true if args.length > 0 && args[0].downcase.include?('c')
  force_users = true if args.length > 0 && args[0].downcase.include?('u')
  new_commits = true if args.length > 0 && args[0].downcase.include?('n')

  gcs = octokit_init()

  # Process repositories general info
  hs = []
  n_repos = repos.count

  hint = rate_limit(gcs)[0]
  rpts = 0
  puts "Type exit-program if You want to exit"
  # This is to ensure You want to continue, it displays Your limit, should be close to 5000
  # If not type 'exit-program' if Yes type 'quit' (to quit debugger & continue)
  binding.pry
  thrs = []
  n_thrs = Etc.nprocessors
  repos.each_with_index do |repo_name, repo_index|
    thrs << Thread.new do
      h = nil
      begin
        puts "Processing #{repo_index + 1}/#{n_repos} #{repo_name}"
        fn = 'ghusers/' + repo_name.gsub('/', '__')
        ofn = force_repo ? SecureRandom.hex(80) : fn
        f = File.read(ofn)
        puts "Got repository JSON from saved file"
        h = JSON.parse f
      rescue Errno::ENOENT => err1
        begin
          puts "No previously saved #{fn}, getting repo from GitHub" unless force_repo
          if rpts <= 0
            hint, rem, pts = rate_limit(gcs)
            rpts = pts / 10
            puts "Allowing #{rpts} calls without checking rate"
          else
            rpts -= 1
            puts "#{rpts} calls remain before next rate check"
          end
          repo = gcs[hint].repo repo_name
          h = repo.to_h
          json = email_encode(JSON.pretty_generate(h))
          File.write fn, json
        rescue Octokit::TooManyRequests => err2
          hint, td = rate_limit(gcs)
          puts "Too many GitHub requests, sleeping for #{td} seconds"
          sleep td
          retry
        rescue => err2
          puts "Uups, somethis bad happened, check `err2` variable!"
          STDERR.puts err2
        end
      end
      h
    end
    while thrs.length >= n_thrs
      h = thrs.first.value
      hs << h unless h.nil?
      thrs = thrs[1..-1]
    end
  end
  thrs.each do |thr|
    h = thr.value
    hs << h unless h.nil?
  end

  # Process each repository's commits
  # 56k commits took 162/5000 points
  # After processed all 70 repos I had ~3900/5000 points remaining
  comms = []
  processed = {}
  processed_mutex = Mutex.new
  n_repos = hs.count
  rpts = 0
  thrs = []
  hs.each_with_index do |repo, repo_index|
    thrs << Thread.new do
      begin
        comm = nil
        repo_name = repo['full_name'] || repo[:full_name]
        puts "Getting commits from #{repo_index + 1}/#{n_repos} #{repo_name}"
        already_processed = false
        processed_mutex.synchronize do
          if processed.key?(repo_name)
            puts "#{repo_name} was already processed"
            already_processed = true
          end
        end
        return nil if already_processed
        fn = 'ghusers/' + repo_name.gsub('/', '__') + '__commits'
        ofn = force_commits ? SecureRandom.hex(80) : fn
        f = File.read(ofn)
        puts "Got commits JSON from saved file"
        comm = JSON.parse f
        if new_commits
          author_maxdt = comm.map { |c| (c.key?('commit') && c['commit'].key?('author') && c['commit']['author'].key?('date')) ? c['commit']['author']['date'] : start_date }.max
          committer_maxdt = comm.map { |c| (c.key?('commit') && c['commit'].key?('author') && c['commit']['author'].key?('date')) ? c['commit']['author']['date'] : start_date }.max
          maxdt = [author_maxdt, committer_maxdt].max
          if maxdt.nil?
            maxdt = start_date
          else
            maxdt = maxdt[0...10] if maxdt.length >= 10
          end
          shas = {}
          comm.each { |c| shas[c[:sha] || c['sha']] = true }
          # hint, rem, pts = rate_limit(gcs)
          puts "Getting new commits for #{repo_name} from #{maxdt}"
          ocomm = commits_since(gcs, repo_name, maxdt)
          h = ocomm.map(&:to_h)
          nc = 0
          h.each do |c|
            unless shas.key?(c[:sha])
              nc += 1
              comm << c
              # else: puts "#{repo_name}:#{c[:sha]} already processed"
            end
          end
          puts "Got #{nc} new commits"
          json = email_encode(JSON.pretty_generate(comm))
          File.write fn, json
        end
        comms << comm
        processed_mutex.synchronize { processed[repo_name] = true }
      rescue Errno::ENOENT => err1
        begin
          from_date = start_date
          from_date = '2012-07-01' if repo_name == 'torvalds/linux'
          puts "No previously saved #{fn}, getting commits from GitHub from #{from_date}" unless force_commits
          # hint, rem, pts = rate_limit(gcs)
          comm = commits_since(gcs, repo_name, from_date)
          h = comm.map(&:to_h)
          puts "Got #{h.count} commits"
          json = email_encode(JSON.pretty_generate(h))
          File.write fn, json
          comms << comm
          processed_mutex.synchronize { processed[repo_name] = true }
        rescue Octokit::TooManyRequests => err2
          hint, td = rate_limit(gcs)
          puts "Too many GitHub requests, sleeping for #{td} seconds"
          sleep td
          retry
        rescue => err2
          puts "Uups, somethis bad happened, check `err2` variable!"
          STDERR.puts err2
        end
      end
      comm
    end
    while thrs.length >= n_thrs
      comm = thrs.first.value
      comms << comm unless comm.nil?
      thrs = thrs[1..-1]
    end
  end
  thrs.each do |thr|
    comm = thr.value
    comms << comm unless comm.nil?
  end
  puts "Processed #{processed.keys.length} repos"

  hs = nil
  # Now analysis of different authors
  puts "Commits analysis..."
  skip_logins = [
    'greenkeeper[bot]', 'web-flow', 'k8s-merge-robot', 'codecov[bot]', 'stale[bot]',
    'googlebot', 'coveralls', 'rktbot', 'Docker Library Bot',
    '', nil
  ]
  email2github = {}
  n_commits = 0
  n_processed = 0
  comms.each do |repo_commits|
    repo_commits.each do |comm|
      n_commits += 1
      next unless comm['committer'] && comm['author']
      n_processed += 1
      author = comm['commit']['author'] || comm[:commit][:author]
      committer = comm['commit']['committer'] || comm[:commit][:committer]
      committer['login'] = (comm['committer'] && comm['committer']['login']) || (comm[:committer] && comm[:committer][:login])
      author['login'] = (comm['author'] && comm['author']['login']) || (comm[:author] && comm[:author][:login])
      h = {}
      h[email_encode(author['email'])] = author['login']
      h[email_encode(committer['email'])] = committer['login']
      h.each do |email, login|
        next unless email.include?('!')
        next if email == nil || email == ''
        next if skip_logins.include?(login)
        if email2github.key?(email)
          if email2github[email][0] != login
            puts "Too bad, we already have email2github[#{email}] = #{email2github[email][0]}, and now new value: #{login}"
          else
            email2github[email][1] += 1
          end
        else
          email2github[email] = [login, 1]
        end
      end
    end
  end
  puts "Processed #{processed.keys.length} repos"
  puts "Processed #{n_processed}/#{n_commits} commits"

  comms = nil
  users = []
  email2github.each do |email, data|
    users << [email, data[0], data[1]]
  end
  users = users.sort_by { |u| -u[2] }
  email2github = nil

  # Process distinct GitHub users
  # 1 point/user --> took 3100 points
  # I had 3896 points left after getting all repos metadata & commits
  final = []
  n_users = users.count
  puts "#{n_users} users"
  data = {}
  begin
    ofn = force_users ? SecureRandom.hex(80) : 'github_users.json'
    json = JSON.parse File.read ofn
    json.each do |usr|
      data[usr['email']] = usr
    end
  rescue Errno::ENOENT => e
    puts "No JSON saved yet, generating new one" unless force_users
  end

  rpts = 0
  thrs = []
  users.each_with_index do |usr, index|
    thrs << Thread.new do
      h = nil
      begin
        if rpts <= 0
          hint, rem, pts = rate_limit(gcs)
          rpts = pts / 10
          puts "Allowing #{rpts} calls without checking rate"
        else
          rpts -= 1
          puts "#{rpts} calls remain before next rate check"
        end
        puts "Asking for #{index}/#{n_users}: GitHub: #{usr[1]}, email: #{usr[0]}, commits: #{usr[2]}"
        u = nil
        if data.key?(usr[0])
          # Check saved JSON by email (JSON unique)
          u = data[usr[0]]
        else
          # Ask GitHub by login (github unique)
          u = gcs[hint].user usr[1]
        end
        u['email'] = usr[0]
        u['commits'] = usr[2]
        puts "Got name: #{u[:name] || u['name']}, login: #{u[:login] || u['login']}"
        h = u.to_h
      rescue Octokit::TooManyRequests => err2
        hint, td = rate_limit(gcs)
        puts "Too many GitHub requests, sleeping for #{td} seconds"
        sleep td
        retry
      rescue => err2
        puts "Uups, somethig bad happened, check `err2` variable!"
        STDERR.puts err2
      end
      h
    end
    while thrs.length >= n_thrs
      h = thrs.first.value
      final << h unless h.nil?
      thrs = thrs[1..-1]
    end
  end
  thrs.each do |thr|
    h = thr.value
    final << h unless h.nil?
  end

  # Encode emails in JSON
  final.each do |user|
    e = user['email']
    next if e.nil? || e == ''
    user['email'] = email_encode(e)
  end
  json = email_encode(JSON.pretty_generate(final))
  File.write 'github_users.json', json
  puts "All done: please note that new JSON has *only* data for committers"
  # I had 908/5000 points left when running < 1 hour
end

ghusers(start_date, ARGV)
