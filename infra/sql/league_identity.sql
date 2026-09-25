-- Identity de Liga v1 (APK .fvm debug / create league sheet oscuro)
-- Idempotente: se puede aplicar las veces que haga falta en el SQL editor
-- de Supabase (A). No toca ni dropa columnas existentes.
--
-- 1. icon_text  : palanca de identidad visual guardada por la app.
--                 El sheet v1 ya no la elige: la app inserta 'podium' fijo.
-- 2. social_bet : apuesta social opcional (whatsapp/instagram/twitch).
-- 3. photo_url  : foto de grupo subida al bucket 'avatars' (public/<uid>/league_*).

alter table public.leagues
  add column if not exists icon_text text not null default 'podium';

alter table public.leagues
  add column if not exists social_bet text;

alter table public.leagues
  add column if not exists photo_url text;

-- select (*) now: icon_text | social_bet | photo_url
-- select count(*) from information_schema.columns
--  where table_schema='public' and table_name='leagues'
--    and column_name in ('icon_text','social_bet','photo_url');