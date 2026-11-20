-- Apply after training_sessions_v1.sql and league_weekly_ranking_v1.sql.
begin;

create or replace function public.is_supported_training_result_v1(exercise text, rules text)
returns boolean language sql immutable set search_path = '' as $$
  select coalesce(
    (exercise = 'sentadillas' and rules = 'sentadillas-v1') or
    (exercise = 'lagartijas' and rules = 'lagartijas-v1'),
    false
  );
$$;
revoke all on function public.is_supported_training_result_v1(text, text)
  from public, anon, authenticated;

create or replace function public.submit_training_session_v1(
  p_id uuid, p_owner uuid, p_exercise text, p_rules text, p_source text,
  p_started_at timestamptz, p_ended_at timestamptz,
  p_active_us bigint, p_reps integer
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  caller uuid := auth.uid();
  saved public.sessions%rowtype;
begin
  if caller is null or p_owner is distinct from caller then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_id is null or not public.is_supported_training_result_v1(p_exercise, p_rules)
      or p_source is distinct from 'camera'
      or p_started_at is null or p_ended_at is null
      or not pg_catalog.isfinite(p_started_at) or not pg_catalog.isfinite(p_ended_at)
      or p_active_us is null or p_active_us < 0 or p_active_us / 1000000 > 2147483647
      or p_reps is null or p_reps <= 0
      or p_ended_at < p_started_at
      or p_ended_at > pg_catalog.now() + interval '5 minutes'
      or p_active_us > extract(epoch from (p_ended_at - p_started_at)) * 1000000 then
    raise exception 'Invalid session' using errcode = '22023';
  end if;

  insert into public.sessions
      (id, user_id, exercise_type, rules_version, platform, started_at, completed_at,
       active_duration_us, total_reps, verified_reps, duration)
    values (p_id, caller, p_exercise, p_rules, p_source::public.session_platform, p_started_at, p_ended_at,
       p_active_us, p_reps, p_reps, (p_active_us / 1000000)::integer)
    on conflict (id) do nothing;

  select * into saved from public.sessions where id = p_id;
  if saved.user_id is distinct from caller
      or saved.exercise_type is distinct from p_exercise
      or saved.rules_version is distinct from p_rules
      or saved.platform::text is distinct from p_source
      or saved.started_at is distinct from p_started_at
      or saved.completed_at is distinct from p_ended_at
      or saved.active_duration_us is distinct from p_active_us
      or saved.verified_reps is distinct from p_reps then
    raise exception 'Session identity conflict' using errcode = '22023';
  end if;
  return pg_catalog.jsonb_build_object('session_id', saved.id, 'status', 'stored');
end;
$$;

revoke all on function public.submit_training_session_v1(
  uuid, uuid, text, text, text, timestamptz, timestamptz, bigint, integer)
  from public, anon, authenticated;
grant execute on function public.submit_training_session_v1(
  uuid, uuid, text, text, text, timestamptz, timestamptz, bigint, integer)
  to authenticated;

-- This RPC lets clients distinguish a backend without the new migration.
-- On that backend a push-up result can stay pending until the RPC is installed.
create or replace function public.submit_push_up_session_v1(
  p_id uuid, p_owner uuid, p_source text,
  p_started_at timestamptz, p_ended_at timestamptz,
  p_active_us bigint, p_reps integer
) returns jsonb language sql set search_path = '' as $$
  select public.submit_training_session_v1(
    p_id, p_owner, 'lagartijas', 'lagartijas-v1', p_source,
    p_started_at, p_ended_at, p_active_us, p_reps
  );
$$;
revoke all on function public.submit_push_up_session_v1(
  uuid, uuid, text, timestamptz, timestamptz, bigint, integer
) from public, anon, authenticated;
grant execute on function public.submit_push_up_session_v1(
  uuid, uuid, text, timestamptz, timestamptz, bigint, integer
) to authenticated;

create or replace function public.assign_training_league_v1()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  candidate record;
  selected_league uuid;
  matches integer := 0;
  received_at timestamptz := statement_timestamp();
begin
  if not public.is_supported_training_result_v1(new.exercise_type, new.rules_version) then
    return new;
  end if;

  new.league_id := null;
  if new.completed_at > received_at or
      date_trunc('week', new.started_at at time zone 'America/Mexico_City')
      is distinct from date_trunc('week', received_at at time zone 'America/Mexico_City') then
    return new;
  end if;

  -- Lock eligible membership rows so a concurrent departure cannot change
  -- the attribution between this check and insertion of the session.
  for candidate in
    select m.league_id, m.scoring_since
    from public.league_members m
    where m.user_id = new.user_id
    order by m.league_id
    for share
  loop
    matches := matches + 1;
    if candidate.scoring_since <= new.started_at then
      selected_league := candidate.league_id;
    end if;
  end loop;

  if matches = 1 then
    new.league_id := selected_league;
  end if;
  return new;
end;
$$;

revoke all on function public.assign_training_league_v1() from public, anon, authenticated;
create or replace function public.league_weekly_ranking_v1(p_league uuid)
returns table (
  league_id uuid, user_id uuid, weekly_points bigint,
  joined_at timestamptz, users jsonb
)
language sql stable security definer set search_path = '' as $$
  with week as (
    select date_trunc('week', statement_timestamp() at time zone 'America/Mexico_City') as start_at
  )
  select m.league_id, m.user_id, coalesce(sum(s.verified_reps), 0), m.joined_at,
    jsonb_build_object('display_name', u.display_name, 'alias', u.alias, 'photo_url', u.photo_url)
  from public.league_members m
  join public.users u on u.id = m.user_id
  cross join week w
  left join public.sessions s on s.user_id = m.user_id and s.league_id = m.league_id
    and public.is_supported_training_result_v1(s.exercise_type, s.rules_version)
    and s.started_at >= m.scoring_since
    and s.completed_at >= (w.start_at at time zone 'America/Mexico_City')
    and s.completed_at < ((w.start_at + interval '1 week') at time zone 'America/Mexico_City')
  where m.league_id = p_league and auth.uid() is not null
    and (public.is_league_member(p_league) or public.is_league_owner(p_league))
  group by m.league_id, m.user_id, m.joined_at, u.display_name, u.alias, u.photo_url
  order by 3 desc, m.joined_at asc, m.user_id asc;
$$;

revoke all on function public.league_weekly_ranking_v1(uuid) from public, anon, authenticated;
grant execute on function public.league_weekly_ranking_v1(uuid) to authenticated;

commit;
