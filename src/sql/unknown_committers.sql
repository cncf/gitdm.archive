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
), unknown_commits as (
  select distinct c.committer_id as actor_id,
    c.dup_committer_login as actor,
    c.event_id
  from
    gha_commits c
  left join
    gha_actors_affiliations aa
  on
    c.committer_id = aa.actor_id
  where
    c.committer_id is not null
    and (lower(c.dup_committer_login) {{exclude_bots}})
    and aa.actor_id is null
  union select distinct c.author_id as actor_id,
    c.dup_author_login as actor,
    c.event_id
  from
    gha_commits c
  left join
    gha_actors_affiliations aa
  on
    c.author_id = aa.actor_id
  where
    c.author_id is not null
    and (lower(c.dup_author_login) {{exclude_bots}})
    and aa.actor_id is null
  union select distinct e.actor_id,
    e.dup_actor_login as actor,
    e.id as event_id
  from
    gha_events e
  left join
    gha_actors_affiliations aa
  on
    e.actor_id = aa.actor_id
  where
    e.type in ('PushEvent')
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and aa.actor_id is null
), committers as (
  select actor,
    count(distinct event_id) as commits
  from
    commits
  group by
    actor
  order by
    commits desc
), unknown_committers as (
  select actor,
    count(distinct event_id) as commits
  from
    unknown_commits
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
  unknown_committers c,
  all_commits a
window
  cumulative_commits as (
    order by c.commits desc, c.actor asc
    range between unbounded preceding
    and current row
  )
;
