-- =====================================================================
-- Wreckfest 2 Race Log — Supabase schema
-- Run this in the Supabase SQL editor on a fresh project.
-- =====================================================================

-- Create and expose the wreckfest2 schema.
create schema if not exists wreckfest2;
grant usage on schema wreckfest2 to anon, authenticated, service_role;
alter default privileges in schema wreckfest2
    grant all on tables to anon, authenticated, service_role;
alter default privileges in schema wreckfest2
    grant all on sequences to anon, authenticated, service_role;
alter default privileges in schema wreckfest2
    grant all on routines to anon, authenticated, service_role;

-- Tracks: shared catalogue (no user_id — same set for everyone).
create table if not exists wreckfest2.tracks (
    id uuid primary key default gen_random_uuid(),
    name text not null unique,
    slug text not null unique,
    created_at timestamptz not null default now()
);

-- Track variations: routes/configurations of a track.
create table if not exists wreckfest2.track_variations (
    id uuid primary key default gen_random_uuid(),
    track_id uuid not null references wreckfest2.tracks(id) on delete cascade,
    name text not null,
    slug text not null,
    created_at timestamptz not null default now(),
    unique (track_id, slug)
);

-- Vehicles: shared catalogue.
create table if not exists wreckfest2.vehicles (
    id uuid primary key default gen_random_uuid(),
    name text not null unique,
    class text,
    image_url text,
    created_at timestamptz not null default now()
);

-- For projects upgrading from an earlier schema version: add the columns
-- if they're missing. Safe to leave in even on a fresh install.
alter table wreckfest2.vehicles add column if not exists image_url text;

-- Goals: per-user lap-time goal and notes for a track variation.
create table if not exists wreckfest2.goals (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    track_variation_id uuid not null references wreckfest2.track_variations(id) on delete cascade,
    goal_lap_time_ms integer check (goal_lap_time_ms is null or goal_lap_time_ms > 0),
    notes text,
    updated_at timestamptz not null default now(),
    unique (user_id, track_variation_id)
);

-- For existing installs: migrate goals table to new shape.
alter table wreckfest2.goals alter column goal_lap_time_ms drop not null;
alter table wreckfest2.goals add column if not exists notes text;
drop table if exists wreckfest2.track_variation_notes;

-- Races: the core record.
-- Times stored as integer milliseconds for precise comparisons.
create table if not exists wreckfest2.races (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    datetime timestamptz not null default now(),
    track_variation_id uuid not null references wreckfest2.track_variations(id) on delete cascade,
    vehicle_id uuid references wreckfest2.vehicles(id) on delete set null,
    place text,
    lap_time_ms integer,
    total_time_ms integer,
    notes text,
    created_at timestamptz not null default now()
);

-- For existing installs: drop the tuning column if it exists.
alter table wreckfest2.races drop column if exists tuning;

create index if not exists races_user_track_idx
    on wreckfest2.races (user_id, track_variation_id, datetime desc);

create index if not exists races_user_datetime_idx
    on wreckfest2.races (user_id, datetime desc);

-- Variation annotations: per-user turn notes pinned to a map image position.
create table if not exists wreckfest2.variation_annotations (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    track_variation_id uuid not null references wreckfest2.track_variations(id) on delete cascade,
    x numeric(6,3) not null,
    y numeric(6,3) not null,
    number integer not null default 1,
    note text,
    created_at timestamptz not null default now()
);

create index if not exists variation_annotations_user_track_idx
    on wreckfest2.variation_annotations (user_id, track_variation_id);

-- =====================================================================
-- Row Level Security
-- =====================================================================

alter table wreckfest2.tracks enable row level security;
alter table wreckfest2.track_variations enable row level security;
alter table wreckfest2.vehicles enable row level security;
alter table wreckfest2.races enable row level security;
alter table wreckfest2.goals enable row level security;

-- Catalogue tables: anyone signed in can read.
-- Postgres 15 has no `create policy if not exists`, so we drop-then-create
-- to keep this script safe to re-run.
drop policy if exists "tracks readable by authenticated" on wreckfest2.tracks;
create policy "tracks readable by authenticated"
    on wreckfest2.tracks for select
    to authenticated
    using (true);

drop policy if exists "track_variations readable by authenticated" on wreckfest2.track_variations;
create policy "track_variations readable by authenticated"
    on wreckfest2.track_variations for select
    to authenticated
    using (true);

drop policy if exists "vehicles readable by authenticated" on wreckfest2.vehicles;
create policy "vehicles readable by authenticated"
    on wreckfest2.vehicles for select
    to authenticated
    using (true);

