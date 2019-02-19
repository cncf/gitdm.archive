#!/bin/sh
ruby gen_aff_files.rb all_affs.csv
ruby split_file.rb ../company_developers.txt ../developers_affiliations.txt
