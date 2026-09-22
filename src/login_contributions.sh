#!/bin/bash
# TESTSRV=1
if [ ! -z "${TESTSRV}" ]
then
  kubectl exec -n devstats-test devstats-postgres-0 -- psql allprj --csv -c "select dup_actor_login as login, count(id) as cnt from gha_events where type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent') group by dup_actor_login order by cnt desc" > login_contributions.csv
else
  kubectl exec -n devstats-prod devstats-postgres-0 -- psql allprj --csv -c "select dup_actor_login as login, count(id) as cnt from gha_events where type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent') group by dup_actor_login order by cnt desc" > login_contributions.csv
fi
./check_shas login_contributions.csv
echo -n "Proceed (y/n)? "
read ans
if [ ! "${ans}" = "y" ]
then
  echo "Fix forbiden SHAs and then run './update_login_contributions.rb && FULL=1 ./post_manual_checks.sh && ./post_manual_updates.sh' manually"
  exit 1
fi
./update_login_contributions.rb && FULL=1 ./post_manual_checks.sh && ./post_manual_updates.sh
