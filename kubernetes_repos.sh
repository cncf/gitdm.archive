#!/bin/sh
#community heapster dashboard minikube
./multirepo.sh ~/dev/go/src/k8s.io/test-infra/ ~/dev/go/src/k8s.io/kubernetes/ ~/dev/go/src/k8s.io/kubernetes.github.io/ ~/dev/go/src/k8s.io/contrib/ ~/dev/go/src/k8s.io/helm/ ~/dev/go/src/k8s.io/kops/
./anyrepo.sh ~/dev/go/src/k8s.io/test-infra/ test-infra
./anyrepo.sh ~/dev/go/src/k8s.io/kubernetes/ kubernetes
./anyrepo.sh ~/dev/go/src/k8s.io/kubernetes.github.io/ kubernetes.github.io
./anyrepo.sh ~/dev/go/src/k8s.io/contrib/ contrib
./anyrepo.sh ~/dev/go/src/k8s.io/helm/ helm
./anyrepo.sh ~/dev/go/src/k8s.io/kops/ kops
