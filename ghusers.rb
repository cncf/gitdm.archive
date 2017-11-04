require 'pry'
require 'octokit'
require 'json'
require 'securerandom'
require './email_code'

# Ask each repo for commits newer than...
start_date = '2014-01-01'

# List of repositories to retrieve commits from (and get their basic data)
repos = [
  'prometheus',
  'prometheus/alertmanager',
  'prometheus/blackbox_exporter',
  'prometheus/build_tools',
  'prometheus/busybox',
  'prometheus/client_golang',
  'prometheus/client_java',
  'prometheus/client_model',
  'prometheus/client_python',
  'prometheus/client_ruby',
  'prometheus/cloudwatch_exporter',
  'prometheus/collectd_exporter',
  'prometheus/common',
  'prometheus/consul_exporter',
  'prometheus/demo',
  'prometheus/distro-pkgs',
  'prometheus/docs',
  'prometheus/golang-builder',
  'prometheus/graphite_exporter',
  'prometheus/haproxy_exporter',
  'prometheus/host_exporter',
  'prometheus/hystrix',
  'prometheus/influxdb_exporter',
  'prometheus/jmx_exporter',
  'prometheus/log',
  'prometheus/memcached_exporter',
  'prometheus/mesos_exporter',
  'prometheus/migrate',
  'prometheus/mysqld_exporter',
  'prometheus/nagios_plugins',
  'prometheus/node_exporter',
  'prometheus/procfs',
  'prometheus/prom2json',
  'prometheus/prombench',
  'prometheus/promdash',
  'prometheus/prometheus',
  'prometheus/prometheus_api_client_ruby',
  'prometheus/prometheus_cli',
  'prometheus/prometheus.github.io',
  'prometheus/promu',
  'prometheus/pushgateway',
  'prometheus/snmp_exporter',
  'prometheus/statsd_bridge',
  'prometheus/statsd_exporter',
  'prometheus/tsdb',
  'prometheus/utils',
  'GoogleCloudPlatform/kubernetes',
  'kubernetes',
  'kubernetes/api',
  'kubernetes/apiextensions-apiserver',
  'kubernetes/apimachinery',
  'kubernetes/apiserver',
  'kubernetes/application-dm-templates',
  'kubernetes/application-images',
  'kubernetes/autoscaler',
  'kubernetes/charts',
  'kubernetes-client',
  'kubernetes-client/community',
  'kubernetes-client/csharp',
  'kubernetes-client/gen',
  'kubernetes-client/go',
  'kubernetes/client-go',
  'kubernetes-client/go-base',
  'kubernetes-client/java',
  'kubernetes-client/javascript',
  'kubernetes-client/python-base',
  'kubernetes-client/ruby',
  'kubernetes-client/typescript',
  'kubernetes/cluster-proportional-autoscaler',
  'kubernetes/cluster-registry',
  'kubernetes/code-generator',
  'kubernetes/common',
  'kubernetes/community',
  'kubernetes/console',
  'kubernetes/contrib',
  'kubernetes/dashboard',
  'kubernetes/demos-and-tutorials',
  'kubernetes/deployment-manager',
  'kubernetes/dns',
  'kubernetes/examples',
  'kubernetes/features',
  'kubernetes/federation',
  'kubernetes/frakti',
  'kubernetes/gengo',
  'kubernetes/git-sync',
  'kubernetes/heapster',
  'kubernetes/helm',
  'kubernetes-helm/chartmuseum',
  'kubernetes-helm/community',
  'kubernetes-helm/monocular',
  'kubernetes-helm/rudder-federation',
  'kubernetes/horizontal-self-scaler',
  'kubernetes-incubator/apiserver-builder',
  'kubernetes-incubator/application-images',
  'kubernetes-incubator/auger',
  'kubernetes-incubator/bootkube',
  'kubernetes-incubator/client-python',
  'kubernetes-incubator/cluster-capacity',
  'kubernetes-incubator/cluster-proportional-autoscaler',
  'kubernetes-incubator/cluster-proportional-vertical-autoscaler',
  'kubernetes-incubator/cri-containerd',
  'kubernetes-incubator/cri-o',
  'kubernetes-incubator/cri-tools',
  'kubernetes-incubator/custom-metrics-apiserver',
  'kubernetes-incubator/descheduler',
  'kubernetes-incubator/external-dns',
  'kubernetes-incubator/external-storage',
  'kubernetes-incubator/ip-masq-agent',
  'kubernetes-incubator/kargo',
  'kubernetes-incubator/kompose',
  'kubernetes-incubator/kube2consul',
  'kubernetes-incubator/kube-arbitrator',
  'kubernetes-incubator/kube-aws',
  'kubernetes-incubator/kube-mesos-framework',
  'kubernetes-incubator/kubespray',
  'kubernetes-incubator/metrics-server',
  'kubernetes-incubator/nfs-provisioner',
  'kubernetes-incubator/node-feature-discovery',
  'kubernetes-incubator/ocid',
  'kubernetes-incubator/reference-docs',
  'kubernetes-incubator/rescheduler',
  'kubernetes-incubator/rktlet',
  'kubernetes-incubator/service-catalog',
  'kubernetes-incubator/spartakus',
  'kubernetes/ingress',
  'kubernetes/ingress-gce',
  'kubernetes/ingress-nginx',
  'kubernetes/k8s.io',
  'kubernetes/kompose',
  'kubernetes/kops',
  'kubernetes/kube2consul',
  'kubernetes/kubeadm',
  'kubernetes/kube-aggregator',
  'kubernetes/kubectl',
  'kubernetes/kubedash',
  'kubernetes/kube-deploy',
  'kubernetes/kube-openapi',
  'kubernetes/kubernetes',
  'kubernetes/kubernetes-anywhere',
  'kubernetes/kubernetes-bootcamp',
  'kubernetes/kubernetes-console',
  'kubernetes/kubernetes-docs-cn',
  'kubernetes/kubernetes.github.io',
  'kubernetes/kubernetes-template-project',
  'kubernetes/kube-state-metrics',
  'kubernetes/kube-ui',
  'kubernetes/md-check',
  'kubernetes/md-format',
  'kubernetes/metrics',
  'kubernetes/minikube',
  'kubernetes/node-problem-detector',
  'kubernetes/ocid',
  'kubernetes/perf-tests',
  'kubernetes/pr-bot',
  'kubernetes/release',
  'kubernetes/repo-infra',
  'kubernetes/rktlet',
  'kubernetes/sample-apiserver',
  'kubernetes/sample-controller',
  'kubernetes/sig-release',
  'kubernetes/steering',
  'kubernetes/test-infra',
  'kubernetes/utils',
  'kubernetes/website'
]

