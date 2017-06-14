#!/bin/sh
echo "All with map to (Unknown)"
./all.sh
echo "All without mapping"
./all_no_map.sh
echo "All with map to Domain *"
./all_with_map.sh

echo "Kubernetes/kubernetes commits in last year and each last 12 months"
./k8s_commits_in_ranges.sh

echo "Releases with map to (Unknown)"
./rels_strict.sh
echo "Releases without mapping"
./rels_no_map.sh
echo "Releases with map to Domain *"
./rels.sh
echo "Done mapping"

echo "Analysis All"
./analysis_all.sh
echo "Analysis Releases"
./analysis_rels.sh

echo "New devs"
./new_devs.sh

echo "Multi repos"
./kubernetes_repos.sh
