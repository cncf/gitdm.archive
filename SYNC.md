Syncing new affiliations

1. If you generated new email-map using `./import_affs.sh`, then: `mv email-map cncf-config/email-map`
2. To generate `git.log` file and make sure it includes all orgs used by `devstats` use cncf/devstats\'s `PG_PASS=... GHA2DB_EXTERNAL_INFO=1 GHA2DB_PROCESS_REPOS=1 ./get_repos` and then final command line it generates.
3. To run `cncf/gitdm` on a generated `git.log` file do: `~/dev/alt/gitdm/cncfdm.py -i git.log -r "^vendor/|/vendor/|^Godeps/" -R -n -b ./ -t -z -d -D -U -u -o all.txt -x all.csv -a all_affs.csv > all.out`
4. To generate human readable text affiliation files: `SKIP_COMPANIES="(Unknown)" ./gen_aff_files.sh`
5. If updating via `ghusers.sh` or `ghusers_cached.sh` (step 6) - run `generate_actors.sh` too.
5. Consider `./ghusers_cached.sh` or `./ghusers.sh` (if you run this, then copy result json somewhere and get 0-committers from previous version to save GH API points). Sometimes you should just run ./ghusers.sh without cache.
6. To update (enchance) `github_users.json` with new affiliations `./enchance_json.sh` or alternatively regenerate ALL data `./rerun_all.sh`.
7. *ALWAYS* before any commit to GitHub run: `./handle_forbidden_data.sh` to remove any forbiden affiliations, please also see `FORBIDDEN_DATA.md`.
