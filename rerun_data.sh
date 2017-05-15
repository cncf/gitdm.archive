#!/bin/sh
echo "All with map to (Unknown)"
./all.sh
echo "All without mapping"
./all_no_map.sh
echo "All with map to Domain *"
./all_with_map.sh

echo "Releases with map to (Unknown)"
./rels_strict.sh
echo "Releases without mapping"
./rels_no_map.sh
echo "Releases with map to Domain *"
./rels.sh

echo "Multi repos"
./all_multirepos.sh
