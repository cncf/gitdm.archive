#!/bin/sh
echo "Done mapping"
echo "Analysis All"
./analysis_all.sh
echo "Analysis Releases"
./analysis_rels.sh

echo "Kubernetes repos"
./kubernetes_repos.sh

echo "TopDevs, google others and unknowns"
./topdevs.sh

echo "All done."
