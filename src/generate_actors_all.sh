#!/bin/bash
cat actors_nonlf.txt actors_lf.txt > actors.txt
cat actors.txt | sort | uniq > out && mv out actors.txt
./scrub.rb actors.txt
cat actors.txt | sort | uniq > actors.tmp
tr '\n' ',' < actors.tmp > out
rm actors.tmp
mv out actors.txt
truncate -s-1 actors.txt
./scrub.rb actors.txt
