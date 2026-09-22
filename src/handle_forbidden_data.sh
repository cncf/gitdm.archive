#!/bin/sh
#find . -type f -iname "*.out" >> ./flist.txt
#find . -type f -iname "*.htm*" >> ./flist.txt
#find . -type f -iname "*.db" >> ./flist.txt
#find . -type f -iname "*.dump" >> ./flist.txt
#find . -type f -iname "*.dat" >> ./flist.txt
#find . -type f -iname "*.old" >> ./flist.txt
#find . -type f -iname "*.log" >> ./flist.txt
find . -type f -iname "*.csv" > ./flist.txt
find . -type f -iname "*.txt" >> ./flist.txt
find . -type f -iname "*.rb" >> ./flist.txt
find . -type f -iname "*.py" >> ./flist.txt
find . -type f -iname "*.md" >> ./flist.txt
find . -type f -iname "*.json" >> ./flist.txt
find . -type f -iname "*.sh" >> ./flist.txt
find . -type f -iname "*.go" >> ./flist.txt
find . -type f -iname "*.new" >> ./flist.txt
find ./cncf-config -type f >> ./flist.txt
find .. -iname "devel*.txt" >> ./flist.txt
find .. -iname "compan*.txt" >> ./flist.txt
#./handle_forbidden_data.rb `cat flist.txt`
./check_shas `cat flist.txt`
rm ./flist.txt
