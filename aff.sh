#!/bin/sh
ruby aff.rb repos/combined.csv Email Date Affliation
mv affs.csv stats/all_devs_gitdm.csv
ruby aff.rb facade_kubernetes.csv 'Author Email' 'Author Date' 'Author Affiliation'
mv affs.csv stats/all_devs_facade.csv
