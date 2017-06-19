require 'pry'
require 'octokit'
require 'json'

# Ask each repo for commits newer than...
start_date = '2014-01-01'

# List of repositories to retrieve commits from (and get their basic data)
repos = [
  'kubernetes/test-infra',
  'kubernetes/kubernetes',
  'kubernetes/kubernetes.github.io',
  'kubernetes/contrib',
  'kubernetes/helm',
  'kubernetes/kops',
  'kubernetes/community',
  'kubernetes/heapster',
  'kubernetes/dashboard',
  'kubernetes/minikube',
  'kubernetes/charts',
  'kubernetes/kube-state-metrics',
  'kubernetes/kubernetes-anywhere',
  'kubernetes/ingress',
  'kubernetes/release',
  'kubernetes/gengo',
  'kubernetes/autoscaler',
  'kubernetes/dns',
  'kubernetes/sample-apiserver',
  'kubernetes/apiserver',
  'kubernetes/kube-aggregator',
  'kubernetes/client-go',
  'kubernetes/node-problem-detector',
  'kubernetes/perf-tests',
  'kubernetes/apimachinery',
  'kubernetes/frakti',
  'kubernetes/features',
  'kubernetes/repo-infra',
  'kubernetes/kube-deploy',
  'kubernetes/examples',
  'kubernetes/git-sync',
  'kubernetes/k8s.io',
  'kubernetes/kubernetes-bootcamp',
  'kubernetes/kubectl',
  'kubernetes/metrics',
  'kubernetes/md-check',
  'kubernetes/kubernetes-template-project',
  'kubernetes/kubernetes-docs-cn',
  'kubernetes/kube-ui',
  'kubernetes/kubeadm',
  'kubernetes-incubator/kompose',
  'kubernetes-incubator/external-storage',
  'kubernetes-incubator/cri-tools',
  'kubernetes-incubator/kube-aws',
  'kubernetes-incubator/external-dns',
  'kubernetes-incubator/bootkube',
  'kubernetes-incubator/service-catalog',
  'kubernetes-incubator/kargo',
  'kubernetes-incubator/cri-o',
  'kubernetes-incubator/cri-containerd',
  'kubernetes-incubator/apiserver-builder',
  'kubernetes-incubator/ip-masq-agent',
  'kubernetes-incubator/client-python',
  'kubernetes-incubator/cluster-capacity',
  'kubernetes-incubator/reference-docs',
  'kubernetes-incubator/kube-mesos-framework',
  'kubernetes-incubator/rktlet',
  'kubernetes-incubator/spartakus',
  'kubernetes-incubator/cluster-proportional-autoscaler',
  'kubernetes-incubator/nfs-provisioner',
  'kubernetes-incubator/node-feature-discovery',
  'kubernetes-incubator/application-images',
  'kubernetes-client/java',
  'kubernetes-client/gen',
  'kubernetes-client/python-base',
  'kubernetes-client/csharp',
  'kubernetes-client/ruby',
  'kubernetes-client/javascript',
  'kubernetes-client/go-base',
  'kubernetes-client/go'
]

# It tries to call GitHub only twice per repo (general repo data & commits), then saves data JSON to files
# If file is saved (2 per repo) - it is read isnstead of quering GitHub
def rate_limit()
  rl = Octokit.rate_limit
  puts "Your rate limit is: limit=#{rl.limit}, remaining=#{rl.remaining}, resets_at=#{rl.resets_at}, resets_in=#{rl.resets_in}"
  (rl.resets_at - Time.now).to_i + 1
end