# It tries to call GitHub only twice per repo (general repo data & commits), then saves data JSON to files
# If file is saved (2 per repo) - it is read isnstead of quering GitHub
def rate_limit()
  rl = Octokit.rate_limit
  puts "Your rate limit is: limit=#{rl.limit}, remaining=#{rl.remaining}, resets_at=#{rl.resets_at}, resets_in=#{rl.resets_in}"
  (rl.resets_at - Time.now).to_i + 1
end

# args[0]: 1st arg is: 'r' - force repos metadata fetch, 'c' - force commits fetch, 'u' force users fetch
def ghusers(repos, start_date, args)

  # Args processing
  force_repo = false
  force_commits = false
  force_users = false
  force_repo = true if args.length > 0 && args[0].downcase.include?('r')
  force_commits = true if args.length > 0 && args[0].downcase.include?('c')
  force_users = true if args.length > 0 && args[0].downcase.include?('u')
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
  n_repos = repos.count
  repos.each_with_index do |repo_name, repo_index|
    begin
      puts "Processing #{repo_index + 1}/#{n_repos} #{repo_name}"
      fn = 'ghusers/' + repo_name.gsub('/', '__')
      ofn = force_repo ? SecureRandom.hex(80) : fn
      f = File.read(ofn)
      puts "Got repository JSON from saved file"
      h = JSON.parse f
      hs << h
    rescue Errno::ENOENT => err1
      begin
        puts "No previously saved #{fn}, getting repo from GitHub" unless force_repo
        rate_limit()
        repo = Octokit.repo repo_name
        h = repo.to_h
        json = email_encode(JSON.pretty_generate(h))
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
  n_repos = hs.count
  hs.each_with_index do |repo, repo_index|
    begin
      repo_name = repo['full_name'] || repo[:full_name]
      puts "Getting commits from #{repo_index + 1}/#{n_repos} #{repo_name}"
      fn = 'ghusers/' + repo_name.gsub('/', '__') + '__commits'
      ofn = force_commits ? SecureRandom.hex(80) : fn
      f = File.read(ofn)
      puts "Got commits JSON from saved file"
      comm = JSON.parse f
      comms << comm
    rescue Errno::ENOENT => err1
      begin
        puts "No previously saved #{fn}, getting commits from GitHub" unless force_commits
        rate_limit()
        comm = Octokit.commits_since(repo_name, start_date)
        h = comm.map(&:to_h)
        puts "Got #{h.count} commits"
        json = email_encode(JSON.pretty_generate(h))
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

  hs = nil
  # Now analysis of different authors
  puts "Commits analysis..."
  skip_logins = [
    'greenkeeper[bot]', 'web-flow', 'k8s-merge-robot', '', nil
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
      h[author['email']] = author['login']
      h[committer['email']] = committer['login']
      h.each do |email, login|
        next unless email.include?('@')
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
  json = email_encode(JSON.pretty_generate(final))
  File.write 'github_users.json', json
  puts "All done."
  # I had 908/5000 points left when running < 1 hour
end

ghusers(repos, start_date, ARGV)
