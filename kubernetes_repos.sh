#!/bin/sh
# kubernetes org
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
./anyrepo.sh ~/dev/go/src/k8s.io/kubeadm/ kubeadm
# kubernetes-incubator org
./anyrepo.sh ~/dev/go/src/k8s.io/kompose/ kompose
./anyrepo.sh ~/dev/go/src/k8s.io/external-storage/ external-storage
./anyrepo.sh ~/dev/go/src/k8s.io/cri-tools/ cri-tools
./anyrepo.sh ~/dev/go/src/k8s.io/kube-aws/ kube-aws
./anyrepo.sh ~/dev/go/src/k8s.io/external-dns/ external-dns
./anyrepo.sh ~/dev/go/src/k8s.io/bootkube/ bootkube
./anyrepo.sh ~/dev/go/src/k8s.io/service-catalog/ service-catalog
./anyrepo.sh ~/dev/go/src/k8s.io/kargo/ kargo
./anyrepo.sh ~/dev/go/src/k8s.io/cri-o/ cri-o
./anyrepo.sh ~/dev/go/src/k8s.io/cri-containerd/ cri-containerd
./anyrepo.sh ~/dev/go/src/k8s.io/apiserver-builder/ apiserver-builder
./anyrepo.sh ~/dev/go/src/k8s.io/ip-masq-agent/ ip-masq-agent
./anyrepo.sh ~/dev/go/src/k8s.io/client-python/ client-python
./anyrepo.sh ~/dev/go/src/k8s.io/cluster-capacity/ cluster-capacity
./anyrepo.sh ~/dev/go/src/k8s.io/reference-docs/ reference-docs
./anyrepo.sh ~/dev/go/src/k8s.io/kube-mesos-framework/ kube-mesos-framework
./anyrepo.sh ~/dev/go/src/k8s.io/rktlet/ rktlet
./anyrepo.sh ~/dev/go/src/k8s.io/spartakus/ spartakus
./anyrepo.sh ~/dev/go/src/k8s.io/cluster-proportional-autoscaler/ cluster-proportional-autoscaler
./anyrepo.sh ~/dev/go/src/k8s.io/nfs-provisioner/ nfs-provisioner
./anyrepo.sh ~/dev/go/src/k8s.io/node-feature-discovery/ node-feature-discovery
./anyrepo.sh ~/dev/go/src/k8s.io/application-images/ application-images
# kubernetes-client org
./anyrepo.sh ~/dev/go/src/k8s.io/java/ java
./anyrepo.sh ~/dev/go/src/k8s.io/gen/ gen
./anyrepo.sh ~/dev/go/src/k8s.io/python-base/ python-base
./anyrepo.sh ~/dev/go/src/k8s.io/csharp/ csharp
./anyrepo.sh ~/dev/go/src/k8s.io/ruby/ ruby
./anyrepo.sh ~/dev/go/src/k8s.io/javascript/ javascript
# community --> kubernetes-client-community (renamed due to name conflict)
./anyrepo.sh ~/dev/go/src/k8s.io/kubernetes-client-community/ kubernetes-client-community
./anyrepo.sh ~/dev/go/src/k8s.io/go-base/ go-base
./anyrepo.sh ~/dev/go/src/k8s.io/go/ go
# kubernetes-contrib org
# application-images --> kubernetes-contrib-application-images (renamed due to name conflict)
./anyrepo.sh ~/dev/go/src/k8s.io/kubernetes-contrib-application-images/ kubernetes-contrib-application-images
./anyrepo.sh ~/dev/go/src/k8s.io/jumpserver/ jumpserver
./anyrepo.sh ~/dev/go/src/k8s.io/graylog2/ graylog2
./anyrepo.sh ~/dev/go/src/k8s.io/consul/ consul
# kubernetes-cluster-automation org
./anyrepo.sh ~/dev/go/src/k8s.io/docker-registry/ docker-registry 
./anyrepo.sh ~/dev/go/src/k8s.io/kubernetes-minion/ kubernetes-minion 
./anyrepo.sh ~/dev/go/src/k8s.io/kubernetes-master/ kubernetes-master
./anyrepo.sh ~/dev/go/src/k8s.io/flanneld/ flanneld
./anyrepo.sh ~/dev/go/src/k8s.io/etcd/ etcd
./anyrepo.sh ~/dev/go/src/k8s.io/docker-registry-images/ docker-registry-images
./anyrepo.sh ~/dev/go/src/k8s.io/docker-registry-proxy/ docker-registry-proxy
./anyrepo.sh ~/dev/go/src/k8s.io/docker-install/ docker-install
# kubernetes-ui org
./anyrepo.sh ~/dev/go/src/k8s.io/label-selector/ label-selector
./anyrepo.sh ~/dev/go/src/k8s.io/object-describer/ object-describer
./anyrepo.sh ~/dev/go/src/k8s.io/container-terminal/ container-terminal
./anyrepo.sh ~/dev/go/src/k8s.io/topology-graph/ topology-graph
./anyrepo.sh ~/dev/go/src/k8s.io/graph/ graph
./anyrepo.sh ~/dev/go/src/k8s.io/kube-ui-docker/ kube-ui-docker

