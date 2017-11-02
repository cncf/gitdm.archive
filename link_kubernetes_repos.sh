#!/bin/sh
cd ~/dev/kubernetes_repos_links
# kubernetes org
ln -s ~/dev/go/src/k8s.io/test-infra/ test-infra
ln -s ~/dev/go/src/k8s.io/kubernetes/ kubernetes
ln -s ~/dev/go/src/k8s.io/kubernetes.github.io/ kubernetes.github.io
ln -s ~/dev/go/src/k8s.io/contrib/ contrib
ln -s ~/dev/go/src/k8s.io/helm/ helm
ln -s ~/dev/go/src/k8s.io/kops/ kops
ln -s ~/dev/go/src/k8s.io/community/ community
ln -s ~/dev/go/src/k8s.io/heapster/ heapster
ln -s ~/dev/go/src/k8s.io/dashboard/ dashboard
ln -s ~/dev/go/src/k8s.io/minikube/ minikube
ln -s ~/dev/go/src/k8s.io/charts/ charts
ln -s ~/dev/go/src/k8s.io/kube-state-metrics/ kube-state-metrics
ln -s ~/dev/go/src/k8s.io/kubernetes-anywhere/ kubernetes-anywhere
ln -s ~/dev/go/src/k8s.io/ingress/ ingress
ln -s ~/dev/go/src/k8s.io/release/ release
ln -s ~/dev/go/src/k8s.io/gengo/ gengo
ln -s ~/dev/go/src/k8s.io/autoscaler/ autoscaler
ln -s ~/dev/go/src/k8s.io/dns/ dns
ln -s ~/dev/go/src/k8s.io/sample-apiserver/ sample-apiserver
ln -s ~/dev/go/src/k8s.io/apiserver/ apiserver
ln -s ~/dev/go/src/k8s.io/kube-aggregator/ kube-aggregator
ln -s ~/dev/go/src/k8s.io/client-go/ client-go
ln -s ~/dev/go/src/k8s.io/node-problem-detector/ node-problem-detector
ln -s ~/dev/go/src/k8s.io/perf-tests/ perf-tests
ln -s ~/dev/go/src/k8s.io/apimachinery/ apimachinery
ln -s ~/dev/go/src/k8s.io/frakti/ frakti
ln -s ~/dev/go/src/k8s.io/features/ features
ln -s ~/dev/go/src/k8s.io/repo-infra/ repo-infra
ln -s ~/dev/go/src/k8s.io/kube-deploy/ kube-deploy
ln -s ~/dev/go/src/k8s.io/examples/ examples
ln -s ~/dev/go/src/k8s.io/git-sync/ git-sync
ln -s ~/dev/go/src/k8s.io/k8s.io/ k8s.io
ln -s ~/dev/go/src/k8s.io/kubernetes-bootcamp/ kubernetes-bootcamp
ln -s ~/dev/go/src/k8s.io/kubectl/ kubectl
ln -s ~/dev/go/src/k8s.io/metrics/ metrics
ln -s ~/dev/go/src/k8s.io/md-check/ md-check
ln -s ~/dev/go/src/k8s.io/kubernetes-template-project/ kubernetes-template-project
ln -s ~/dev/go/src/k8s.io/kubernetes-docs-cn/ kubernetes-docs-cn
ln -s ~/dev/go/src/k8s.io/kube-ui/ kube-ui
ln -s ~/dev/go/src/k8s.io/kubeadm/ kubeadm
# kubernetes-incubator org
ln -s ~/dev/go/src/k8s.io/kompose/ kompose
ln -s ~/dev/go/src/k8s.io/external-storage/ external-storage
ln -s ~/dev/go/src/k8s.io/cri-tools/ cri-tools
ln -s ~/dev/go/src/k8s.io/kube-aws/ kube-aws
ln -s ~/dev/go/src/k8s.io/external-dns/ external-dns
ln -s ~/dev/go/src/k8s.io/bootkube/ bootkube
ln -s ~/dev/go/src/k8s.io/service-catalog/ service-catalog
ln -s ~/dev/go/src/k8s.io/kargo/ kargo
ln -s ~/dev/go/src/k8s.io/cri-o/ cri-o
ln -s ~/dev/go/src/k8s.io/cri-containerd/ cri-containerd
ln -s ~/dev/go/src/k8s.io/apiserver-builder/ apiserver-builder
ln -s ~/dev/go/src/k8s.io/ip-masq-agent/ ip-masq-agent
ln -s ~/dev/go/src/k8s.io/client-python/ client-python
ln -s ~/dev/go/src/k8s.io/cluster-capacity/ cluster-capacity
ln -s ~/dev/go/src/k8s.io/reference-docs/ reference-docs
ln -s ~/dev/go/src/k8s.io/kube-mesos-framework/ kube-mesos-framework
ln -s ~/dev/go/src/k8s.io/rktlet/ rktlet
ln -s ~/dev/go/src/k8s.io/spartakus/ spartakus
ln -s ~/dev/go/src/k8s.io/cluster-proportional-autoscaler/ cluster-proportional-autoscaler
ln -s ~/dev/go/src/k8s.io/nfs-provisioner/ nfs-provisioner
ln -s ~/dev/go/src/k8s.io/node-feature-discovery/ node-feature-discovery
ln -s ~/dev/go/src/k8s.io/application-images/ application-images
# kubernetes-client org
ln -s ~/dev/go/src/k8s.io/java/ java
ln -s ~/dev/go/src/k8s.io/gen/ gen
ln -s ~/dev/go/src/k8s.io/python-base/ python-base
ln -s ~/dev/go/src/k8s.io/csharp/ csharp
ln -s ~/dev/go/src/k8s.io/ruby/ ruby
ln -s ~/dev/go/src/k8s.io/javascript/ javascript
# community --> kubernetes-client-community (renamed due to name conflict)
ln -s ~/dev/go/src/k8s.io/kubernetes-client-community/ kubernetes-client-community
ln -s ~/dev/go/src/k8s.io/go-base/ go-base
ln -s ~/dev/go/src/k8s.io/go/ go
# kubernetes-helm org
ln -s ~/dev/go/src/k8s.io/chartmuseum/ chartmuseum
ln -s ~/dev/go/src/k8s.io/monocular/ monocular
ln -s ~/dev/go/src/k8s.io/rudder-federation/ rudder-federation
ln -s ~/dev/go/src/k8s.io/kubernetes-helm-community/ kubernetes-helm-community
# We no more need 3 kubernetes orgs: kubernetes-contrib, kubernetes-ui, kubernetes-cluster-automation
# kubernetes-contrib org
# application-images --> kubernetes-contrib-application-images (renamed due to name conflict)
# ln -s ~/dev/go/src/k8s.io/kubernetes-contrib-application-images/ kubernetes-contrib-application-images
# ln -s ~/dev/go/src/k8s.io/jumpserver/ jumpserver
# ln -s ~/dev/go/src/k8s.io/graylog2/ graylog2
# ln -s ~/dev/go/src/k8s.io/consul/ consul
# kubernetes-cluster-automation org
# ln -s ~/dev/go/src/k8s.io/docker-registry/ docker-registry 
# ln -s ~/dev/go/src/k8s.io/kubernetes-minion/ kubernetes-minion 
# ln -s ~/dev/go/src/k8s.io/kubernetes-master/ kubernetes-master
# ln -s ~/dev/go/src/k8s.io/flanneld/ flanneld
# ln -s ~/dev/go/src/k8s.io/etcd/ etcd
# ln -s ~/dev/go/src/k8s.io/docker-registry-images/ docker-registry-images
# ln -s ~/dev/go/src/k8s.io/docker-registry-proxy/ docker-registry-proxy
# ln -s ~/dev/go/src/k8s.io/docker-install/ docker-install
# kubernetes-ui org
# ln -s ~/dev/go/src/k8s.io/label-selector/ label-selector
# ln -s ~/dev/go/src/k8s.io/object-describer/ object-describer
# ln -s ~/dev/go/src/k8s.io/container-terminal/ container-terminal
# ln -s ~/dev/go/src/k8s.io/topology-graph/ topology-graph
# ln -s ~/dev/go/src/k8s.io/graph/ graph
# ln -s ~/dev/go/src/k8s.io/kube-ui-docker/ kube-ui-docker
