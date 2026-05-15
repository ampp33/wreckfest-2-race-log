-- =====================================================================
-- One-time admin bootstrap
-- Run this in the Supabase SQL editor AFTER schema.sql to grant the
-- initial admin account. Re-running is safe (idempotent).
-- =====================================================================

-- Replace whatever role ampp33@gmail.com currently holds with 'admin'.
delete from wreckfest2.user_roles
where user_id = (select id from auth.users where email = 'ampp33@gmail.com');

insert into wreckfest2.user_roles (user_id, role_id)
select u.id, r.id
from auth.users u
cross join wreckfest2.roles r
where u.email = 'ampp33@gmail.com'
  and r.name  = 'admin';

-- Verify the result.
select u.email, r.name as role
from auth.users u
join wreckfest2.user_roles ur on ur.user_id = u.id
join wreckfest2.roles r on r.id = ur.role_id
where u.email = 'ampp33@gmail.com';