echo "All repos combined"
./multirepo.sh ~/dev/go/src/k8s.io/test-infra/ ~/dev/go/src/k8s.io/kubernetes/ ~/dev/go/src/k8s.io/kubernetes.github.io/ ~/dev/go/src/k8s.io/contrib/ ~/dev/go/src/k8s.io/helm/ ~/dev/go/src/k8s.io/kops/ ~/dev/go/src/k8s.io/community/ ~/dev/go/src/k8s.io/heapster/ ~/dev/go/src/k8s.io/dashboard/ ~/dev/go/src/k8s.io/minikube/ ~/dev/go/src/k8s.io/charts/ ~/dev/go/src/k8s.io/kube-state-metrics/ ~/dev/go/src/k8s.io/kubernetes-anywhere/ ~/dev/go/src/k8s.io/ingress/ ~/dev/go/src/k8s.io/release/ ~/dev/go/src/k8s.io/gengo/ ~/dev/go/src/k8s.io/autoscaler/ ~/dev/go/src/k8s.io/dns/ ~/dev/go/src/k8s.io/sample-apiserver/ ~/dev/go/src/k8s.io/apiserver/ ~/dev/go/src/k8s.io/kube-aggregator/ ~/dev/go/src/k8s.io/client-go/ ~/dev/go/src/k8s.io/node-problem-detector/ ~/dev/go/src/k8s.io/perf-tests/ ~/dev/go/src/k8s.io/apimachinery/ ~/dev/go/src/k8s.io/frakti/ ~/dev/go/src/k8s.io/features/ ~/dev/go/src/k8s.io/repo-infra/ ~/dev/go/src/k8s.io/kube-deploy/ ~/dev/go/src/k8s.io/examples/ ~/dev/go/src/k8s.io/git-sync/ ~/dev/go/src/k8s.io/k8s.io/ ~/dev/go/src/k8s.io/kubernetes-bootcamp/ ~/dev/go/src/k8s.io/kubectl/ ~/dev/go/src/k8s.io/metrics/ ~/dev/go/src/k8s.io/md-check/ ~/dev/go/src/k8s.io/kubernetes-template-project/ ~/dev/go/src/k8s.io/kubernetes-docs-cn/ ~/dev/go/src/k8s.io/kube-ui/ ~/dev/go/src/k8s.io/kubeadm/ ~/dev/go/src/k8s.io/kompose/ ~/dev/go/src/k8s.io/external-storage/ ~/dev/go/src/k8s.io/cri-tools/ ~/dev/go/src/k8s.io/kube-aws/ ~/dev/go/src/k8s.io/external-dns/ ~/dev/go/src/k8s.io/bootkube/ ~/dev/go/src/k8s.io/service-catalog/ ~/dev/go/src/k8s.io/kargo/ ~/dev/go/src/k8s.io/cri-o/ ~/dev/go/src/k8s.io/cri-containerd/ ~/dev/go/src/k8s.io/apiserver-builder/ ~/dev/go/src/k8s.io/ip-masq-agent/ ~/dev/go/src/k8s.io/client-python/ ~/dev/go/src/k8s.io/cluster-capacity/ ~/dev/go/src/k8s.io/reference-docs/ ~/dev/go/src/k8s.io/kube-mesos-framework/ ~/dev/go/src/k8s.io/rktlet/ ~/dev/go/src/k8s.io/spartakus/ ~/dev/go/src/k8s.io/cluster-proportional-autoscaler/ ~/dev/go/src/k8s.io/nfs-provisioner/ ~/dev/go/src/k8s.io/node-feature-discovery/ ~/dev/go/src/k8s.io/application-images/ ~/dev/go/src/k8s.io/java/ ~/dev/go/src/k8s.io/gen/ ~/dev/go/src/k8s.io/python-base/ ~/dev/go/src/k8s.io/csharp/ ~/dev/go/src/k8s.io/ruby/ ~/dev/go/src/k8s.io/javascript/ ~/dev/go/src/k8s.io/kubernetes-client-community/ ~/dev/go/src/k8s.io/go-base/ ~/dev/go/src/k8s.io/go/ ~/dev/go/src/k8s.io/kubernetes-contrib-application-images/ ~/dev/go/src/k8s.io/jumpserver/ ~/dev/go/src/k8s.io/graylog2/ ~/dev/go/src/k8s.io/consul/ ~/dev/go/src/k8s.io/docker-registry/ ~/dev/go/src/k8s.io/kubernetes-minion/ ~/dev/go/src/k8s.io/kubernetes-master/ ~/dev/go/src/k8s.io/flanneld/ ~/dev/go/src/k8s.io/etcd/ ~/dev/go/src/k8s.io/docker-registry-images/ ~/dev/go/src/k8s.io/docker-registry-proxy/ ~/dev/go/src/k8s.io/docker-install/ ~/dev/go/src/k8s.io/label-selector/ ~/dev/go/src/k8s.io/object-describer/ ~/dev/go/src/k8s.io/container-terminal/ ~/dev/go/src/k8s.io/topology-graph/ ~/dev/go/src/k8s.io/graph/ ~/dev/go/src/k8s.io/kube-ui-docker/
echo "TopDevs, google others and unknowns"
./topdevs.sh

echo "Merged file"
cat repos/*.txt > repos/merged.out