def ghusers(repos, start_date)
  # Auto paginate results, this uses maximum page size 100 internally and calls API # of results / 100 times.
  Octokit.auto_paginate = true

  # Login with standard OAuth token
  # https://github.com/settings/tokens --> Personal access tokens
  client = Octokit::Client.new access_token: File.read('/etc/github/oauth').strip
  user = client.user
  user.login

  # Increase rate limit from 60 to 5000
  # You will need Your own client_id & client_secret
  # See: https://github.com/settings/ --> OAuth application
  Octokit.client_id = File.read('/etc/github/client_id').strip
  Octokit.client_secret = File.read('/etc/github/client_secret').strip
  # user = Octokit.user 'some_github_username'

  rate_limit()
  puts "Type exit-program if You want to exit"
  # This is to ensure You want to continue, it displays Your limit, should be close to 5000
  # If not type 'exit-program' if Yes type 'quit' (to quit debugger & continue)
  binding.pry

  # Process repositories general info
  hs = []
  repos.each do |repo_name|
    begin
      puts "Processing #{repo_name}"
      fn = 'ghusers/' + repo_name.gsub('/', '__')
      f = File.read(fn)
      puts "Got repository JSON from saved file"
      h = JSON.parse f
      hs << h
    rescue Errno::ENOENT => err1
      begin
        puts "No previously saved #{fn}, getting repo from GitHub"
        rate_limit()
        repo = Octokit.repo repo_name
        h = repo.to_h
        json = JSON.pretty_generate h
        File.write fn, json
        hs << h
      rescue Octokit::TooManyRequests => err2
        td = rate_limit()
        puts "Too many GitHub requests, sleeping for #{td} seconds"
        sleep td
        retry
      rescue => err2
        puts "Uups, somethis bad happened, check `err2` variable!"
        binding.pry
      end
    end
  end

  # Process each repository's commits
  # 56k commits took 162/5000 points
  # After processed all 70 repos I had ~3900/5000 points remaining
  comms = []
  hs.each do |repo|
    begin
      repo_name = repo['full_name'] || repo[:full_name]
      puts "Getting commits from #{repo_name}"
      fn = 'ghusers/' + repo_name.gsub('/', '__') + '__commits'
      f = File.read(fn)
      puts "Got commits JSON from saved file"
      comm = JSON.parse f
      comms << comm
    rescue Errno::ENOENT => err1
      begin
        puts "No previously saved #{fn}, getting commits from GitHub"
        rate_limit()
        comm = Octokit.commits_since(repo_name, start_date)
        h = comm.map(&:to_h)
        puts "Got #{h.count} commits"
        json = JSON.pretty_generate h
        File.write fn, json
        comms << comm
      rescue Octokit::TooManyRequests => err2
        td = rate_limit()
        puts "Too many GitHub requests, sleeping for #{td} seconds"
        sleep td
        retry
      rescue => err2
        puts "Uups, somethis bad happened, check `err2` variable!"
        binding.pry
      end
    end
  end

  # Now analysis of different authors
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
      committer['login'] = comm['committer']['login'] || comm[:committer][:login]
      author['login'] = comm['author']['login'] || comm[:author][:login]

      h = {}
      h[author['email']] = author['login']
      h[committer['email']] = committer['login']
      h.each do |email, login|
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
  puts "Processed #{n_processed}/#{n_commits} commits"
  users = []
  email2github.each do |email, data|
    users << [email, data[0], data[1]]
  end
  users = users.sort_by { |u| -u[2] }

  # Process distinct GitHub users
  # 1 point/user --> took 3100 points
  final = []
  n_users = users.count
  data = {}
  begin
    json = JSON.parse File.read 'github_users.json'
    json.each do |usr|
      data[usr['email']] = usr
    end
  rescue Errno::ENOENT => e
    puts "No JSON saved yet, generating new one"
  end

  users.each_with_index do |usr, index|
    begin
      rate_limit()
      puts "Asking for #{index}/#{n_users}: GitHub: #{usr[1]}, email: #{usr[0]}, commits: #{usr[2]}"
      u = nil
      if data.key?(usr[0])
        # Check saved JSON by email (JSON unique)
        u = data[usr[0]]
      else
        # Ask GitHub by login (github unique)
        u = Octokit.user usr[1]
      end
      u['email'] = usr[0]
      u['commits'] = usr[2]
      puts "Got name: #{u[:name] || u['name']}, login: #{u[:login] || u['login']}"
      h = u.to_h
      final << h
    rescue Octokit::TooManyRequests => err2
      td = rate_limit()
      puts "Too many GitHub requests, sleeping for #{td} seconds"
      sleep td
      retry
    rescue => err2
      puts "Uups, somethis bad happened, check `err2` variable!"
      binding.pry
    end
  end
  json = JSON.pretty_generate final
  File.write 'github_users.json', json
end

ghusers(repos, start_date)
