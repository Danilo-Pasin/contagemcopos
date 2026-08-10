-- ============================================================
-- Contagem — schema ctg_* (extraído do projeto compartilhado)
-- Projeto original: cxuurozyyfcqxywhsiyt · 2026-08-10
-- Replica apenas os objetos do app (prefixo ctg_), self-contained.
-- ============================================================

-- Extensões usadas (digest sha256 / gen_random_uuid)
create extension if not exists pgcrypto;

-- 1) Enums ----------------------------------------------------
create type public.ctg_activity_type as enum (
  'drink_added',
  'photo_added',
  'member_joined',
  'group_created',
  'title_changed',
  'achievement_unlocked',
  'group_ended'
);

create type public.ctg_group_status as enum ('active', 'ended', 'archived');

create type public.ctg_member_role as enum ('member', 'creator');

-- 2) Tabelas --------------------------------------------------
create table public.ctg_accounts (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  password_hash text not null,
  created_at timestamptz not null default now()
);

create table public.ctg_achievements (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  emoji text not null,
  title text not null,
  description text not null
);

create table public.ctg_groups (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name text not null,
  creator_anon_id uuid not null,
  start_date timestamptz not null default now(),
  end_date timestamptz not null,
  duration_days integer not null,
  max_goal integer not null,
  status public.ctg_group_status not null default 'active',
  cover_emoji text not null default '🍻',
  created_at timestamptz not null default now(),
  ended_at timestamptz
);
create unique index ctg_groups_code_key on public.ctg_groups using btree (code);

create table public.ctg_participants (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.ctg_groups(id) on delete cascade,
  anon_id uuid not null,
  name text not null,
  photo_url text,
  role public.ctg_member_role not null default 'member',
  joined_at timestamptz not null default now(),
  account_id uuid references public.ctg_accounts(id) on delete set null,
  unique (group_id, anon_id)
);

create table public.ctg_drinks (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.ctg_groups(id) on delete cascade,
  participant_id uuid not null references public.ctg_participants(id) on delete cascade,
  created_at timestamptz not null default now(),
  drink_type text,
  note text
);

create table public.ctg_photos (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.ctg_groups(id) on delete cascade,
  participant_id uuid not null references public.ctg_participants(id) on delete cascade,
  drink_id uuid references public.ctg_drinks(id) on delete set null,
  url text not null,
  created_at timestamptz not null default now()
);

create table public.ctg_activity_log (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.ctg_groups(id) on delete cascade,
  participant_id uuid references public.ctg_participants(id) on delete set null,
  type public.ctg_activity_type not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.ctg_participant_achievements (
  id uuid primary key default gen_random_uuid(),
  participant_id uuid not null references public.ctg_participants(id) on delete cascade,
  group_id uuid not null references public.ctg_groups(id) on delete cascade,
  achievement_id uuid not null references public.ctg_achievements(id) on delete cascade,
  unlocked_at timestamptz not null default now(),
  unique (participant_id, achievement_id)
);

create table public.ctg_title_history (
  id uuid primary key default gen_random_uuid(),
  participant_id uuid not null references public.ctg_participants(id) on delete cascade,
  group_id uuid not null references public.ctg_groups(id) on delete cascade,
  old_title text,
  new_title text not null,
  changed_at timestamptz not null default now()
);

create table public.ctg_hall_of_fame (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.ctg_groups(id) on delete cascade,
  group_name text not null,
  champion_name text not null,
  champion_photo text,
  total_drinks integer not null,
  end_date timestamptz not null,
  created_at timestamptz not null default now()
);

-- 3) Índices ---------------------------------------------------
create unique index ctg_accounts_name_key
  on public.ctg_accounts using btree (lower(name));
create index idx_ctg_groups_code on public.ctg_groups using btree (code);
create index idx_ctg_groups_status on public.ctg_groups using btree (status);
create index idx_ctg_part_anon on public.ctg_participants using btree (anon_id);
create index idx_ctg_part_group on public.ctg_participants using btree (group_id);
create index idx_ctg_drinks_created on public.ctg_drinks using btree (created_at desc);
create index idx_ctg_drinks_group on public.ctg_drinks using btree (group_id);
create index idx_ctg_drinks_part on public.ctg_drinks using btree (participant_id);
create index idx_ctg_photos_created on public.ctg_photos using btree (created_at desc);
create index idx_ctg_photos_group on public.ctg_photos using btree (group_id);
create index idx_ctg_activity_group
  on public.ctg_activity_log using btree (group_id, created_at desc);
create index idx_ctg_pa_part on public.ctg_participant_achievements using btree (participant_id);

