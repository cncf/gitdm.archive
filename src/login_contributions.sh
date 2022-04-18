#!/bin/bash
k exec -n devstats-test devstats-postgres-0 -- psql allprj --csv -c "select dup_actor_login as login, count(id) as cnt from gha_events where type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent') group by dup_actor_login order by cnt desc" > login_contributions.csv
