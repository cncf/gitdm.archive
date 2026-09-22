#!/bin/bash
if ( [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] )
then
  echo "Usage: $0 unknowns.csv affiliations.csv merged.csv"
  exit 1
fi
ruby merge_csvs.rb "$1" "$2" "$3"