-- 4) View -----------------------------------------------------
create or replace view public.ctg_ranking_view as
select
  p.id,
  p.group_id,
  p.anon_id,
  p.name,
  p.photo_url,
  p.role,
  p.joined_at,
  coalesce(drink_counts.total_drinks, 0::bigint) as total_drinks,
  rank() over (
    partition by p.group_id
    order by coalesce(drink_counts.total_drinks, 0::bigint) desc, p.joined_at
  ) as "position"
from public.ctg_participants p
left join (
  select ctg_drinks.participant_id, count(*) as total_drinks
  from public.ctg_drinks
  group by ctg_drinks.participant_id
) drink_counts on drink_counts.participant_id = p.id;

-- 5) Funções ---------------------------------------------------
create or replace function public.ctg_create_account(p_name text, p_password text)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_id uuid;
  v_name text := trim(p_name);
begin
  select a.id into v_id
    from public.ctg_accounts a
   where lower(a.name) = lower(v_name);
  if v_id is not null then
    raise exception 'Senha incorreta para "%". Se é novo, use outro nome.', v_name;
  end if;

  insert into public.ctg_accounts(name, password_hash)
  values (v_name, extensions.digest(p_password, 'sha256')::text)
  returning id into v_id;
  return v_id;
end;
$function$;

create or replace function public.ctg_login_account(p_name text, p_password text)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_id uuid;
begin
  select a.id into v_id
    from public.ctg_accounts a
   where lower(a.name) = lower(p_name)
     and a.password_hash = extensions.digest(p_password, 'sha256')::text;

  if v_id is not null then
    -- Re-vincula o anon_id das participações da conta à sessão anônima atual.
    -- O RLS de ctg_drinks/ctg_photos exige anon_id = auth.uid(); sem isso, um
    -- retorno por conta (nome+senha) em outro navegador/sessão cai em 403.
    update public.ctg_participants p
       set anon_id = auth.uid()
     where p.account_id = v_id
       and not exists (
         select 1 from public.ctg_participants o
         where o.group_id = p.group_id
           and o.anon_id = auth.uid()
           and o.id <> p.id
       );
  end if;

  return v_id;
end;
$function$;

create or replace function public.ctg_create_group(
  p_name text,
  p_creator_anon_id uuid,
  p_start_date timestamp with time zone,
  p_end_date timestamp with time zone,
  p_duration_days integer,
  p_max_goal integer,
  p_cover_emoji text default '🍻'::text
)
returns table (out_id uuid, out_code text)
language plpgsql
security definer
set search_path to 'public'
as $function$
declare v_code text; v_id uuid; chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
begin
  loop
    v_code := '';
    for i in 1..6 loop
      v_code := v_code || substr(chars, floor(random()*length(chars))::int + 1, 1);
    end loop;
    exit when not exists (select 1 from ctg_groups g where g.code = v_code);
  end loop;
  insert into ctg_groups (code, name, creator_anon_id, start_date, end_date, duration_days, max_goal, cover_emoji)
  values (v_code, p_name, p_creator_anon_id, p_start_date, p_end_date, p_duration_days, p_max_goal, coalesce(p_cover_emoji,'🍻'))
  returning id into v_id;
  insert into ctg_activity_log (group_id, type, payload)
    values (v_id, 'group_created', jsonb_build_object('name', p_name));
  out_id := v_id; out_code := v_code;
  return next;
end;
$function$;

create or replace function public.ctg_end_expired_groups()
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare g record; champ record;
begin
  for g in select * from ctg_groups where status = 'active' and end_date <= now() loop
    update ctg_groups set status = 'ended', ended_at = now() where id = g.id;
    insert into ctg_activity_log (group_id, type, payload)
      values (g.id, 'group_ended', jsonb_build_object('at', now()));
    select p.id, p.name, p.photo_url,
           (select count(*) from ctg_drinks d where d.participant_id = p.id) as total
      into champ from ctg_participants p where p.group_id = g.id
      order by total desc limit 1;
    if found then
      insert into ctg_hall_of_fame (group_id, group_name, champion_name, champion_photo, total_drinks, end_date)
        values (g.id, g.name, champ.name, champ.photo_url, coalesce(champ.total,0), g.end_date);
    end if;
  end loop;
end;
$function$;

create or replace function public.ctg_drink_activity()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  insert into ctg_activity_log (group_id, participant_id, type, payload)
  values (new.group_id, new.participant_id, 'drink_added',
          jsonb_build_object('drink_id', new.id, 'at', new.created_at));
  return new;