-- Races: users only see/touch their own.
drop policy if exists "races select own" on wreckfest2.races;
create policy "races select own"
    on wreckfest2.races for select
    to authenticated
    using (auth.uid() = user_id);

drop policy if exists "races insert own" on wreckfest2.races;
create policy "races insert own"
    on wreckfest2.races for insert
    to authenticated
    with check (auth.uid() = user_id);

drop policy if exists "races update own" on wreckfest2.races;
create policy "races update own"
    on wreckfest2.races for update
    to authenticated
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

drop policy if exists "races delete own" on wreckfest2.races;
create policy "races delete own"
    on wreckfest2.races for delete
    to authenticated
    using (auth.uid() = user_id);

-- Goals: same pattern.
drop policy if exists "goals select own" on wreckfest2.goals;
create policy "goals select own"
    on wreckfest2.goals for select
    to authenticated
    using (auth.uid() = user_id);

drop policy if exists "goals insert own" on wreckfest2.goals;
create policy "goals insert own"
    on wreckfest2.goals for insert
    to authenticated
    with check (auth.uid() = user_id);

drop policy if exists "goals update own" on wreckfest2.goals;
create policy "goals update own"
    on wreckfest2.goals for update
    to authenticated
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

drop policy if exists "goals delete own" on wreckfest2.goals;
create policy "goals delete own"
    on wreckfest2.goals for delete
    to authenticated
    using (auth.uid() = user_id);

-- Variation annotations: same pattern as races/goals.
alter table wreckfest2.variation_annotations enable row level security;

drop policy if exists "variation_annotations select own" on wreckfest2.variation_annotations;
create policy "variation_annotations select own"
    on wreckfest2.variation_annotations for select
    to authenticated
    using (auth.uid() = user_id);

drop policy if exists "variation_annotations insert own" on wreckfest2.variation_annotations;
create policy "variation_annotations insert own"
    on wreckfest2.variation_annotations for insert
    to authenticated
    with check (auth.uid() = user_id);

drop policy if exists "variation_annotations delete own" on wreckfest2.variation_annotations;
create policy "variation_annotations delete own"
    on wreckfest2.variation_annotations for delete
    to authenticated
    using (auth.uid() = user_id);

-- =====================================================================
-- Catalogue seed (tracks, variations, vehicles) lives in supabase/seed.sql.
-- Run that file separately after this one. It is idempotent.
-- =====================================================================

-- =====================================================================
-- Admin: roles catalogue and user_roles joining table
-- (No user_profiles table — email is read directly from auth.users
--  inside security definer RPCs.)
-- =====================================================================

-- Clean up previous schema versions that had user_profiles.
drop table if exists wreckfest2.user_roles cascade;
drop table if exists wreckfest2.user_profiles cascade;

-- Roles catalogue: the set of valid roles.
create table if not exists wreckfest2.roles (
    id          uuid primary key default gen_random_uuid(),
    name        text not null unique,
    description text,
    created_at  timestamptz not null default now()
);

-- Seed the two built-in roles (idempotent).
insert into wreckfest2.roles (name, description) values
    ('user',  'Standard user'),
    ('admin', 'Administrator with access to admin pages')
on conflict (name) do nothing;

alter table wreckfest2.roles enable row level security;

drop policy if exists "roles readable by authenticated" on wreckfest2.roles;
create policy "roles readable by authenticated"
    on wreckfest2.roles for select
    to authenticated
    using (true);

-- User roles: links auth.users directly to roles.
create table if not exists wreckfest2.user_roles (
    user_id    uuid not null references auth.users(id) on delete cascade,
    role_id    uuid not null references wreckfest2.roles(id) on delete cascade,
    created_at timestamptz not null default now(),
    primary key (user_id, role_id)
);

alter table wreckfest2.user_roles enable row level security;

-- Each user can read their own role assignments.
drop policy if exists "user_roles select own" on wreckfest2.user_roles;
create policy "user_roles select own"
    on wreckfest2.user_roles for select
    to authenticated
    using (auth.uid() = user_id);

-- Assign the 'user' role to new sign-ups automatically.
create or replace function wreckfest2.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = wreckfest2
as $$
begin
    insert into wreckfest2.user_roles (user_id, role_id)
    select new.id, r.id from wreckfest2.roles r where r.name = 'user'
    on conflict (user_id, role_id) do nothing;
    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure wreckfest2.handle_new_user();

-- Backfill: assign 'user' role to any existing users without a role assignment.
insert into wreckfest2.user_roles (user_id, role_id)
select u.id, r.id
from auth.users u
cross join wreckfest2.roles r
where r.name = 'user'
  and not exists (
      select 1 from wreckfest2.user_roles ur where ur.user_id = u.id
  )
