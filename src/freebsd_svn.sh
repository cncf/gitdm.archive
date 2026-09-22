#!/bin/sh
echo "Args date-from date-to"
cd ~/dev/freebsd/
> svn.log
for file in base doc ports
do
    cd $file
    echo "$file"
    svn log -q -r {$1}:{$2} | sed '/^-/ d' >> ../svn.log
    ls -l ../svn.log
    cd ..
done
cd ~/dev/freebsd/
echo "Revisions: `cat svn.log | cut -f 1 -d "|" | sort | uniq | wc -l`"
echo "Authors: `cat svn.log | cut -f 2 -d "|" | sort | uniq | wc -l`"
