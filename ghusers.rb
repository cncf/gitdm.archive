require 'pry'
require 'octokit'
require 'json'
require 'securerandom'
require './email_code'
require './ghapi'

# Ask each repo for commits newer than...
start_date = '2014-01-01'

# List of repositories to retrieve commits from (and get their basic data)
repos = [
  'BuoyantIO/linkerd',
  'GoogleCloudPlatform/kubernetes',
  'apcera/gnatsd',
  'apcera/gssapi',
  'apcera/nats',
  'apcera/nginx-statsd',
  'apcera/sample-apps',
  'apcera/termtables',
  'appc/cni',
  'cloudevents/cloudevents-web',
  'cloudevents/cloudevents.github.io',
  'cloudevents/cloudevents.io',
  'cloudevents/spec',
  'cncf/ambassadors',
  'cncf/apisnoop',
  'cncf/artwork',
  'cncf/awards',
  'cncf/cla',
  'cncf/cluster',
  'cncf/cnfs',
  'cncf/contribute',
  'cncf/cross-cloud',
  'cncf/cross-project',
  'cncf/curriculum',
  'cncf/demo',
  'cncf/dev-affiliations',
  'cncf/devstats',
  'cncf/draft-wg-serverless',
  'cncf/filterable-landscape',
  'cncf/foundation',
  'cncf/gha2db',
  'cncf/gha2pg',
  'cncf/gitdm',
  'cncf/hnanalysis',
  'cncf/images',
  'cncf/k8s-conformance',
  'cncf/landscape',
  'cncf/meetups',
  'cncf/onap-demo',
  'cncf/presentations',
  'cncf/serverless-landscape',
  'cncf/servicebroker',
  'cncf/servicedesk',
  'cncf/soc',
  'cncf/svg-autocrop',
  'cncf/toc',
  'cncf/velocity',
  'cncf/wg-ci',
  'cncf/wg-networking',
  'cncf/wg-serverless',
  'cncf/wg-storage',
  'containerd/aufs',
  'containerd/btrfs',
  'containerd/cgroups',
  'containerd/console',
  'containerd/containerd',
  'containerd/continuity',
  'containerd/cri',
  'containerd/cri-containerd',
  'containerd/fifo',
  'containerd/go-cni',
  'containerd/go-runc',
  'containerd/project',
  'containerd/typeurl',
  'containerd/zfs',
  'containernetworking/cni',
  'containernetworking/plugins',
  'coredns/ci',
  'coredns/client',
  'coredns/cloud',
  'coredns/coredns',
  'coredns/coredns.io',
  'coredns/deployment',
  'coredns/distributed',
  'coredns/example',
  'coredns/fallback',
  'coredns/kubernetai',
  'coredns/logo',
  'coredns/perf-tests',
  'coredns/policy',
  'coredns/presentations',
  'coredns/unbound',
  'coreos/rkt',
  'coreos/rocket',
  'crosscloudci/artwork',
  'crosscloudci/build',
  'crosscloudci/ci-dashboard',
  'crosscloudci/ci_status_repository',
  'crosscloudci/cncf-configuration',
  'crosscloudci/coredns-configuration',
  'crosscloudci/cross-cloud',
  'crosscloudci/cross-project',
  'crosscloudci/crosscloudci',
  'crosscloudci/crosscloudci-trigger',
  'crosscloudci/fluentd-configuration',
  'crosscloudci/gitlab-dashboard-updater',
  'crosscloudci/kubernetes-configuration',
  'crosscloudci/linkerd-configuration',
  'crosscloudci/onap-ciservice',
  'crosscloudci/onap-so-configuration',
  'crosscloudci/prometheus-configuration',
  'datawire/telepresence',
  'docker/containerd',
  'docker/notary',
  'envoyproxy/artwork',
  'envoyproxy/control-plane',
  'envoyproxy/data-plane-api',
  'envoyproxy/envoy',
  'envoyproxy/envoy-api',
  'envoyproxy/envoy-filter-example',
  'envoyproxy/envoy-perf',
  'envoyproxy/envoy-tools',
  'envoyproxy/envoyproxy.github.io',
  'envoyproxy/go-control-plane',
  'envoyproxy/java-control-plane',
  'fluent/NLog.Targets.Fluentd',
  'fluent/data-collection',
  'fluent/fluent-bit',
  'fluent/fluent-bit-demo',
  'fluent/fluent-bit-docker',
  'fluent/fluent-bit-docker-image',
  'fluent/fluent-bit-docs',
  'fluent/fluent-bit-go',
  'fluent/fluent-bit-kubernetes-daemonset',
  'fluent/fluent-bit-kubernetes-logging',
  'fluent/fluent-bit-packaging',
  'fluent/fluent-bit-website',
  'fluent/fluent-logger-d',
  'fluent/fluent-logger-erlang',
  'fluent/fluent-logger-golang',
  'fluent/fluent-logger-java',
  'fluent/fluent-logger-node',
  'fluent/fluent-logger-ocaml',
  'fluent/fluent-logger-perl',
  'fluent/fluent-logger-php',
  'fluent/fluent-logger-python',
  'fluent/fluent-logger-ruby',
  'fluent/fluent-logger-scala',
  'fluent/fluent-plugin-flume',
  'fluent/fluent-plugin-grok-parser',
  'fluent/fluent-plugin-hoop',
  'fluent/fluent-plugin-kafka',
  'fluent/fluent-plugin-mongo',
  'fluent/fluent-plugin-msgpack-rpc',
  'fluent/fluent-plugin-multiprocess',
  'fluent/fluent-plugin-prometheus',
  'fluent/fluent-plugin-rewrite-tag-filter',
  'fluent/fluent-plugin-s3',
  'fluent/fluent-plugin-scribe',
  'fluent/fluent-plugin-splunk',
  'fluent/fluent-plugin-sql',
  'fluent/fluent-plugin-webhdfs',
  'fluent/fluent-plugin-windows-eventlog',
  'fluent/fluent-plugin-winevtlog',
  'fluent/fluent-plugins',
  'fluent/fluentbit-dashboard',
  'fluent/fluentbit-website-v2',
  'fluent/fluentd',
  'fluent/fluentd-benchmark',
  'fluent/fluentd-docker-image',
  'fluent/fluentd-docs',
  'fluent/fluentd-docs-kubernetes',
  'fluent/fluentd-forwarder',
  'fluent/fluentd-kubernetes-daemonset',
  'fluent/fluentd-ui',
  'fluent/fluentd-website',
  'fluent/kafka-connect-fluentd',
  'fluent/nginx-fluentd-module',
  'fluent/serverengine',
  'fluent/website',
  'grpc/grpc',
  'grpc/grpc-common',
  'grpc/grpc-contrib',
  'grpc/grpc-dart',
  'grpc/grpc-docker-library',
  'grpc/grpc-experiments',
  'grpc/grpc-go',
  'grpc/grpc-haskell',
  'grpc/grpc-java',
  'grpc/grpc-java-api-checker',
  'grpc/grpc-node',
  'grpc/grpc-php',
  'grpc/grpc-proto',
  'grpc/grpc-swift',
  'grpc/grpc-web',
  'grpc/grpc.github.io',
  'grpc/homebrew-grpc',
  'grpc/proposal',
  'jaegertracing/artwork',
  'jaegertracing/cpp-client',
  'jaegertracing/documentation',
  'jaegertracing/jaeger',
  'jaegertracing/jaeger-client-cpp',
  'jaegertracing/jaeger-client-csharp',
  'jaegertracing/jaeger-client-go',
  'jaegertracing/jaeger-client-java',
  'jaegertracing/jaeger-client-javascript',
  'jaegertracing/jaeger-client-node',
  'jaegertracing/jaeger-client-python',
  'jaegertracing/jaeger-documentation',
  'jaegertracing/jaeger-idl',
  'jaegertracing/jaeger-kubernetes',
  'jaegertracing/jaeger-lib',
  'jaegertracing/jaeger-openshift',
  'jaegertracing/jaeger-performance',
  'jaegertracing/jaeger-ui',
  'jaegertracing/legacy-client-java',
  'jaegertracing/spark-dependencies',
  'jaegertracing/xdock-zipkin-brave',
  'kubernetes-client/client-python',
  'kubernetes-client/community',
  'kubernetes-client/csharp',
  'kubernetes-client/gen',
  'kubernetes-client/go',
  'kubernetes-client/go-base',
  'kubernetes-client/haskell',
  'kubernetes-client/java',
  'kubernetes-client/javascript',
  'kubernetes-client/python',
  'kubernetes-client/python-base',
  'kubernetes-client/ruby',
  'kubernetes-client/typescript',
  'kubernetes-helm/chart-testing',
  'kubernetes-helm/chartmuseum',
  'kubernetes-helm/charts-tooling',
  'kubernetes-helm/community',
  'kubernetes-helm/helm-summit-notes',
  'kubernetes-helm/monocular',
  'kubernetes-helm/rudder-federation',
  'kubernetes-incubator/apiserver-builder',
  'kubernetes-incubator/application-images',
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
  'kubernetes/api',
  'kubernetes/apiextensions-apiserver',
  'kubernetes/apimachinery',
  'kubernetes/apiserver',
  'kubernetes/application-dm-templates',
  'kubernetes/application-images',
  'kubernetes/autoscaler',
  'kubernetes/charts',
  'kubernetes/client-go',
  'kubernetes/cloud-provider-aws',
  'kubernetes/cloud-provider-azure',
  'kubernetes/cloud-provider-gcp',
  'kubernetes/cloud-provider-openstack',
  'kubernetes/cloud-provider-vsphere',
  'kubernetes/cluster-proportional-autoscaler',
  'kubernetes/cluster-registry',
  'kubernetes/code-generator',
  'kubernetes/common',
  'kubernetes/community',
  'kubernetes/console',
  'kubernetes/contrib',
  'kubernetes/dashboard',
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
  'kubernetes/horizontal-self-scaler',
  'kubernetes/ingress',
  'kubernetes/ingress-gce',
  'kubernetes/ingress-nginx',
  'kubernetes/k8s.io',
  'kubernetes/kompose',
  'kubernetes/kops',
  'kubernetes/kube-aggregator',
  'kubernetes/kube-deploy',
  'kubernetes/kube-openapi',
  'kubernetes/kube-state-metrics',
  'kubernetes/kube-ui',
  'kubernetes/kubeadm',
  'kubernetes/kubectl',
  'kubernetes/kubedash',
  'kubernetes/kubernetes',
  'kubernetes/kubernetes-anywhere',
  'kubernetes/kubernetes-bootcamp',
  'kubernetes/kubernetes-console',
  'kubernetes/kubernetes-docs-cn',
  'kubernetes/kubernetes-template-project',
  'kubernetes/kubernetes.github.io',
  'kubernetes/md-check',
  'kubernetes/md-format',
  'kubernetes/metrics',
  'kubernetes/minikube',
  'kubernetes/node-problem-detector',
  'kubernetes/perf-tests',
  'kubernetes/publishing-bot',
  'kubernetes/release',
  'kubernetes/repo-infra',
  'kubernetes/rktlet',
  'kubernetes/sample-apiserver',
  'kubernetes/sample-controller',
  'kubernetes/sig-release',
  'kubernetes/steering',
  'kubernetes/test-infra',
  'kubernetes/utils',
  'kubernetes/website',
  'linkerd/k8s-community-cluster',
  'linkerd/linkerd',
  'linkerd/linkerd-examples',
  'linkerd/linkerd-inject',
  'linkerd/linkerd-tcp',
  'linkerd/linkerd-viz',
  'linkerd/linkerd-zipkin',
  'linkerd/namerctl',
  'linkerd/rustup-nightly-docker',
  'linkerd/tacho',
  'lyft/envoy',
  'miekg/coredns',
  'nats-io/asyncio-nats',
  'nats-io/asyncio-nats-streaming',
  'nats-io/cnats',
  'nats-io/csharp-nats',
  'nats-io/csharp-nats-streaming',
  'nats-io/csnats',
  'nats-io/demo-minio-nats',
  'nats-io/deploy',
  'nats-io/docker-docs',
  'nats-io/docs',
  'nats-io/elixir-nats',
  'nats-io/gnatsd',
  'nats-io/go-nats',
  'nats-io/go-nats-streaming',
  'nats-io/graft',
  'nats-io/java-nats',
  'nats-io/java-nats-streaming',
  'nats-io/jnats',
  'nats-io/js-nuid',
  'nats-io/nats',
  'nats-io/nats-connector',
  'nats-io/nats-connector-framework',
  'nats-io/nats-connector-redis',
  'nats-io/nats-connector-redis-plugin',
  'nats-io/nats-docker',
  'nats-io/nats-on-a-log',
  'nats-io/nats-operator',
  'nats-io/nats-parent-pom',
  'nats-io/nats-site',
  'nats-io/nats-streaming-docker',
  'nats-io/nats-streaming-server',
  'nats-io/nats-top',
  'nats-io/nginx-nats',
  'nats-io/nkeys',
  'nats-io/node-nats',
  'nats-io/node-nats-streaming',
  'nats-io/node-nuid',
  'nats-io/nuid',
  'nats-io/official-images',
  'nats-io/prometheus-nats-exporter',
  'nats-io/pure-ruby-nats',
  'nats-io/python-nats',
  'nats-io/queues.io',
  'nats-io/roadmap',
  'nats-io/ruby-nats',
  'nats-io/ruby-nats-streaming',
  'nats-io/sublist',
  'open-policy-agent/client-python',
  'open-policy-agent/contrib',
  'open-policy-agent/docker-authz-plugin',
  'open-policy-agent/kube-mgmt',
  'open-policy-agent/library',
  'open-policy-agent/opa',
  'open-policy-agent/opa-docker-authz',
  'open-policy-agent/opa-git-sync',
  'open-policy-agent/opa-istio-plugin',
  'open-policy-agent/opa-kube-scheduler',
  'open-policy-agent/opa-test-plugin',
  'open-policy-agent/rego-scheduler',
  'opencontainers/image-spec',
  'opencontainers/image-tools',
  'opencontainers/ocitools',
  'opencontainers/runc',
  'opencontainers/runtime-spec',
  'opencontainers/runtime-tools',
  'opencontainers/specs',
  'openeventing/spec',
  'opentracing/api-go',
  'opentracing/api-golang',
  'opentracing/api-java',
  'opentracing/api-python',
  'opentracing/basictracer-csharp',
  'opentracing/basictracer-go',
  'opentracing/basictracer-javascript',
  'opentracing/basictracer-python',
  'opentracing/contrib',
  'opentracing/documentation',
  'opentracing/opentracing-c',
  'opentracing/opentracing-cpp',
  'opentracing/opentracing-csharp',
  'opentracing/opentracing-go',
  'opentracing/opentracing-java',
  'opentracing/opentracing-java-v030',
  'opentracing/opentracing-javascript',
  'opentracing/opentracing-objc',
  'opentracing/opentracing-php',
  'opentracing/opentracing-python',
  'opentracing/opentracing-ruby',
  'opentracing/opentracing-rust',
  'opentracing/opentracing.github.io',
  'opentracing/opentracing.io',
  'opentracing/specification',
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
  'prometheus/demo-site',
  'prometheus/distro-pkgs',
  'prometheus/docs',
  'prometheus/golang-builder',
  'prometheus/graphite_exporter',
  'prometheus/haproxy_exporter',
  'prometheus/host_exporter',
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
  'prometheus/prometheus.github.io',
  'prometheus/prometheus_api_client_ruby',
  'prometheus/prometheus_cli',
  'prometheus/promu',
  'prometheus/pushgateway',
  'prometheus/snmp_exporter',
  'prometheus/statsd_bridge',
  'prometheus/statsd_exporter',
  'prometheus/talks',
  'prometheus/tsdb',
  'prometheus/utils',
  'rkt/rkt',
  'rkt/rkt-builder',
  'rkt/stage1-xen',
  'rktproject/rkt',
  'rook/artwork',
  'rook/ceph',
  'rook/coreos-kubernetes',
  'rook/operator-kit',
  'rook/rook',
  'rook/rook.github.io',
  'spiffe/aws-iid-attestor',
  'spiffe/aws-resolver',
  'spiffe/aws-role-attestor',
  'spiffe/c-spiffe',
  'spiffe/clabot',
  'spiffe/etcd-datastore',
  'spiffe/ghostunnel',
  'spiffe/go-spiffe',
  'spiffe/java-spiffe',
  'spiffe/kerberos-attestor',
  'spiffe/plugin-template',
  'spiffe/sidecar',
  'spiffe/spiffe',
  'spiffe/spiffe-example',
  'spiffe/spiffe-helper',
  'spiffe/spiffe-nginx',
  'spiffe/spiffe.github.io',
  'spiffe/spire',
  'spiffe/spire-k8s',
  'spiffe/spire-test',
  'telepresenceio/ci-experiment',
  'telepresenceio/telepresence',
  'theupdateframework/artwork',
  'theupdateframework/notary',
  'theupdateframework/pep-maximum-security-model',
  'theupdateframework/pep-on-pypi-with-tuf',
  'theupdateframework/pip',
  'theupdateframework/pypi.updateframework.com',
  'theupdateframework/specification',
  'theupdateframework/taps',
  'theupdateframework/theupdateframework.github.io',
  'theupdateframework/tuf',
  'uber/jaeger',
  'vitessio/contrib',
  'vitessio/messages',
  'vitessio/vitess',
  'vitessio/vitess-operator',
  'youtube/api-samples',
  'youtube/doorman',
  'youtube/geo-search-tool',
  'youtube/spfjs',
  'youtube/vitess',
  'youtube/youtube-ios-player-helper',
  'youtube/youtubechatbot',
  'youtube/yt-android-player',
  'youtube/yt-direct-lite-android',
  'youtube/yt-watchme'
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

  # Process repositories general info
  hs = []
  n_repos = repos.count

  rate_limit()
  puts "Type exit-program if You want to exit"
  # This is to ensure You want to continue, it displays Your limit, should be close to 5000
  # If not type 'exit-program' if Yes type 'quit' (to quit debugger & continue)
  binding.pry
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
      puts "Uups, somethig bad happened, check `err2` variable!"
      binding.pry
    end
  end
  json = email_encode(JSON.pretty_generate(final))
  File.write 'github_users.json', json
  puts "All done: please not that new JSON has *only* data for committers"
  # I had 908/5000 points left when running < 1 hour
end

ghusers(repos, start_date, ARGV)
