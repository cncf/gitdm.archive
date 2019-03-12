require 'pry'
require 'octokit'
require 'json'
require 'securerandom'
require 'set'
require 'thwait'
require './email_code'
require './ghapi'

# Ask each repo for commits newer than...
start_date = '2014-01-01'

def running_thread_count
  Thread.list.select {|thread| thread.status == "run"}.count
end

# Environment variable BOOST (2 if not sets) sets the maximum numbe rof threads processing commits on a single repo.
# Not that each repo is already processing in a separate thread, so settiung this to, say 8 will end up with a maximum
# 8 * NCPUs threads created which will cause ruby thread creation errors. Default value `2` should be quite safe.
def commits_since(gcs, repo, sdt)
  days_inc = 365
  days_inc = 30 if repo == 'torvalds/linux'
  now = DateTime.now()
  dt = DateTime.strptime(sdt, '%Y-%m-%d')
  final_comms = []
  thrs = Set[]
  n_thrs = ENV['BOOST'].nil? ? 2 : ENV['BOOST'].to_i
  while dt < now
    edt = dt + days_inc
    dtf = dt.strftime("%Y-%m-%d")
    dtt = edt.strftime("%Y-%m-%d")
    thrs << Thread.new(edt, dtf, dtt) do |edt, dtf, dtt|
      comms = []
      begin
        hint, rem, pts = rate_limit(gcs)
        if edt < now
          puts "#{repo}: #{dtf} - #{dtt}"
          comms = gcs[hint].commits_between(repo, dtf, dtt)
          puts "#{repo}: #{dtf} - #{dtt} --> #{comms.length} commits"
        else
          puts "#{repo}: #{dtf} - now"
          comms = gcs[hint].commits_since(repo, dtf)
          puts "#{repo}: #{dtf} - now --> #{comms.length} commits"
        end
      rescue Octokit::NotFound, Octokit::BadGateway => err
        puts "GitHub doesn't know repo #{repo}: #{err}"
      rescue Octokit::AbuseDetected => err
        puts "Abuse #{err} on #{repo}: #{dtf} - #{dtt}, sleeping 30 seconds"
        sleep 30
        retry
      rescue Octokit::TooManyRequests => err
        hint, td = rate_limit(gcs)
        puts "Too many GitHub requests on #{repo}: #{dtf} - #{dtt}, sleeping for #{td} seconds"
        sleep td
        retry
      rescue Zlib::BufError, Zlib::DataError, Faraday::ConnectionFailed, Faraday::SSLError => err
        puts "Retryable error #{err} on #{repo}: #{dtf} - #{dtt}, sleeping 10 seconds"
        sleep 10
        retry
      rescue Octokit::Conflict => err
        puts "Conflict (probably missing repository): #{err}"
        STDERR.puts [err.class, err]
        comms = false
      rescue => err
        puts "Error: Uups, something bad happened on #{repo}: #{dtf} - #{dtt}, check `err` variable!"
        STDERR.puts [err.class, err]
        comms = false
      end
      comms
    end
    while thrs.length >= n_thrs
      tw = ThreadsWait.new(thrs.to_a)
      t = tw.next_wait
      comms = t.value
      unless comms === false
        final_comms << comms unless comms.length == 0
      end
      thrs = thrs.delete t
    end
    dt = edt
  end
  # puts "Remains #{thrs.length} threads"
  ThreadsWait.all_waits(thrs.to_a) do |thr|
    comms = thr.value
    unless comms === false
      final_comms << comms unless comms.length == 0
    end
  end
  final_comms.flatten
end

