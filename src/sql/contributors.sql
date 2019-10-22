with contributions as (
  select committer_id as actor_id,
    dup_committer_login as actor,
    event_id
  from
    gha_commits
  where
    committer_id is not null
    and (lower(dup_committer_login) {{exclude_bots}})
  union select author_id as actor_id,
    dup_author_login as actor,
    event_id
  from
    gha_commits
  where
    author_id is not null
    and (lower(dup_author_login) {{exclude_bots}})
  union select actor_id,
    dup_actor_login as actor,
    id as event_id
  from
    gha_events
  where
    type in (
      'PushEvent', 'PullRequestEvent', 'IssuesEvent',
      'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
    )
    and (lower(dup_actor_login) {{exclude_bots}})
), contributors as (
  select actor,
    count(distinct event_id) as contributions
  from
    contributions
  group by
    actor
  order by
    contributions desc
), all_contributions as (
  select sum(contributions) as cnt
  from
    contributors
)
select
  row_number() over cumulative_contributions as rank_number,
  c.actor,
  c.contributions,
  round((c.contributions * 100.0) / a.cnt, 5) as percent,
  sum(c.contributions) over cumulative_contributions as cumulative_sum,
  round((sum(c.contributions) over cumulative_contributions * 100.0) / a.cnt, 5) as cumulative_percent,
  a.cnt as all_contributions
from
  contributors c,
  all_contributions a
window
  cumulative_contributions as (
    order by c.contributions desc, c.actor asc
    range between unbounded preceding
    and current row
  )
;
