#!/bin/bash
cat actors_nonlf.txt > actors_cncf.txt
cat actors_cncf.txt | sort | uniq > out && mv out actors_cncf.txt
./scrub.rb actors_cncf.txt
cat actors_cncf.txt | sort | uniq > actors.tmp
tr '\n' ',' < actors.tmp > out
rm actors.tmp
mv out actors_cncf.txt
truncate -s-1 actors_cncf.txt
./scrub.rb actors_cncf.txt
