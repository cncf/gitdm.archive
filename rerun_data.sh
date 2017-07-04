#!/bin/sh
echo "Consider running: pull_kubernetes.sh, update_all_repos.sh and manually check ~/dev/go/src/k8s.io/kubernetes/ (rebase.sh there)"
echo "Update PULL_DATE after this, and update datasheet dates and report dates to PULL_DATE"
echo "Also update last_processed.txt with last processed unknown/not found affliation from repos/combined.txt"
rm -f ./other_repos/*
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

echo "Final analysis"
./final_analysis.sh