end;
$function$;

create or replace function public.ctg_member_activity()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  insert into ctg_activity_log (group_id, participant_id, type, payload)
  values (new.group_id, new.id, 'member_joined',
          jsonb_build_object('name', new.name, 'at', new.joined_at));
  return new;
end;
$function$;

create or replace function public.ctg_photo_activity()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  insert into ctg_activity_log (group_id, participant_id, type, payload)
  values (new.group_id, new.participant_id, 'photo_added',
          jsonb_build_object('photo_id', new.id, 'url', new.url, 'at', new.created_at));
  return new;
end;
$function$;

-- 6) Triggers --------------------------------------------------
create trigger trg_ctg_drink
after insert on public.ctg_drinks
for each row execute function public.ctg_drink_activity();

create trigger trg_ctg_member
after insert on public.ctg_participants
for each row execute function public.ctg_member_activity();

create trigger trg_ctg_photo
after insert on public.ctg_photos
for each row execute function public.ctg_photo_activity();

-- 7) RLS -------------------------------------------------------
alter table public.ctg_accounts enable row level security;
alter table public.ctg_achievements enable row level security;
alter table public.ctg_groups enable row level security;
alter table public.ctg_participants enable row level security;
alter table public.ctg_drinks enable row level security;
alter table public.ctg_photos enable row level security;
alter table public.ctg_activity_log enable row level security;
alter table public.ctg_participant_achievements enable row level security;
alter table public.ctg_title_history enable row level security;
alter table public.ctg_hall_of_fame enable row level security;

create policy ctg_groups_read on public.ctg_groups
  for select to public using (true);
create policy ctg_groups_insert on public.ctg_groups
  for insert to public with check (creator_anon_id = auth.uid());
create policy ctg_groups_update on public.ctg_groups
  for update to public using ((creator_anon_id = auth.uid()) or (status = 'active'::ctg_group_status));

create policy ctg_part_read on public.ctg_participants
  for select to public using (true);
create policy ctg_part_insert on public.ctg_participants
  for insert to public with check (
    (anon_id = auth.uid()) and
    (exists (select 1 from public.ctg_groups g where g.id = ctg_participants.group_id and g.status = 'active'::ctg_group_status and g.end_date > now()))
  );
create policy ctg_part_update on public.ctg_participants
  for update to public using (anon_id = auth.uid());

create policy ctg_drinks_read on public.ctg_drinks
  for select to public using (true);
create policy ctg_drinks_insert on public.ctg_drinks
  for insert to public with check (
    (exists (select 1 from public.ctg_participants p where p.id = ctg_drinks.participant_id and p.anon_id = auth.uid())) and
    (exists (select 1 from public.ctg_groups g where g.id = ctg_drinks.group_id and g.status = 'active'::ctg_group_status and g.end_date > now()))
  );

create policy ctg_photos_read on public.ctg_photos
  for select to public using (true);
create policy ctg_photos_insert on public.ctg_photos
  for insert to public with check (
    (exists (select 1 from public.ctg_participants p where p.id = ctg_photos.participant_id and p.anon_id = auth.uid())) and
    (exists (select 1 from public.ctg_groups g where g.id = ctg_photos.group_id and g.status = 'active'::ctg_group_status and g.end_date > now()))
  );
create policy ctg_photos_update on public.ctg_photos
  for update to public using (
    exists (select 1 from public.ctg_participants p where p.id = ctg_photos.participant_id and p.anon_id = auth.uid())
  );

create policy ctg_act_read on public.ctg_activity_log
  for select to public using (true);
create policy ctg_act_insert on public.ctg_activity_log
  for insert to public with check (
    (participant_id is null) or
    (exists (select 1 from public.ctg_participants p where p.id = ctg_activity_log.participant_id and p.anon_id = auth.uid()))
  );

create policy ctg_ach_read on public.ctg_achievements
  for select to public using (true);

create policy ctg_pa_read on public.ctg_participant_achievements
  for select to public using (true);
create policy ctg_pa_insert on public.ctg_participant_achievements
  for insert to public with check (
    exists (select 1 from public.ctg_participants p where p.id = ctg_participant_achievements.participant_id and p.anon_id = auth.uid())
  );

create policy ctg_th_read on public.ctg_title_history
  for select to public using (true);
create policy ctg_th_insert on public.ctg_title_history
  for insert to public with check (
    exists (select 1 from public.ctg_participants p where p.id = ctg_title_history.participant_id and p.anon_id = auth.uid())
  );

create policy ctg_hof_read on public.ctg_hall_of_fame
  for select to public using (true);
