-- =====================================================================
-- Wreckfest 2 Race Log — full catalogue seed
-- Generated from https://wreckfest.fandom.com/wiki/Maps#Wreckfest_2_early_access
--                  https://wreckfest.fandom.com/wiki/Vehicles#Wreckfest_2_early_access
-- Idempotent: safe to re-run. Existing rows are kept.
-- =====================================================================

begin;

-- Remove deprecated entries -------------------------------------------
delete from wreckfest2.track_variations tv
using wreckfest2.tracks t
where tv.track_id = t.id and t.slug = 'testing-grounds';
delete from wreckfest2.tracks where slug = 'testing-grounds';

delete from wreckfest2.track_variations tv
using wreckfest2.tracks t
where tv.track_id = t.id and t.slug = 'speedway' and tv.slug = 'derby-arena';

delete from wreckfest2.track_variations tv
using wreckfest2.tracks t
where tv.track_id = t.id and t.slug = 'uk-banger-1' and tv.slug = 'derby';

-- Tracks ----------------------------------------------------------------
insert into wreckfest2.tracks (name, slug) values ('Cannonhill', 'cannonhill') on conflict (slug) do update set name = excluded.name;
insert into wreckfest2.tracks (name, slug) values ('Crash Canyon', 'crash-canyon') on conflict (slug) do update set name = excluded.name;
insert into wreckfest2.tracks (name, slug) values ('Dalsbanen', 'dalsbanen') on conflict (slug) do update set name = excluded.name;
insert into wreckfest2.tracks (name, slug) values ('European Rallycross', 'european-rallycross-1') on conflict (slug) do update set name = excluded.name;
insert into wreckfest2.tracks (name, slug) values ('FinnCross Circuit', 'finncross-circuit') on conflict (slug) do update set name = excluded.name;
insert into wreckfest2.tracks (name, slug) values ('Moorfeld', 'moorfeld') on conflict (slug) do update set name = excluded.name;
insert into wreckfest2.tracks (name, slug) values ('Savolax Sandpit', 'savolax-sandpit') on conflict (slug) do update set name = excluded.name;
insert into wreckfest2.tracks (name, slug) values ('Scrapyard', 'scrapyard') on conflict (slug) do update set name = excluded.name;
insert into wreckfest2.tracks (name, slug) values ('Speedway', 'speedway') on conflict (slug) do update set name = excluded.name;
insert into wreckfest2.tracks (name, slug) values ('UK Banger', 'uk-banger-1') on conflict (slug) do update set name = excluded.name;

insert into wreckfest2.tracks (name, slug) values ('Mora Raceway', 'mora-raceway') on conflict (slug) do update set name = excluded.name;

-- Track variations ------------------------------------------------------
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Main circuit', 'main-circuit' from wreckfest2.tracks where slug = 'cannonhill' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Main circuit reverse', 'main-circuit-reverse' from wreckfest2.tracks where slug = 'cannonhill' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Waypoint race', 'waypoint-race' from wreckfest2.tracks where slug = 'crash-canyon' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Main route', 'main-route' from wreckfest2.tracks where slug = 'crash-canyon' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Main circuit', 'main-circuit' from wreckfest2.tracks where slug = 'dalsbanen' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Main circuit reverse', 'main-circuit-reverse' from wreckfest2.tracks where slug = 'dalsbanen' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Main circuit', 'main-circuit' from wreckfest2.tracks where slug = 'european-rallycross-1' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Reverse circuit', 'reverse-circuit' from wreckfest2.tracks where slug = 'european-rallycross-1' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Main circuit', 'main-circuit' from wreckfest2.tracks where slug = 'finncross-circuit' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Main circuit reverse', 'main-circuit-reverse' from wreckfest2.tracks where slug = 'finncross-circuit' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Race route', 'race-route' from wreckfest2.tracks where slug = 'moorfeld' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Crash route', 'crash-route' from wreckfest2.tracks where slug = 'moorfeld' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Main circuit', 'main-circuit' from wreckfest2.tracks where slug = 'savolax-sandpit' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Main circuit reverse', 'main-circuit-reverse' from wreckfest2.tracks where slug = 'savolax-sandpit' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Short circuit', 'short-circuit' from wreckfest2.tracks where slug = 'savolax-sandpit' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Short circuit reverse', 'short-circuit-reverse' from wreckfest2.tracks where slug = 'savolax-sandpit' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Main route', 'main-route' from wreckfest2.tracks where slug = 'scrapyard' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Main route reverse', 'main-route-reverse' from wreckfest2.tracks where slug = 'scrapyard' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Bonebreaker', 'bonebreaker' from wreckfest2.tracks where slug = 'scrapyard' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Speedbowl', 'speedbowl' from wreckfest2.tracks where slug = 'scrapyard' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Figure 8', 'figure-8' from wreckfest2.tracks where slug = 'scrapyard' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Outer oval', 'outer-oval' from wreckfest2.tracks where slug = 'speedway' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Inner oval', 'inner-oval' from wreckfest2.tracks where slug = 'speedway' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Figure 8', 'figure-8' from wreckfest2.tracks where slug = 'speedway' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Oval', 'oval' from wreckfest2.tracks where slug = 'uk-banger-1' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Figure 8', 'figure-8' from wreckfest2.tracks where slug = 'uk-banger-1' on conflict (track_id, slug) do update set name = excluded.name;

insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Full Circuit', 'full-circuit' from wreckfest2.tracks where slug = 'mora-raceway' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'High-Speed Oval', 'high-speed-oval' from wreckfest2.tracks where slug = 'mora-raceway' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Suicide Circuit', 'suicide-circuit' from wreckfest2.tracks where slug = 'mora-raceway' on conflict (track_id, slug) do update set name = excluded.name;
insert into wreckfest2.track_variations (track_id, name, slug) select id, 'Sprint Circuit', 'sprint-circuit' from wreckfest2.tracks where slug = 'mora-raceway' on conflict (track_id, slug) do update set name = excluded.name;

-- Vehicles --------------------------------------------------------------
insert into wreckfest2.vehicles (name) values ('Bravion') on conflict (name) do nothing;
insert into wreckfest2.vehicles (name) values ('Buggy') on conflict (name) do nothing;
insert into wreckfest2.vehicles (name) values ('Cardinal') on conflict (name) do nothing;
insert into wreckfest2.vehicles (name) values ('Crusader') on conflict (name) do nothing;
insert into wreckfest2.vehicles (name) values ('Gizmo') on conflict (name) do nothing;
insert into wreckfest2.vehicles (name) values ('Grandstar') on conflict (name) do nothing;
insert into wreckfest2.vehicles (name) values ('Hurricane') on conflict (name) do nothing;
insert into wreckfest2.vehicles (name) values ('Motorhome') on conflict (name) do nothing;
insert into wreckfest2.vehicles (name) values ('Nami') on conflict (name) do nothing;
insert into wreckfest2.vehicles (name) values ('Phaser') on conflict (name) do nothing;
insert into wreckfest2.vehicles (name) values ('Popper') on conflict (name) do nothing;
insert into wreckfest2.vehicles (name) values ('Rammer') on conflict (name) do nothing;
insert into wreckfest2.vehicles (name) values ('RoadSlayer') on conflict (name) do nothing;
insert into wreckfest2.vehicles (name) values ('Rocket') on conflict (name) do nothing;
insert into wreckfest2.vehicles (name) values ('School Bus') on conflict (name) do nothing;
insert into wreckfest2.vehicles (name) values ('Switchback') on conflict (name) do nothing;

insert into wreckfest2.vehicles (name) values ('Bullet') on conflict (name) do nothing;
insert into wreckfest2.vehicles (name) values ('Half a Crusader') on conflict (name) do nothing;
insert into wreckfest2.vehicles (name) values ('Jackal') on conflict (name) do nothing;
insert into wreckfest2.vehicles (name) values ('Stahlwagen') on conflict (name) do nothing;
insert into wreckfest2.vehicles (name) values ('Valken') on conflict (name) do nothing;

commit;
