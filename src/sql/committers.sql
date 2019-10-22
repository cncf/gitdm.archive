with commits as (
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
    type in ('PushEvent')
    and (lower(dup_actor_login) {{exclude_bots}})
), committers as (
  select actor,
    count(distinct event_id) as commits
  from
    commits
  group by
    actor
  order by
    commits desc
), all_commits as (
  select sum(commits) as cnt
  from
    committers
)
select
  row_number() over cumulative_commits as rank_number,
  c.actor,
  c.commits,
  round((c.commits * 100.0) / a.cnt, 5) as percent,
  sum(c.commits) over cumulative_commits as cumulative_sum,
  round((sum(c.commits) over cumulative_commits * 100.0) / a.cnt, 5) as cumulative_percent,
  a.cnt as all_commits
from
  committers c,
  all_commits a
window
  cumulative_commits as (
    order by c.commits desc, c.actor asc
    range between unbounded preceding
    and current row
  )
;