# args[0]: 1st arg is: 'r' - force repos metadata fetch, 'c' - force commits fetch, 'u' force users fetch, 'n' fetch commits never than newest from cache
def ghusers(start_date, args)
  # List of repositories to retrieve commits from (and get their basic data): from repos.txt file
  str = File.read 'repos.txt'
  repos_raw = str.strip.split(",")
  repos = []
  repos_raw.each { |repo| repos << repo.strip }
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
  thrs = Set[]
  n_thrs = ENV['NCPUS'].nil? ? Etc.nprocessors : ENV['NCPUS'].to_i
  repos.each_with_index do |repo_name, repo_index|
    thrs << Thread.new do
      h = nil
      begin
        puts "Processing repository data #{repo_index + 1}/#{n_repos} #{repo_name}"
        fn = 'ghusers/' + repo_name.gsub('/', '__')
        ofn = force_repo ? SecureRandom.hex(80) : fn
        f = File.read(ofn)
        puts "Got repository #{repo_name} JSON from saved file"
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
            #puts "#{rpts} calls remain before next rate check"
          end
          repo = gcs[hint].repo repo_name
          h = repo.to_h
          json = email_encode(JSON.pretty_generate(h))
          File.write fn, json
        rescue Octokit::NotFound, Octokit::BadGateway => err2
          puts "GitHub doesn't know repo #{repo_name}: #{err2}"
          puts err2
        rescue Octokit::AbuseDetected => err2
          puts "Abuse #{err2} on #{repo_name}, sleeping 30 seconds"
          sleep 30
          retry
        rescue Octokit::TooManyRequests => err2
          hint, td = rate_limit(gcs)
          puts "Too many GitHub requests on #{repo_name}, sleeping for #{td} seconds"
          sleep td
          retry
        rescue Zlib::BufError, Zlib::DataError, Faraday::ConnectionFailed, Faraday::SSLError => err2
          puts "Retryable error #{err2} on #{repo_name}, sleeping 10 seconds"
          sleep 10
          retry
        rescue => err2
          puts "Error: Uups, something bad happened on #{repo_name}, check `err2` variable!"
          STDERR.puts [err2.class, err2]
          h = false
        end
      end
      h
    end
    while thrs.length >= n_thrs
      tw = ThreadsWait.new(thrs.to_a)
      t = tw.next_wait
      h = t.value
      hs << h unless h.nil? || h === false
      thrs = thrs.delete t
    end
  end
  ThreadsWait.all_waits(thrs.to_a) do |thr|
    h = thr.value
    hs << h unless h.nil? || h === false
  end

  # Process each repository's commits
  comms = []
  processed = {}
  processed_mutex = Mutex.new
  n_repos = hs.count
  rpts = 0
  thrs = Set[]
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
        unless already_processed
          fn = 'ghusers/' + repo_name.gsub('/', '__') + '__commits'
          ofn = force_commits ? SecureRandom.hex(80) : fn
          f = File.read(ofn)
          puts "Got #{repo_name} commits JSON from saved file"
          ok_json = true
          begin
            comm = JSON.parse f
          rescue => e
            puts "Broken JSON: #{ofn}"
            ok_json = false
          end
          if ok_json && new_commits
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
            puts "Getting #{repo_index + 1}/#{n_repos} new commits for #{repo_name} from #{maxdt}, threads: #{running_thread_count()}"
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
            puts "Got #{nc} new commits for #{repo_name} #{repo_index + 1}/#{n_repos}"
            json = email_encode(JSON.pretty_generate(comm))
            File.write fn, json
          end
          processed_mutex.synchronize { processed[repo_name] = true }
        end
      rescue Errno::ENOENT => err1
        from_date = start_date
        from_date = '2012-07-01' if repo_name == 'torvalds/linux'
        puts "No previously saved #{fn}, getting commits from GitHub from #{from_date}, threads: #{running_thread_count()}" unless force_commits
        comm = commits_since(gcs, repo_name, from_date)
        h = comm.map(&:to_h)
        puts "Got #{h.count} commits for #{repo_name}"
        json = email_encode(JSON.pretty_generate(h))
        File.write fn, json
        processed_mutex.synchronize { processed[repo_name] = true }
      end
      comm
    end
    while thrs.length >= n_thrs
      tw = ThreadsWait.new(thrs.to_a)
      t = tw.next_wait
      comm = t.value
      comms << comm unless comm.nil?
      thrs = thrs.delete t
    end
  end
  ThreadsWait.all_waits(thrs.to_a) do |thr|
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
      sha = nil
      begin
        sha = comm['commit']['tree']['sha'] || comm[:commit][:tree][:sha]
      rescue => e
        puts "Commit without SHA: #{comm['commit'] || comm[:commit]}"
      end
      h.each do |email, login|
        next unless email.include?('!')
        next if email == nil || email == ''
        next if skip_logins.include?(login)
        if email2github.key?(email)
          if email2github[email][0] != login
            puts "Too bad, we already have email2github[#{email}] = #{email2github[email][0]}, and now new value: #{login}"
          else
            email2github[email][1] << sha
          end
        else
          email2github[email] = [login, Set[sha]]
        end
      end
    end
  end
  email2github.each do |email, data|
    email2github[email] = [data[0], data[1].length]
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
  thrs = Set[]
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
          #puts "#{rpts} calls remain before next rate check"
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
      rescue Octokit::NotFound, Octokit::BadGateway => err2
        puts "GitHub doesn't know actor #{usr[1]}: #{err2}"
        puts err2
      rescue Octokit::AbuseDetected => err2
        puts "Abuse #{err2} for #{usr[1]}, sleeping 30 seconds"
        sleep 30
        retry
      rescue Octokit::TooManyRequests => err2
        hint, td = rate_limit(gcs)
        puts "Too many GitHub requests for #{usr[1]}, sleeping for #{td} seconds"
        sleep td
        retry
      rescue Zlib::BufError, Zlib::DataError, Faraday::ConnectionFailed, Faraday::SSLError => err2
        puts "Retryable error #{err2} for #{usr[1]}, sleeping 10 seconds"
        sleep 10
        retry
      rescue => err2
        puts "Error: Uups, something bad happened for #{usr[1]}, check `err2` variable!"
        STDERR.puts [err2.class, err2]
        h = false
      end
      h
    end
    while thrs.length >= n_thrs
      tw = ThreadsWait.new(thrs.to_a)
      t = tw.next_wait
      h = t.value
      final << h unless h.nil? || h === false
      thrs = thrs.delete t
    end
  end
  ThreadsWait.all_waits(thrs.to_a) do |thr|
    h = thr.value
    final << h unless h.nil? || h === false
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
end

ghusers(start_date, ARGV)
