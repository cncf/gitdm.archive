# Generate research recent unknown contributors task:

- On the `prod` node run: `helm install devstats-prod-reports ./devstats-helm --set skipSecrets=1,skipPVs=1,skipBackupsPV=1,skipVacuum=1,skipBackups=1,skipBootstrap=1,skipProvisions=1,skipCrons=1,skipAffiliations=1,skipGrafanas=1,skipServices=1,skipPostgres=1,skipIngress=1,skipStatic=1,skipAPI=1,skipNamespaces=1,reportsPod=1,namespace='devstats-prod'`.
- On the `test` node run: `helm install devstats-test-reports ./devstats-helm --set skipSecrets=1,skipPVs=1,skipBackupsPV=1,skipVacuum=1,skipBackups=1,skipBootstrap=1,skipProvisions=1,skipCrons=1,skipAffiliations=1,skipGrafanas=1,skipServices=1,skipPostgres=1,skipIngress=1,skipStatic=1,skipAPI=1,skipNamespaces=1,reportsPod=1,projectsOverride='+cncf\,+opencontainers\,+istio\,+zephyr\,+linux\,+rkt\,+sam\,+azf\,+riff\,+fn\,+openwhisk\,+openfaas\,+cii\,+prestodb\,+godotengine'`.
- Shell into reporting pod: `../devstats-k8s-lf/util/pod_shell.sh devstats-reports` or `k exec -itn devstats-prod devstats-reports -- bash` from a different namespace (like `devstats-test`).
- Generate data for all time for a given project(s): `TASKS='unknown_contributors' ONLY='keylime tuf' ./affs/all_tasks.sh`.
- Generate data for recent 3 months for all projects: `TASKS='unknown_contributors' ONLY='allprj' ./affs/all_tasks_recent.sh '3 months'`.
- Generate data for new/first-time committers 2 months for Prometheus projects: `ONLY='prometheus' TASKS='unknown_committers' ./affs/all_tasks_new.sh '2 months'`.
- Delete reporting pod: `helm delete devstats-prod-reports`. Use `devstats` URL for `prod` and `teststats` for `test`.
- Go to `cncf/gitdm:src`: `wget https://devstats.cncf.io/backups/keylime_unknown_contributors.csv`
- Go to `cncf/gitdm:src`: `wget https://teststats.cncf.io/backups/allprj_unknown_contributors_recent.csv`
- Check for forbidden SHAs: `./check_shas keylime_unknown_contributors.csv`.
- Check for forbidden SHAs: `./check_shas allprj_unknown_contributors_recent.csv`.
- Generate a task file: `PG_PASS=... ./unknown_committers.rb keylime_unknown_contributors.csv; mv task.csv keylime_task.csv`.
- Generate a task file: `PG_PASS=... ./unknown_committers.rb allprj_unknown_contributors_recent.csv; mv task.csv allprj_task.csv`.
- Merge multiple tasks: `./csv_merge.rb commits task.csv *_task.csv`
- Upload `task.csv` to a Google Sheet.
