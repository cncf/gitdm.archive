#!/bin/sh
cd ~/dev/prometheus || exit 1
for file in *
do
    echo "$file"
    cd $file || exit 2
    git pull || exit 3
    cd ~/dev/prometheus
done
echo "All prometheus repos pulled/updated"
