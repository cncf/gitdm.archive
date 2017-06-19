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
  # https://github.com/settings/tokens --> Persona access tokens
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
  # After processed all 70 repos I had xxxx/5000 points remaining
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
        binding.pry
        sleep td
        retry
      rescue => err2
        puts "Uups, somethis bad happened, check `err2` variable!"
        binding.pry
      end
    end
  end
  binding.pry
end

ghusers(repos, start_date)
