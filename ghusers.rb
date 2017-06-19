require 'pry'
require 'octokit'
require 'json'

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

Octokit.auto_paginate = true
client = Octokit::Client.new access_token: File.read('/etc/github/oauth').strip
user = client.user
user.login

Octokit.client_id = File.read('/etc/github/client_id').strip
Octokit.client_secret = File.read('/etc/github/client_secret').strip

rl = Octokit.rate_limit
puts "Your rate limit is: limit=#{rl.limit}, remaining=#{rl.remaining}, resets_at=#{rl.resets_at}, resets_in=#{rl.resets_in}"
puts "Type exit-program if You want to exit"
binding.pry

repos.each do |repo_name|
  begin
    puts "Processing #{repo_name}"
    fn = 'ghusers/' + repo_name.gsub('/', '__')
    f = File.read(fn)
    puts "Got JSON from saved file"
  rescue Errno::ENOENT => err1
    begin
      puts "No previously saved #{fn}, getting repo from GitHub"
      repo = Octokit.repo repo_name
      json = JSON.pretty_generate repo.to_h
      File.write fn, json
    rescue Octokit::TooManyRequests => err2
      rl = Octokit.rate_limit
      td = (rl.resets_at - Time.now).to_i + 1
      puts "Too many GitHub requests, sleeping for #{td} seconds"
      sleep td
      retry
    rescue => err2
      puts "Uups, somethis bad happened, check `err2` variable!"
      binding.pry
    end
  end
end
binding.pry

# user = Octokit.user 'jbarnette'
# repo = Octokit.repo 'pengwynn/pingwynn'
# Octokit.commits_since('kubernetes/test-infra', '2017-06-19')
# repo.to_h.to_json
