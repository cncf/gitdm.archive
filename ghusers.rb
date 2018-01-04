require 'pry'
require 'octokit'
require 'json'
require 'securerandom'
require './email_code'
require './ghapi'

# Ask each repo for commits newer than...
start_date = '2014-04-01'

# List of repositories to retrieve commits from (and get their basic data)
repos = [
  'GoogleCloudPlatform/kubernetes',
  'kubernetes-incubator/external-dns',
  'kubernetes-incubator/kube-arbitrator',
  'kubernetes-incubator/service-catalog',
  'kubernetes-incubator/node-feature-discovery',
  'kubernetes-incubator/cri-containerd',
  'kubernetes-incubator/spartakus',
  'kubernetes-incubator/cri-o',
  'kubernetes-incubator/ip-masq-agent',
  'kubernetes-incubator/external-storage',
  'kubernetes-incubator/kube-aws',
  'kubernetes-incubator/nfs-provisioner',
  'kubernetes-incubator/custom-metrics-apiserver',
  'kubernetes-incubator/cluster-proportional-autoscaler',
  'kubernetes-incubator/metrics-server',
  'kubernetes-incubator/apiserver-builder',
  'kubernetes-incubator/bootkube',
  'kubernetes-incubator/kargo',
  'kubernetes-incubator/cluster-proportional-vertical-autoscaler',
  'kubernetes-incubator/client-python',
  'kubernetes-incubator/kube-mesos-framework',
  'kubernetes-incubator/kompose',
  'kubernetes-incubator/cluster-capacity',
  'kubernetes-incubator/descheduler',
  'kubernetes-incubator/cri-tools',
  'kubernetes-incubator/reference-docs',
  'kubernetes-incubator/ocid',
  'kubernetes-incubator/kubespray',
  'kubernetes-incubator/rktlet',
  'kubernetes-incubator/rescheduler',
  'kubernetes-incubator/application-images',
  'kubernetes-helm/community',
  'kubernetes-helm/rudder-federation',
  'kubernetes-helm/monocular',
  'kubernetes-helm/chartmuseum',
  'kubernetes-helm/charts-tooling',
  'fluent/fluentbit-website-v2',
  'fluent/fluentd-docs',
  'fluent/fluent-plugin-kafka',
  'fluent/fluent-bit',
  'fluent/fluentd-docs-kubernetes',
  'fluent/fluent-plugin-multiprocess',
  'fluent/fluent-plugin-windows-eventlog',
  'fluent/fluent-logger-ruby',
  'fluent/fluent-bit-go',
  'fluent/fluent-plugins',
  'fluent/fluent-logger-php',
  'fluent/website',
  'fluent/fluent-plugin-hoop',
  'fluent/fluentd-website',
  'fluent/fluent-logger-scala',
  'fluent/fluent-plugin-flume',
  'fluent/fluent-plugin-rewrite-tag-filter',
  'fluent/fluent-logger-golang',
  'fluent/nginx-fluentd-module',
  'fluent/fluent-plugin-mongo',
  'fluent/fluentd-benchmark',
  'fluent/kafka-connect-fluentd',
  'fluent/fluentd-ui',
  'fluent/fluent-plugin-s3',
  'fluent/fluent-bit-demo',
  'fluent/fluent-logger-perl',
  'fluent/NLog.Targets.Fluentd',
  'fluent/fluent-logger-java',
  'fluent/fluentbit-dashboard',
  'fluent/fluent-plugin-grok-parser',
  'fluent/fluent-plugin-msgpack-rpc',
  'fluent/fluent-bit-kubernetes-daemonset',
  'fluent/fluent-logger-d',
  'fluent/fluent-bit-docker-image',
  'fluent/fluent-bit-docs',
  'fluent/fluent-plugin-prometheus',
  'fluent/fluent-bit-kubernetes-logging',
  'fluent/fluent-logger-python',
  'fluent/fluent-logger-node',
  'fluent/fluent-logger-ocaml',
  'fluent/fluentd-kubernetes-daemonset',
  'fluent/fluentd-docker-image',
  'fluent/fluent-bit-packaging',
  'fluent/fluent-bit-website',
  'fluent/fluent-logger-erlang',
  'fluent/fluent-plugin-sql',
  'fluent/serverengine',
  'fluent/fluentd',
  'fluent/fluent-plugin-winevtlog',
  'fluent/fluent-plugin-webhdfs',
  'fluent/fluentd-forwarder',
  'fluent/fluent-plugin-scribe',
  'fluent/data-collection',
  'fluent/fluent-bit-docker',
  'BuoyantIO/linkerd',
  'containerd/go-runc',
  'containerd/zfs',
  'containerd/console',
  'containerd/typeurl',
  'containerd/cgroups',
  'containerd/aufs',
  'containerd/continuity',
  'containerd/btrfs',
  'containerd/fifo',
  'containerd/containerd',
  'docker/containerd',
  'kubernetes/api',
  'kubernetes/kubeadm',
  'kubernetes/git-sync',
  'kubernetes/apiserver',
  'kubernetes/website',
  'kubernetes/charts',
  'kubernetes/heapster',
  'kubernetes/helm',
  'kubernetes/kops',
  'kubernetes/client-go',
  'kubernetes/kube-deploy',
  'kubernetes/gengo',
  'kubernetes/contrib',
  'kubernetes/rktlet',
  'kubernetes/apimachinery',
  'kubernetes/frakti',
  'kubernetes/utils',
  'kubernetes/cluster-registry',
  'kubernetes/application-images',
  'kubernetes/horizontal-self-scaler',
  'kubernetes/md-check',
  'kubernetes/md-format',
  'kubernetes/apiextensions-apiserver',
  'kubernetes/kube-aggregator',
  'kubernetes/kompose',
  'kubernetes/release',
  'kubernetes/autoscaler',
  'kubernetes/sample-apiserver',
  'kubernetes/deployment-manager',
  'kubernetes/kube-state-metrics',
  'kubernetes/k8s.io',
  'kubernetes/sample-controller',
  'kubernetes/perf-tests',
  'kubernetes/kubedash',
  'kubernetes/kube-openapi',
  'kubernetes/dns',
  'kubernetes/cluster-proportional-autoscaler',
  'kubernetes/ingress-nginx',
  'kubernetes/test-infra',
  'kubernetes/federation',
  'kubernetes/kubernetes-anywhere',
  'kubernetes/common',
  'kubernetes/console',
  'kubernetes/dashboard',
  'kubernetes/steering',
  'kubernetes/code-generator',
  'kubernetes/publishing-bot',
  'kubernetes/ingress-gce',
  'kubernetes/kubernetes.github.io',
  'kubernetes/kubernetes-console',
  'kubernetes/features',
  'kubernetes/kubernetes-template-project',
  'kubernetes/minikube',
  'kubernetes/ingress',
  'kubernetes/kubernetes-bootcamp',
  'kubernetes/kubectl',
  'kubernetes/application-dm-templates',
  'kubernetes/kube-ui',
  'kubernetes/node-problem-detector',
  'kubernetes/examples',
  'kubernetes/sig-release',
  'kubernetes/repo-infra',
  'kubernetes/kubernetes',
  'kubernetes/community',
  'kubernetes/kubernetes-docs-cn',
  'kubernetes/metrics',
  'kubernetes-client/community',
  'kubernetes-client/python-base',
  'kubernetes-client/gen',
  'kubernetes-client/typescript',
  'kubernetes-client/csharp',
  'kubernetes-client/java',
  'kubernetes-client/go-base',
  'kubernetes-client/go',
  'kubernetes-client/javascript',
  'kubernetes-client/haskell',
  'kubernetes-client/ruby',
  'linkerd/linkerd-tcp',
  'linkerd/rustup-nightly-docker',
  'linkerd/linkerd-viz',
  'linkerd/namerctl',
  'linkerd/linkerd-inject',
  'linkerd/linkerd',
  'linkerd/tacho',
  'linkerd/linkerd-examples',
  'linkerd/linkerd-zipkin',
  'coredns/distributed',
  'coredns/cloud',
  'coredns/coredns.io',
  'coredns/deployment',
  'coredns/presentations',
  'coredns/coredns',
  'coredns/logo',
  'coredns/ci',
  'coredns/forward',
  'coredns/example',
  'coredns/perf-tests',
  'prometheus/haproxy_exporter',
  'prometheus/alertmanager',
  'prometheus/client_java',
  'prometheus/cloudwatch_exporter',
  'prometheus/mysqld_exporter',
  'prometheus/prometheus',
  'prometheus/distro-pkgs',
  'prometheus/promdash',
  'prometheus/docs',
  'prometheus/haproxy_exporter',
  'prometheus/promu',
  'prometheus/tsdb',
  'prometheus/nagios_plugins',
  'prometheus/statsd_exporter',
  'prometheus/mesos_exporter',
  'prometheus/alertmanager',
  'prometheus/client_golang',
  'prometheus/memcached_exporter',
  'prometheus/host_exporter',
  'prometheus/jmx_exporter',
  'prometheus/prometheus_cli',
  'prometheus/prometheus.github.io',
  'prometheus/procfs',
  'prometheus/migrate',
  'prometheus/client_java',
  'prometheus/client_python',
  'prometheus/demo',
  'prometheus/utils',
  'prometheus/mysqld_exporter',
  'prometheus/prometheus_api_client_ruby',
  'prometheus/common',
  'prometheus/snmp_exporter',
  'prometheus/consul_exporter',
  'prometheus/prometheus',
  'prometheus/statsd_bridge',
  'prometheus/collectd_exporter',
  'prometheus/golang-builder',
  'prometheus/prombench',
  'prometheus/build_tools',
  'prometheus/pushgateway',
  'prometheus/graphite_exporter',
  'prometheus/client_model',
  'prometheus/node_exporter',
  'prometheus/blackbox_exporter',
  'prometheus/client_ruby',
  'prometheus/cloudwatch_exporter',
  'prometheus/prom2json',
  'prometheus/influxdb_exporter',
  'prometheus/log',
  'prometheus/busybox',
  'opentracing/api-python',
  'opentracing/api-java',
  'opentracing/opentracing-python',
  'opentracing/opentracing.github.io',
  'opentracing/basictracer-python',
  'opentracing/opentracing-cpp',
  'opentracing/opentracing-go',
  'opentracing/opentracing-php',
  'opentracing/basictracer-csharp',
  'opentracing/basictracer-go',
  'opentracing/contrib',
  'opentracing/api-golang',
  'opentracing/opentracing-java',
  'opentracing/opentracing-ruby',
  'opentracing/opentracing-java-v030',
  'opentracing/basictracer-javascript',
  'opentracing/opentracing-objc',
  'opentracing/documentation',
  'opentracing/opentracing.io',
  'opentracing/opentracing-javascript',
  'opentracing/api-go',
  'opentracing/opentracing-csharp',
  'opentracing/specification',
  'grpc/grpc-contrib',
  'grpc/grpc-go',
  'grpc/proposal',
  'grpc/grpc-swift',
  'grpc/grpc-common',
  'grpc/grpc',
  'grpc/grpc.github.io',
  'grpc/grpc-proto',
  'grpc/homebrew-grpc',
  'grpc/grpc-java',
  'grpc/grpc-docker-library',
  'grpc/grpc-node',
  'grpc/grpc-php',
  'grpc/grpc-haskell',
  'grpc/grpc-experiments'
]

# args[0]: 1st arg is: 'r' - force repos metadata fetch, 'c' - force commits fetch, 'u' force users fetch
def ghusers(repos, start_date, args)
  # Args processing
  force_repo = false
  force_commits = false
  force_users = false
  force_repo = true if args.length > 0 && args[0].downcase.include?('r')
  force_commits = true if args.length > 0 && args[0].downcase.include?('c')
  force_users = true if args.length > 0 && args[0].downcase.include?('u')

  octokit_init()

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
    'greenkeeper[bot]', 'web-flow', 'k8s-merge-robot', 'codecov[bot]', 'stale[bot]',
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
      h[author['email']] = author['login']
      h[committer['email']] = committer['login']
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