on conflict (user_id, role_id) do nothing;

-- =====================================================================
-- Admin RPC functions (security definer — bypass RLS with role check)
-- =====================================================================

-- Internal helper: true if the given user holds the admin role.
create or replace function wreckfest2.is_admin(uid uuid)
returns boolean
language sql
security definer stable set search_path = wreckfest2
as $$
    select exists (
        select 1
        from wreckfest2.user_roles ur
        join wreckfest2.roles r on r.id = ur.role_id
        where ur.user_id = uid and r.name = 'admin'
    )
$$;

-- Returns aggregate diagnostics — admin only.
create or replace function wreckfest2.get_diagnostics()
returns json
language plpgsql
security definer set search_path = wreckfest2
as $$
declare
    v_total_users int;
    v_top_users   json;
begin
    if not wreckfest2.is_admin(auth.uid()) then
        raise exception 'Unauthorized: admin access required';
    end if;

    select count(*) into v_total_users from auth.users;

    select json_agg(t) into v_top_users
    from (
        select
            u.email,
            u.created_at,
            count(distinct rc.id)  as race_count,
            count(distinct g.id)   as goal_count,
            count(distinct a.id)   as annotation_count,
            count(distinct rc.id) + count(distinct g.id) + count(distinct a.id) as total_activity
        from auth.users u
        left join wreckfest2.races                 rc on rc.user_id = u.id
        left join wreckfest2.goals                 g  on g.user_id  = u.id
        left join wreckfest2.variation_annotations a  on a.user_id  = u.id
        group by u.id, u.email, u.created_at
        order by total_activity desc
        limit 5
    ) t;

    return json_build_object(
        'total_users', v_total_users,
        'top_users',   coalesce(v_top_users, '[]'::json)
    );
end;
$$;

-- Returns all users with their current role name — admin only.
create or replace function wreckfest2.get_all_users_with_roles()
returns table(id uuid, email text, role text, created_at timestamptz)
language plpgsql
security definer set search_path = wreckfest2
as $$
begin
    if not wreckfest2.is_admin(auth.uid()) then
        raise exception 'Unauthorized: admin access required';
    end if;

    return query
    select
        u.id::uuid,
        u.email::text,
        coalesce(
            (select r.name
             from wreckfest2.user_roles ur
             join wreckfest2.roles r on r.id = ur.role_id
             where ur.user_id = u.id
             limit 1),
            'user'
        )::text as role,
        u.created_at::timestamptz
    from auth.users u
    order by u.created_at asc;
end;
$$;

-- Returns cumulative user count per day for the last 30 days — admin only.
create or replace function wreckfest2.get_user_growth()
returns table(day date, user_count bigint)
language plpgsql
security definer set search_path = wreckfest2
as $$
begin
    if not wreckfest2.is_admin(auth.uid()) then
        raise exception 'Unauthorized: admin access required';
    end if;

    return query
    select
        gs::date as day,
        (select count(*) from auth.users u where u.created_at::date <= gs::date) as user_count
    from generate_series(
        current_date - interval '29 days',
        current_date,
        interval '1 day'
    ) as gs
    order by gs asc;
end;
$$;

-- Sets the role of a target user — admin only.
-- Replaces all current role assignments with the single new role.
create or replace function wreckfest2.set_user_role(target_user_id uuid, new_role text)
returns void
language plpgsql
security definer set search_path = wreckfest2
as $$
declare
    v_role_id uuid;
begin
    if not wreckfest2.is_admin(auth.uid()) then
        raise exception 'Unauthorized: admin access required';
    end if;

    select id into v_role_id from wreckfest2.roles where name = new_role;
    if v_role_id is null then
        raise exception 'Unknown role: %', new_role;
    end if;

    -- Prevent demoting the last admin.
    if new_role <> 'admin' then
        if (
            select count(*)
            from wreckfest2.user_roles ur
            join wreckfest2.roles r on r.id = ur.role_id
            where r.name = 'admin' and ur.user_id = target_user_id
        ) > 0 and (
            select count(*)
            from wreckfest2.user_roles ur
            join wreckfest2.roles r on r.id = ur.role_id
            where r.name = 'admin'
        ) = 1 then
            raise exception 'Cannot remove the last admin';
        end if;
    end if;

    delete from wreckfest2.user_roles where user_id = target_user_id;
    insert into wreckfest2.user_roles (user_id, role_id) values (target_user_id, v_role_id);
end;
$$;

