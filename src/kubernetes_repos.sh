#!/bin/sh

echo "Clearing old repos"
rm -f repos/*

echo "Each repository analysis"
for file in ~/dev/kubernetes_repos/*
do
    dir=$(basename $file)
    echo "Analysis $dir"
    ./anyrepo.sh $file $dir
done

echo "All repos combined"
./multirepo.sh ~/dev/kubernetes_repos/*
echo "All repos analysis"
./analysis_all_repos.sh

echo "TopDevs, google others and unknowns"
./topdevs.sh

echo "Merged file"
cat repos/*.txt > repos/merged.out
echo "All done"
