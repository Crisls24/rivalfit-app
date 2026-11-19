-- RivalFit backend: extends init/10-autohost-schema.sql after migration 13.
begin;

alter table public.sessions
  add column if not exists rules_version text,
  add column if not exists started_at timestamptz,
  add column if not exists active_duration_us bigint;

-- Preserve legacy session policies while making RPC results immutable to clients.
drop policy if exists sessions_v1_insert_guard on public.sessions;
create policy sessions_v1_insert_guard on public.sessions as restrictive
  for insert to authenticated with check (rules_version is null);
drop policy if exists sessions_v1_update_guard on public.sessions;
create policy sessions_v1_update_guard on public.sessions as restrictive
  for update to authenticated using (rules_version is null) with check (rules_version is null);
drop policy if exists sessions_v1_delete_guard on public.sessions;
create policy sessions_v1_delete_guard on public.sessions as restrictive
  for delete to authenticated using (rules_version is null);

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
  if p_id is null or p_exercise is distinct from 'sentadillas'
      or p_rules is distinct from 'sentadillas-v1'
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

commit;