-- =====================================================================
-- Feedback: user-submitted feedback, bugs, and suggestions.
-- Defined after is_admin so the admin select policy can reference it.
-- =====================================================================

create table if not exists wreckfest2.feedback (
    id            uuid primary key default gen_random_uuid(),
    user_id       uuid not null references auth.users(id) on delete cascade,
    url           text not null,
    feedback_text text not null,
    created_at    timestamptz not null default now()
);

alter table wreckfest2.feedback enable row level security;

-- Users can insert their own feedback.
drop policy if exists "feedback insert own" on wreckfest2.feedback;
create policy "feedback insert own"
    on wreckfest2.feedback for insert
    to authenticated
    with check (auth.uid() = user_id);

-- Admins can read all feedback.
drop policy if exists "feedback select admin" on wreckfest2.feedback;
create policy "feedback select admin"
    on wreckfest2.feedback for select
    to authenticated
    using (wreckfest2.is_admin(auth.uid()));

-- =====================================================================
-- API keys: per-user tokens for the sidecar memory-reader app.
-- Raw keys are never stored — only a SHA-256 hex digest.
-- =====================================================================

create table if not exists wreckfest2.api_keys (
    id           uuid primary key default gen_random_uuid(),
    user_id      uuid not null references auth.users(id) on delete cascade,
    key_hash     text not null unique,
    name         text not null,
    created_at   timestamptz not null default now(),
    last_used_at timestamptz
);

alter table wreckfest2.api_keys enable row level security;

drop policy if exists "api_keys select own" on wreckfest2.api_keys;
create policy "api_keys select own"
    on wreckfest2.api_keys for select
    to authenticated
    using (auth.uid() = user_id);

drop policy if exists "api_keys insert own" on wreckfest2.api_keys;
create policy "api_keys insert own"
    on wreckfest2.api_keys for insert
    to authenticated
    with check (auth.uid() = user_id);

drop policy if exists "api_keys delete own" on wreckfest2.api_keys;
create policy "api_keys delete own"
    on wreckfest2.api_keys for delete
    to authenticated
    using (auth.uid() = user_id);

-- RPC called by the sidecar: validates the raw API key, then inserts a race
-- for the owning user.  SECURITY DEFINER lets it bypass RLS so it can write
-- to wreckfest2.races on behalf of any user without exposing the service role key.
create or replace function wreckfest2.insert_race_with_api_key(
    p_api_key        text,
    p_track_slug     text,
    p_variation_slug text,
    p_vehicle_name   text,
    p_place          text,
    p_lap_time_ms    integer,
    p_total_time_ms  integer,
    p_datetime       timestamptz default now()
)
returns json
language plpgsql
security definer set search_path = wreckfest2
as $$
declare
    v_user_id            uuid;
    v_track_variation_id uuid;
    v_vehicle_id         uuid;
    v_race_id            uuid;
begin
    -- Validate key by hash.
    select user_id into v_user_id
    from wreckfest2.api_keys
    where key_hash = encode(sha256(p_api_key::bytea), 'hex');

    if v_user_id is null then
        return json_build_object('success', false, 'error', 'Invalid API key');
    end if;

    -- Stamp last-used.
    update wreckfest2.api_keys
    set last_used_at = now()
    where key_hash = encode(sha256(p_api_key::bytea), 'hex');

    -- Resolve track variation from slugs.
    select tv.id into v_track_variation_id
    from wreckfest2.track_variations tv
    join wreckfest2.tracks t on t.id = tv.track_id
    where t.slug = p_track_slug and tv.slug = p_variation_slug;

    if v_track_variation_id is null then
        return json_build_object(
            'success', false,
            'error', 'Track/variation not found: ' || p_track_slug || '/' || p_variation_slug
        );
    end if;

    -- Resolve vehicle (optional — null is fine).
    if p_vehicle_name is not null and p_vehicle_name <> '' then
        select id into v_vehicle_id
        from wreckfest2.vehicles
        where lower(name) = lower(p_vehicle_name);
    end if;

    -- Insert race bypassing RLS (security definer).
    insert into wreckfest2.races (
        user_id, track_variation_id, vehicle_id,
        place, lap_time_ms, total_time_ms, datetime
    ) values (
        v_user_id, v_track_variation_id, v_vehicle_id,
        p_place, p_lap_time_ms, p_total_time_ms, p_datetime
    )
    returning id into v_race_id;

    return json_build_object('success', true, 'race_id', v_race_id);
end;
$$;

-- Allow the anon key (used by the sidecar) to call this function.
-- Identity is verified inside via the API key hash — no session needed.
grant execute on function wreckfest2.insert_race_with_api_key to anon, authenticated;
