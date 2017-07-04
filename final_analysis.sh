#!/bin/sh
echo "Generate all.txt file and all_affs.csv"
./manual_all.sh

echo "Correlations"
./correlations.sh

echo "Enchance JSON"
./enchance_json.sh

echo "Aliaser"
./aliaser.sh

echo "Lookup JSON"
./lookup_json.sh

echo 'Progress Report'
./progress_report.sh

echo 'Done'

echo "vim all.txt all_affs.csv correlations.txt github_users.json aliaser.txt progress_report.txt"
