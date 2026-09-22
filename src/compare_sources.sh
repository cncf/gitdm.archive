#!/bin/bash
for t in config domain manual user user_manual
do
  c=`cat github_users.json | grep "\"source\": \"${t}\"" | wc -l`
  o=`cat github_users.old | grep "\"source\": \"${t}\"" | wc -l`
  d=$((c - o))
  printf "%-12s new=%-8d old=%-8d diff=%-8d\n" "$t" "$c" "$o" "$d"
done
