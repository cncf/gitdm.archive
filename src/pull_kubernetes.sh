#!/bin/sh
cd ~/dev/kubernetes_repos || exit 1
for file in *
do
    echo "$file"
    cd $file || exit 2
    git pull || exit 3
    cd ~/dev/kubernetes_repos
done
echo "All Kubernetes repos pulled/updated"
