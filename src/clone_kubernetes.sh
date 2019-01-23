#!/bin/sh
mkdir ~/dev/kubernetes_repos 2>/dev/null
# This list is from `cncf/velocity`:`BigQuery/query_cncf_repos.sql`
cd ~/dev/kubernetes_repos || exit 1
# kubernetes org
git clone https://github.com/kubernetes/test-infra.git || exit 1
git clone https://github.com/kubernetes/kubernetes.git || exit 1
git clone https://github.com/kubernetes/kubernetes.github.io.git || exit 1
git clone https://github.com/kubernetes/contrib.git || exit 1
git clone https://github.com/kubernetes/helm.git || exit 1
git clone https://github.com/kubernetes/kops.git || exit 1
git clone https://github.com/kubernetes/community.git || exit 1
git clone https://github.com/kubernetes/heapster.git || exit 1
git clone https://github.com/kubernetes/dashboard.git || exit 1
git clone https://github.com/kubernetes/minikube.git || exit 1
git clone https://github.com/kubernetes/charts.git || exit 1
git clone https://github.com/kubernetes/kube-state-metrics.git || exit 1
git clone https://github.com/kubernetes/kubernetes-anywhere.git || exit 1
git clone https://github.com/kubernetes/ingress.git || exit 1
git clone https://github.com/kubernetes/release.git || exit 1
git clone https://github.com/kubernetes/gengo.git || exit 1
git clone https://github.com/kubernetes/autoscaler.git || exit 1
git clone https://github.com/kubernetes/dns.git || exit 1
git clone https://github.com/kubernetes/sample-apiserver.git || exit 1
git clone https://github.com/kubernetes/apiserver.git || exit 1
git clone https://github.com/kubernetes/kube-aggregator.git || exit 1
git clone https://github.com/kubernetes/client-go.git || exit 1
git clone https://github.com/kubernetes/node-problem-detector.git || exit 1
git clone https://github.com/kubernetes/perf-tests.git || exit 1
git clone https://github.com/kubernetes/apimachinery.git || exit 1
git clone https://github.com/kubernetes/frakti.git || exit 1
git clone https://github.com/kubernetes/features.git || exit 1
git clone https://github.com/kubernetes/repo-infra.git || exit 1
git clone https://github.com/kubernetes/kube-deploy.git || exit 1
git clone https://github.com/kubernetes/examples.git || exit 1
git clone https://github.com/kubernetes/git-sync.git || exit 1
git clone https://github.com/kubernetes/k8s.io.git || exit 1
git clone https://github.com/kubernetes/kubernetes-bootcamp.git || exit 1
git clone https://github.com/kubernetes/kubectl.git || exit 1
git clone https://github.com/kubernetes/metrics.git || exit 1
git clone https://github.com/kubernetes/md-check.git || exit 1
git clone https://github.com/kubernetes/kubernetes-template-project.git || exit 1
git clone https://github.com/kubernetes/kubernetes-docs-cn.git || exit 1
git clone https://github.com/kubernetes/kube-ui.git || exit 1
git clone https://github.com/kubernetes/kubeadm.git || exit 1
# new (updated 2017-09-26)
git clone https://github.com/kubernetes/federation.git || exit 1
git clone https://github.com/kubernetes/cluster-registry.git || exit 1
git clone https://github.com/kubernetes/steering.git || exit 1
git clone https://github.com/kubernetes/code-generator.git || exit 1
git clone https://github.com/kubernetes/sig-release.git || exit 1
git clone https://github.com/kubernetes/kube-openapi.git || exit 1
git clone https://github.com/kubernetes/utils.git || exit 1
git clone https://github.com/kubernetes/apiextensions-apiserver.git || exit 1
git clone https://github.com/kubernetes/api.git || exit 1
# kubernetes-incubator org
git clone https://github.com/kubernetes-incubator/kompose.git || exit 1
git clone https://github.com/kubernetes-incubator/external-storage.git || exit 1
git clone https://github.com/kubernetes-incubator/cri-tools.git || exit 1
git clone https://github.com/kubernetes-incubator/kube-aws.git || exit 1
git clone https://github.com/kubernetes-incubator/external-dns.git || exit 1
git clone https://github.com/kubernetes-incubator/bootkube.git || exit 1
git clone https://github.com/kubernetes-incubator/service-catalog.git || exit 1
git clone https://github.com/kubernetes-incubator/kargo.git || exit 1
git clone https://github.com/kubernetes-incubator/cri-o.git || exit 1
git clone https://github.com/kubernetes-incubator/cri-containerd.git || exit 1
git clone https://github.com/kubernetes-incubator/apiserver-builder.git || exit 1
git clone https://github.com/kubernetes-incubator/ip-masq-agent.git || exit 1
git clone https://github.com/kubernetes-incubator/client-python.git || exit 1
git clone https://github.com/kubernetes-incubator/cluster-capacity.git || exit 1
git clone https://github.com/kubernetes-incubator/reference-docs.git || exit 1
git clone https://github.com/kubernetes-incubator/kube-mesos-framework.git || exit 1
git clone https://github.com/kubernetes-incubator/rktlet.git || exit 1
git clone https://github.com/kubernetes-incubator/spartakus.git || exit 1
git clone https://github.com/kubernetes-incubator/cluster-proportional-autoscaler.git || exit 1
git clone https://github.com/kubernetes-incubator/nfs-provisioner.git || exit 1
git clone https://github.com/kubernetes-incubator/node-feature-discovery.git || exit 1
git clone https://github.com/kubernetes-incubator/application-images.git || exit 1
# new (updated 2017-09-26)
git clone https://github.com/kubernetes-incubator/cluster-proportional-vertical-autoscaler.git || exit 1
git clone https://github.com/kubernetes-incubator/descheduler.git || exit 1
git clone https://github.com/kubernetes-incubator/rescheduler.git || exit 1
git clone https://github.com/kubernetes-incubator/kube-arbitrator.git || exit 1
git clone https://github.com/kubernetes-incubator/metrics-server.git || exit 1
# kubernetes-client org
git clone https://github.com/kubernetes-client/java.git || exit 1
git clone https://github.com/kubernetes-client/gen.git || exit 1
git clone https://github.com/kubernetes-client/python-base.git || exit 1
git clone https://github.com/kubernetes-client/csharp.git || exit 1
git clone https://github.com/kubernetes-client/ruby.git || exit 1
git clone https://github.com/kubernetes-client/javascript.git || exit 1
mv community kubernetes_community
git clone https://github.com/kubernetes-client/community.git || exit 1
git clone https://github.com/kubernetes-client/go-base.git || exit 1
git clone https://github.com/kubernetes-client/go.git || exit 1
# new (updated 2017-09-26)
git clone https://github.com/kubernetes-client/typescript.git || exit 1
# kubernetes-helm org
git clone https://github.com/kubernetes-helm/chartmuseum.git || exit 1
git clone https://github.com/kubernetes-helm/monocular.git || exit 1
git clone https://github.com/kubernetes-helm/rudder-federation.git || exit 1
mv community kubernetes_client_community
git clone https://github.com/kubernetes-helm/community.git || exit 1
echo "All Kubernetes repos cloned"
