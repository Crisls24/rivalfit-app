-- Apply after push_up_sessions_v1.sql. The weekly scoring contract stays in v1.
begin;

-- Existing receipts get the migration time, the latest instant at which we
-- know they existed. An offline upload after midnight cannot change a winner.
alter table public.sessions add column if not exists league_received_at
  timestamptz not null default statement_timestamp();

create or replace function public.league_standings_v2(p_league uuid)
returns table (
  user_id uuid, weekly_points bigint, joined_at timestamptz, users jsonb,
  "position" bigint, leg_reps bigint, chest_arm_reps bigint,
  last_session jsonb, daily_award jsonb
)
language sql stable security definer set search_path = '' as $$
  with roster as materialized (
    select r.*, rank() over (order by r.weekly_points desc) as position
    from public.league_weekly_ranking_v1(p_league) r
    where public.is_league_member(p_league)
  ), clock as (
    select (statement_timestamp() at time zone 'America/Mexico_City')::date as today
  ), accepted as (
    select s.*, (s.completed_at at time zone 'America/Mexico_City')::date as day
    from public.sessions s
    where s.league_id = p_league and exists (select 1 from roster)
      and public.is_supported_training_result_v1(s.exercise_type, s.rules_version)
      and s.verified_reps > 0
  ), daily_totals as (
    select a.day, a.user_id, sum(a.verified_reps) as reps
    from accepted a cross join clock c
    where a.day between c.today - 1 and c.today
      and a.league_received_at < ((a.day + 1)::timestamp at time zone 'America/Mexico_City')
    group by a.day, a.user_id
  ), contenders as (
    select d.*, rank() over (partition by day order by reps desc) as place,
      count(*) over (partition by day, reps) as tied
    from daily_totals d
  ), award as (
    select w.user_id, jsonb_build_object('day', w.day, 'reps', w.reps,
      'closed', w.day < c.today) as result
    from contenders w join roster r using (user_id) cross join clock c
    where w.place = 1 and w.tied = 1
    order by w.day desc limit 1
  ), shared as (
    select a.* from accepted a join public.league_members m
      on m.league_id = p_league and m.user_id = a.user_id
      and a.started_at >= m.scoring_since
  ), totals as (
    select s.user_id, sum(s.verified_reps) filter (where s.exercise_type = 'sentadillas') as legs,
      sum(s.verified_reps) filter (where s.exercise_type = 'lagartijas') as arms
    from shared s group by s.user_id
  ), latest as (
    select distinct on (s.user_id) s.user_id, jsonb_build_object(
      'exercise', s.exercise_type, 'reps', s.verified_reps, 'ended_at', s.completed_at
    ) as session from shared s order by s.user_id, s.completed_at desc, s.id
  )
  select r.user_id, r.weekly_points, r.joined_at, r.users, r.position,
    coalesce(t.legs, 0), coalesce(t.arms, 0), l.session, a.result
  from roster r left join totals t using (user_id)
  left join latest l using (user_id) left join award a using (user_id)
  order by r.weekly_points desc, r.joined_at, r.user_id;
$$;
revoke all on function public.league_standings_v2(uuid) from public, anon, authenticated;
grant execute on function public.league_standings_v2(uuid) to authenticated;
commit;
