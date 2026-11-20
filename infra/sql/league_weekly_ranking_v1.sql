-- Apply after training_sessions_v1.sql.
begin;

alter table public.league_members
  add column if not exists scoring_since timestamptz not null default statement_timestamp();

create or replace function public.set_league_scoring_since()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.scoring_since := clock_timestamp();
  return new;
end;
$$;

drop trigger if exists set_league_scoring_since on public.league_members;
create trigger set_league_scoring_since before insert on public.league_members
  for each row execute function public.set_league_scoring_since();

create or replace function public.assign_training_league_v1()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  candidate record;
  selected_league uuid;
  matches integer := 0;
  received_at timestamptz := statement_timestamp();
begin
  if new.rules_version is distinct from 'sentadillas-v1' then
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
drop trigger if exists assign_training_league_v1 on public.sessions;
create trigger assign_training_league_v1 before insert on public.sessions
  for each row execute function public.assign_training_league_v1();

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
    and s.rules_version = 'sentadillas-v1'
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
