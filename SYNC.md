# Syncing new affiliations

Make sure that you don't have different case email duplicates in `src/cncf-config/email-map`: `cd src`, `./lower_unique.sh cncf-config/email-map`.

1. If you generated new email-map using `./import_affs.sh`, then: `mv email-map cncf-config/email-map`.
2. To generate `git.log` file and make sure it includes all repos used by `devstats`. Use the final command line it generates. Make it `uniq`:
- On DevStats test master: `helm install devstats-test-debug ./devstats-helm --set skipSecrets=1,skipPVs=1,skipBackupsPV=1,skipBackups=1,skipProvisions=1,skipCrons=1,skipAffiliations=1,skipGrafanas=1,skipServices=1,skipIngress=1,skipStatic=1,skipNamespaces=1,skipPostgres=1,projectsOverride='+cncf\,+opencontainers\,+istio\,+zephyr\,+linux\,+rkt\,+sam\,+azf\,+riff\,+fn\,+openwhisk\,+openfaas\,+cii',bootstrapPodName=debug,bootstrapCommand=sleep,bootstrapCommandArgs={360000s}`.
- `../devstats-k8s-lf/util/pod_shell.sh debug`.
- `GHA2DB_EXTERNAL_INFO=1 GHA2DB_PROCESS_REPOS=1 GHA2DB_LOCAL=1 get_repos`.
- `helm delete devstats-test-debug`.
- `kubectl delete pod debug`.
3. To get LF repos use:
- `AWS_PROFILE=... KUBECONFIG=... helm2 install --name devstats-debug ./devstats-helm --set skipSecrets=1,skipPVs=1,skipProvisions=1,skipCrons=1,skipAffiliations=1,skipGrafanas=1,skipServices=1,skipNamespace=1,bootstrapPodName=debug,bootstrapCommand=sleep,bootstrapCommandArgs={36000s}`.
- `AWS_PROFILE=... KUBECONFIG=... ../devstats-k8s-lf/util/pod_shell.sh debug`.
- `ONLY='iovisor mininet opennetworkinglab opensecuritycontroller openswitch p4lang openbmp tungstenfabric cord' GHA2DB_PROPAGATE_ONLY_VAR=1 GHA2DB_EXTERNAL_INFO=1 GHA2DB_PROCESS_REPOS=1 GHA2DB_LOCAL=1 get_repos`.
- `AWS_PROFILE=... KUBECONFIG=... helm2 delete --purge devstats-debug`.
- `AWS_PROFILE=... KUBECONFIG=... kubectl delete po debug`.
4. Update `repos.txt` to contain all repositories returned by the above commands. Update `all_repos.sh` to include data from CNCF, CDF, LF and GraphQL. Run `./all_repos.sh`.
5. To run `cncf/gitdm` on a generated `git.log` file run: `cd src/; cp all_affs.csv all_affs.old; ~/dev/alt/gitdm/src/cncfdm.py -i git.log -r "^vendor/|/vendor/|^Godeps/" -R -n -b ./ -t -z -d -D -A -U -u -o all.txt -x all.csv -a all_affs.csv > all.out`. New approach is `./mtp` but it don't have a way (yet) to deal with the same emails mapped into different user names from different per-thread buckets.
6. Run: `./enchance_all_affs.sh`.
7. If updating via `ghusers.sh` or `ghusers_cached.sh` (step 8) - run `generate_actors.sh` too:
- LF actors: `AWS_PROFILE=... KUBECONFIG=... ./generate_actors_lf.sh`.
- CNCF, CDF and GraphQL actors: `KUBECONFIG=... ./generate_actors_nonlf.sh`.
- Concat: `./generate_actors_all.sh`, `./generate_actors_cncf.sh`.
8. Consider `./ghusers_cached.sh` or `./ghusers.sh` (if you run this, then copy result json somewhere and get 0-committers from previous version to save GH API points). Sometimes you should just run `./ghusers.sh` without cache.
9. Recommended: `./ghusers_partially_cached.sh 2> errors.txt` will refetch repos metadata and commits since last fetched and get users data from `github_users.json` so you can save a lot of API points. You can prepend with `NCPUS=N` to override autodetecting number of CPU cores available.
10. To copy source type from previous JSON version do `./copy_source.sh`, `./compare_sources.sh`.
11. Run `./company_names_mapping.sh` to fix typical company names spell errors, lower/upper case etc. Update `company-names-mapping` before running this (with a new typos/correlations data from the last 3 steps).
12. To update (enhance) `github_users.json` with new affiliations `[SHUFFLE=1] ./enhance_json.sh`. If you run `ghusers` you may need to update `skip_github_logins.txt` with new broken GitHub logins found. This is optional if you already have an enhanced json. You can prepend with `NCPUS=N` to override autodetecting number of CPU cores available.
13. To merge with previous JSON use: `./merge_jsons.sh`.
14. To merge multiple GitHub logins data (for example propagate known affiliation to unknown or not found on the same GitHub login) run: `./merge_github_logins.sh`.
15. Because this can find new affiliations you can now use `./import_from_github_users.sh` to import back from `github_users.json` and then `./lower_unique.sh cncf-config/email-map` and restart from step 5. This uses `company-names-mapping` file to import from GitHub `company` field.
16. Run `./correlations.sh` and examine its output `correlations.txt` to try to normalize company names and remove common suffixes like Ltd., Corp. and downcase/upcase differences.
17. Run `./check_spell` for fuzziness/spell check errors finder (uses Levenshtein distance to find bugs).
18. Run `./lookup_json.sh` and examine its output JSONs - those GitHub profiles have some useful data directly available - this will save you some manual research work.
19. *ALWAYS* before any commit to GitHub run: `./handle_forbidden_data.sh` to remove any forbiden affiliations, please also see `FORBIDDEN_DATA.md`.
20. You can use `./clear_affiliations_in_json.sh` to clear all affiliations on a generated `github_users.json`.
21. To make json unique, call `./unique_json.rb github_users.json`. To sort JSON by commits, login, email use: `./sort_json.rb github_users.json`.
22. You should run genderize/geousers/localize/agify (if needed) before the next step.
23. To generate human readable text affiliation files: first run: `./gen_aff_files.sh`.
24. You can create smaller final json for `cncf/devstats` using `./delete_json_fields.sh github_users.json; ./check_source.rb github_users.json; ./strip_json.sh github_users.json stripped.json; ONLY_AFF=1 ./strip_json.sh github_users.json affiliated.json; cp affiliated.json ~/dev/go/src/github.com/cncf/devstats/github_users.json`.
25. To generate final `unknowns.csv` manual research task file run: `./gen_aff_task.rb unknowns.txt`. You can also generate all actors `./gen_aff_task.rb alldevs.txt`. You can prepend with `ONLY_GH=1` to skip entries without GitHub. You can prepend with `ONLY_EMP=1` to skip entries with any affiliation already set. You can filter only specific entries, for example: `./filter_task.rb unknowns.txt unknown_with_linkedin.json unknowns_with_linkedin.txt`.
26. To manually edit all affiliations related files: edit `cncf-config/email-map all.txt all.csv all_affs.csv github_users.json stripped.json affiliated.json ../developers_affiliations.txt ../company_developers.txt affiliations.csv`
27. To add all possible entries from `github_users.json` to `cncf-config/email-map` use :`github_users_to_map.sh`. This is optional.
28. Finally copy `github_users.json` to `github_users.old`. You can check if JSON fileds are correct via `./check_json_fields.sh github_users.json`, `./check_json_fields.sh stripped.json small`, `./check_json_fields.sh affiliated.json small`.
29. If any file displays error with 'Invalid UTF-8' encoding, scrub it using Ruby tool: `./scrub.rb filename`.
30. To add user with 'xyz' GitHub id, use: `PG_PASS=... ./gh.rb xyz` - this will generate JSON entry that can be added to `github_users.json` after tweaking `email`, `source`, `affiliation` and possible some more fields.
31. To generate unknown CII committers create devstats-reports pod (see `cncf/devstats-helm`:`test/README.md`, search for `Create reports pod`), then run inside reports pod: `PG_DB=cii ./affs/unknown_committers.sh`, or `./affs/all_tasks.sh`.
32. Get [result CSV](https://teststats.cncf.io/backups/cii_unknown_committers.csv): `wget https://teststats.cncf.io/backups/argo_unknown_contributors.csv`.
33. Obsolete way to get unknown committers on the local database: `PG_PASS=... ./sh/unknown_committers.sh`.
34. Use `[KEYW=1] [FREQ=10000] [API_KEY=...] [SKIP_GDPR=1] PG_PASS=... ./unknown_committers.rb cii_unknown_committers.csv` to generate `task.csv` file to research CII committers. After this step you can also use `./top_to_task.rb` to generate `top_task.csv` (this converts Top N CSV output into the task.csv file, optional).
35. Use `./csv_merge.rb commits task.csv *_task.csv` to merge tasks generated for different projects, to create a file containing all those projects data sorted by contributions/commits desc.
36. Use `[SHUFFLE=1] ./ensure_emails.rb github_users.json` to ensure that most up-to-date GitHub users emails are present (this will query all GitHub logins so can take even a day to finish on 300k+ JSON).
37. Use `OUT=fn.csv ./merge_affs_csvs.rb csvfile1.csv csvfile2.csv ...` to merge multiple CSVs to import.
38. Use `[SKIP_JSON=1] ./affs_analysis.rb filename.csv` to analyse committers/commits affiliated/independent/unknown stats.
39. To validate `github_user.json` matches `cncf-config/email-map` use: `./email_map_2_github_users.rb`.


# Example command generated by `cncf/devstats/get_repos`:

- `./all_repos_log.sh /root/devstats_repos/Azure/* /root/devstats_repos/BuoyantIO/* /root/devstats_repos/GoogleCloudPlatform/* /root/devstats_repos/OpenBMP/* /root/devstats_repos/OpenObservability/* /root/devstats_repos/RichiH/* /root/devstats_repos/Virtual-Kubelet/* /root/devstats_repos/alibaba/* /root/devstats_repos/apcera/* /root/devstats_repos/appc/* /root/devstats_repos/brigadecore/* /root/devstats_repos/buildpack/* /root/devstats_repos/cdfoundation/* /root/devstats_repos/cloudevents/* /root/devstats_repos/cncf/* /root/devstats_repos/containerd/* /root/devstats_repos/containernetworking/* /root/devstats_repos/coredns/* /root/devstats_repos/coreos/* /root/devstats_repos/cortexproject/* /root/devstats_repos/cri-o/* /root/devstats_repos/crosscloudci/* /root/devstats_repos/datawire/* /root/devstats_repos/docker/* /root/devstats_repos/dragonflyoss/* /root/devstats_repos/draios/* /root/devstats_repos/envoyproxy/* /root/devstats_repos/etcd-io/* /root/devstats_repos/facebook/* /root/devstats_repos/falcosecurity/* /root/devstats_repos/fluent/* /root/devstats_repos/goharbor/* /root/devstats_repos/graphql/* /root/devstats_repos/grpc/* /root/devstats_repos/helm/* /root/devstats_repos/iovisor/* /root/devstats_repos/istio/* /root/devstats_repos/jaegertracing/* /root/devstats_repos/jenkins-x/* /root/devstats_repos/jenkinsci/* /root/devstats_repos/knative/* /root/devstats_repos/kubeedge/* /root/devstats_repos/kubernetes-client/* /root/devstats_repos/kubernetes-csi/* /root/devstats_repos/kubernetes-graveyard/* /root/devstats_repos/kubernetes-helm/* /root/devstats_repos/kubernetes-incubator-retired/* /root/devstats_repos/kubernetes-incubator/* /root/devstats_repos/kubernetes-retired/* /root/devstats_repos/kubernetes-security/* /root/devstats_repos/kubernetes-sig-testing/* /root/devstats_repos/kubernetes-sigs/* /root/devstats_repos/kubernetes/* /root/devstats_repos/ligato/* /root/devstats_repos/linkerd/* /root/devstats_repos/lyft/* /root/devstats_repos/miekg/* /root/devstats_repos/mininet/* /root/devstats_repos/nats-io/* /root/devstats_repos/networkservicemesh/* /root/devstats_repos/open-policy-agent/* /root/devstats_repos/open-switch/* /root/devstats_repos/open-telemetry/* /root/devstats_repos/opencontainers/* /root/devstats_repos/opencord/* /root/devstats_repos/openebs/* /root/devstats_repos/openeventing/* /root/devstats_repos/opennetworkinglab/* /root/devstats_repos/opensecuritycontroller/* /root/devstats_repos/opentracing/* /root/devstats_repos/p4lang/* /root/devstats_repos/pingcap/* /root/devstats_repos/prometheus/* /root/devstats_repos/rkt/* /root/devstats_repos/rktproject/* /root/devstats_repos/rook/* /root/devstats_repos/spiffe/* /root/devstats_repos/spinnaker/* /root/devstats_repos/tektoncd/* /root/devstats_repos/telepresenceio/* /root/devstats_repos/theupdateframework/* /root/devstats_repos/tikv/* /root/devstats_repos/torvalds/* /root/devstats_repos/tungstenfabric/* /root/devstats_repos/uber/* /root/devstats_repos/virtual-kubelet/* /root/devstats_repos/vitessio/* /root/devstats_repos/vmware/* /root/devstats_repos/weaveworks/* /root/devstats_repos/youtube/* /root/devstats_repos/zephyrproject-rtos/*`.


# To sync maintainers:

1. Open [CNCF projects maintainers list](https://docs.google.com/spreadsheets/d/1Pr8cyp8RLrNGx9WBAgQvBzUUmqyOv69R7QAFKhacJEM/edit#gid=262035321) 
2. Save "Name", "Company", "GitHub name" columns to a new sheet and download it as "maintainers.csv".
3. Add "name,company,login" CSV header.
4. Example [file](https://docs.google.com/spreadsheets/d/1QShmHcStYh5BjTjdOAASFK9V4WaYwJSFu1maBdcV5YA/edit#gid=0)
5. Run `[DBG=1] [ONLYNEW=1] ./maintainers.sh` script. Follow its instructions.
6. Run `[DBG=1] ./check_maintainers.sh`. Follow its instructions.


# Add new project (cncf or non-cncf) to get affiliation for it.

Please follow the instructions from [ADD_PROJECT.md](https://github.com/cncf/gitdm/blob/master/ADD_PROJECT.md).


# Geodata and gender

To add geo data (`country_id`, `tz`) and gender data (`sex`, `sex_prob`), do the following:
- Download `allCountries.zip` file from geonames server[](http://download.geonames.org/export/dump/): `wget http://download.geonames.org/export/dump/allCountries.zip`.
- Create `geonames` database via: `sudo -u postgres createdb geonames`, `sudo -u postgres psql geonames -f geonames.sql` or `[PGPASSWORD=...] psql -Upostgres geonames -f geonames.sql`. Table details in `geonames.info`
- Create `gha_admin` role via `sudo -u postgres -c "create role gha_admin login password 'xyz'"`.
- Unzip `unzip allCountries.zip` and run `PG_PASS=... ./geodata.sh allCountries.txt` - this will populate the DB.
- Create indices on columns to speedup localization: `sudo -u postgres psql geonames -f geonames_idx.sql`.
- Make sure that you don't have any `nil`, `null` and `false` values saved in any `*_cache.json` file (those files are also saved when you `CTRL^C` running enchancement).
- Regexp to search is `/ \(null\|nil\|false\)\(\n\|,\) `, but `agify_cache.json` and `genderize_cache.json` can have `null` so search only for `false` and `nil`: `/ \(nil\|false\)\(\n\|,\)`.
- If this is a first geousers run create `geousers_cache.json` via `cp empty.json geousers_cache.json`.
- To use cache it is best to have `stripped.json` from the previous run. See step 24.
- Enchance `github_users.json` via `SHUFFLE=1 PG_PASS=... ./geousers.sh github_users.json stripped.json geousers_cache.json 20000`. It will add `country_id` and `tz` fields.
- Go to [store.genderize.io](https://store.genderize.io) and get you `API_KEY`, basic subscription ($9) allows 100,000 monthly gender lookups.
- If this is a first genderize run create `genderize_cache.json` via `cp empty.json genderize_cache.json`.
- Enchance `github_users.json` via `SHUFFLE=1 PG_PASS=... API_KEY=... ./nationalize.sh github_users.json stripped.json nationalize_cache.json 20000`. It will eventually fill missing `country_id` and `tz` fields.
- Enchance `github_users.json` via `SHUFFLE=1 API_KEY=... ./genderize.sh github_users.json stripped.json genderize_cache.json 20000`. It will add `sex` and `sex_prob` fields.
- Enchance `github_users.json` via `SHUFFLE=1 API_KEY=... ./agify.sh github_users.json stripped.json agify_cache.json 20000`. It will add `age` field.
- You can skip `API_KEY=...` but only 1000 gender lookups/day are allowed then.
- Copy enhanced json to devstats: `ONLY_AFF=1 ./strip_json.sh github_users.json affiliated.json; cp affiliated.json ~/dev/go/src/github.com/cncf/devstats/github_users.json`.
- Import new json on devstats using `./import_affs` tool.


# Manual affiliations

- To import manual affiliations from a google sheet save this sheet as `affiliations.csv` and then use `./affiliations.sh` script.
- Prepend with `UPDATE=1` to only import those marked as changed: column `changes='x'`.
- Prepend with `RECHECK=1` to always ask for operation and allow updating found -> not found.
- Prepend with `DBG=1` to enable verbose output.
- After finishing import add a status line to `affiliations_import.txt` file and update the online spreadsheet.
- Update `company-names-mapping` if needed and then run `./company_names_mapping.sh`.
- Run: `./sort_config.sh` and `./lower_unique.sh cncf-config/email-map`.
- Run: `./enchance_all_affs.sh`, then follow its suggestions about search and check, then (remove csv header): `cat new_affs.csv >> all_affs.csv`, `./lower_unique.sh all_affs.csv`.
- Finall: `cp all_affs.csv all_affs.old`.
- After importing new data run `./src/burndown.sh 2018-08-22` (from the src's parent directory). Do this after processing all data mentioned here, not after just importing new CSV.
- Import generated `csv/burndown.csv` data into `https://docs.google.com/spreadsheets/d/1RxEbZNefBKkgo3sJ2UQz0OCA91LDOopacQjfFBRRqhQ/edit?usp=sharing`.
- To calculate CNCF/LF ratio use number of CNCF found from last commit - number of CNCF found from some previous commit diveded by the same ratio for all actors.


# Acquisitions

- You can do a company acquisition on a specific dae via something like: `ruby acquire_company.rb 'Old Company' 'YYYY-MM-DD' 'New Company'`


# Complex PRs post merge

For complex merges that modify `developers_affiliationsN.txt` file(s) do the following:

- Copy PR modifications and save them in `pr_data.txt`.
- Run `pr_data_to_csv.sh; cat new_affs.csv >> all_affs.csv; ./sort_configs.sh`.
- Run `PG_PASS=... ./unknown_committers.rb pr_unknowns.csv`.
- Run `mv pr_data.csv affiliations.csv; ./affiliations.sh`.

Alternative way using diff (for simple PRs that only add new users):

- Merge a PR from GitHub UI, then `git pull`.
- `git diff HEAD^ ../*.txt > input.diff`.
- `PG_PASS=... ./update_from_pr_diff.rb ./input.diff github_users.json cncf-config/email-map`.
- `./post_manual_checks.sh && ./post_manual_updates.sh`.


# Update JSON contributions count

- Run `./login_contributions.sh` on any DevStats kubernetes node (you need DevStats DB access).
- Download `login_contributions.csv` from that node.
- Check for forbiden users: `./check_shas login_contributions.csv`.
- Run `./update_login_contributions.rb` to update `github_users.json` file.
- Run `FULL=1 ./post_manual_checks.sh && ./post_manual_updates.sh`.
