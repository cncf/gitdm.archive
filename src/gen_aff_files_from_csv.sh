#!/bin/sh
ruby gen_aff_files_from_csv.rb all_affs.csv
ruby split_file.rb ../company_developers.txt ../developers_affiliations.txt
rm ../developers_affiliations.txt ../company_developers.txt
