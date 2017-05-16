#!/bin/sh
./anyrepo.sh ~/dev/go/src/k8s.io/test-infra/ test-infra
./anyrepo.sh ~/dev/go/src/k8s.io/kubernetes/ kubernetes
./anyrepo.sh ~/dev/go/src/k8s.io/kubernetes.github.io/ kubernetes.github.io
./anyrepo.sh ~/dev/go/src/k8s.io/contrib/ contrib
./anyrepo.sh ~/dev/go/src/k8s.io/helm/ helm
./anyrepo.sh ~/dev/go/src/k8s.io/kops/ kops
./anyrepo.sh ~/dev/go/src/k8s.io/community/ community
./anyrepo.sh ~/dev/go/src/k8s.io/heapster/ heapster
./anyrepo.sh ~/dev/go/src/k8s.io/dashboard/ dashboard
./anyrepo.sh ~/dev/go/src/k8s.io/minikube/ minikube
./anyrepo.sh ~/dev/go/src/k8s.io/charts/ charts
./anyrepo.sh ~/dev/go/src/k8s.io/kube-state-metrics/ kube-state-metrics
./anyrepo.sh ~/dev/go/src/k8s.io/kubernetes-anywhere/ kubernetes-anywhere
./anyrepo.sh ~/dev/go/src/k8s.io/ingress/ ingress
./anyrepo.sh ~/dev/go/src/k8s.io/release/ release
./anyrepo.sh ~/dev/go/src/k8s.io/gengo/ gengo
./anyrepo.sh ~/dev/go/src/k8s.io/autoscaler/ autoscaler
./anyrepo.sh ~/dev/go/src/k8s.io/dns/ dns
./anyrepo.sh ~/dev/go/src/k8s.io/sample-apiserver/ sample-apiserver
./anyrepo.sh ~/dev/go/src/k8s.io/apiserver/ apiserver
./anyrepo.sh ~/dev/go/src/k8s.io/kube-aggregator/ kube-aggregator
./anyrepo.sh ~/dev/go/src/k8s.io/client-go/ client-go
./anyrepo.sh ~/dev/go/src/k8s.io/node-problem-detector/ node-problem-detector
./anyrepo.sh ~/dev/go/src/k8s.io/perf-tests/ perf-tests
./anyrepo.sh ~/dev/go/src/k8s.io/apimachinery/ apimachinery
./anyrepo.sh ~/dev/go/src/k8s.io/frakti/ frakti
./anyrepo.sh ~/dev/go/src/k8s.io/features/ features
./anyrepo.sh ~/dev/go/src/k8s.io/repo-infra/ repo-infra
./anyrepo.sh ~/dev/go/src/k8s.io/kube-deploy/ kube-deploy
./anyrepo.sh ~/dev/go/src/k8s.io/examples/ examples
./anyrepo.sh ~/dev/go/src/k8s.io/git-sync/ git-sync
./anyrepo.sh ~/dev/go/src/k8s.io/k8s.io/ k8s.io
./anyrepo.sh ~/dev/go/src/k8s.io/kubernetes-bootcamp/ kubernetes-bootcamp
./anyrepo.sh ~/dev/go/src/k8s.io/kubectl/ kubectl
./anyrepo.sh ~/dev/go/src/k8s.io/metrics/ metrics
./anyrepo.sh ~/dev/go/src/k8s.io/md-check/ md-check
./anyrepo.sh ~/dev/go/src/k8s.io/kubernetes-template-project/ kubernetes-template-project
./anyrepo.sh ~/dev/go/src/k8s.io/kubernetes-docs-cn/ kubernetes-docs-cn
./anyrepo.sh ~/dev/go/src/k8s.io/kube-ui/ kube-ui
echo "All repos combined"
./multirepo.sh ~/dev/go/src/k8s.io/test-infra/ ~/dev/go/src/k8s.io/kubernetes/ ~/dev/go/src/k8s.io/kubernetes.github.io/ ~/dev/go/src/k8s.io/contrib/ ~/dev/go/src/k8s.io/helm/ ~/dev/go/src/k8s.io/kops/ ~/dev/go/src/k8s.io/community/ ~/dev/go/src/k8s.io/heapster/ ~/dev/go/src/k8s.io/dashboard/ ~/dev/go/src/k8s.io/minikube/ ~/dev/go/src/k8s.io/charts/ ~/dev/go/src/k8s.io/kube-state-metrics/ ~/dev/go/src/k8s.io/kubernetes-anywhere/ ~/dev/go/src/k8s.io/ingress/ ~/dev/go/src/k8s.io/release/ ~/dev/go/src/k8s.io/gengo/ ~/dev/go/src/k8s.io/autoscaler/ ~/dev/go/src/k8s.io/dns/ ~/dev/go/src/k8s.io/sample-apiserver/ ~/dev/go/src/k8s.io/apiserver/ ~/dev/go/src/k8s.io/kube-aggregator/ ~/dev/go/src/k8s.io/client-go/ ~/dev/go/src/k8s.io/node-problem-detector/ ~/dev/go/src/k8s.io/perf-tests/ ~/dev/go/src/k8s.io/apimachinery/ ~/dev/go/src/k8s.io/frakti/ ~/dev/go/src/k8s.io/features/ ~/dev/go/src/k8s.io/repo-infra/ ~/dev/go/src/k8s.io/kube-deploy/ ~/dev/go/src/k8s.io/examples/ ~/dev/go/src/k8s.io/git-sync/ ~/dev/go/src/k8s.io/k8s.io/ ~/dev/go/src/k8s.io/kubernetes-bootcamp/ ~/dev/go/src/k8s.io/kubectl/ ~/dev/go/src/k8s.io/metrics/ ~/dev/go/src/k8s.io/md-check/ ~/dev/go/src/k8s.io/kubernetes-template-project/ ~/dev/go/src/k8s.io/kubernetes-docs-cn/ ~/dev/go/src/k8s.io/kubernetes-docs-cn/
echo "TopDevs, google others and unknowns"
./topdevs.sh
