#!/bin/sh
echo "Per file analysis - kubernetes all time..."
./per_dirs_all.sh 

echo "Per releases..."
./per_dirs_rel.sh v1.0.0 v1.1.0
./per_dirs_rel.sh v1.1.0 v1.2.0
./per_dirs_rel.sh v1.2.0 v1.3.0
./per_dirs_rel.sh v1.3.0 v1.4.0
./per_dirs_rel.sh v1.4.0 v1.5.0
./per_dirs_rel.sh v1.5.0 v1.6.0
./per_dirs_rel.sh v1.6.0 v1.7.0

echo "File stats analysis..."
./filestats.sh
echo "Done."
