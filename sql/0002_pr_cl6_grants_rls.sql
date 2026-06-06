-- ============================================================
-- Migration: 0002_pr_cl6_grants_rls.sql
-- PR-CL6 - GoodFinds WMS - Purchasing API access (grants + RLS)
-- Schema: goodfinds (isolated; never touch wms.*)
-- Fixes: "permission denied for schema goodfinds" (HTTP 401) when the
-- browser anon client reads suppliers / v_ball_economics and inserts balls.
-- App is public (anon key, no auth), so policies target anon + authenticated.
-- Idempotent & safe to re-run.
-- ============================================================

-- 1) Schema usage (root cause of the 401)
grant usage on schema goodfinds to anon, authenticated;

-- 2) Table/view privileges
grant select, insert, update on goodfinds.suppliers to anon, authenticated;
grant select, insert, update on goodfinds.balls to anon, authenticated;
grant select on goodfinds.v_ball_economics to anon, authenticated;

-- Future objects inherit the same privileges
alter default privileges in schema goodfinds grant select, insert, update on tables to anon, authenticated;

-- 3) Enable Row Level Security
alter table goodfinds.suppliers enable row level security;
alter table goodfinds.balls enable row level security;

-- 4) Policies (public app: allow anon + authenticated)
drop policy if exists p_suppliers_all on goodfinds.suppliers;
create policy p_suppliers_all on goodfinds.suppliers
  for all to anon, authenticated
  using (true) with check (true);

drop policy if exists p_balls_all on goodfinds.balls;
create policy p_balls_all on goodfinds.balls
  for all to anon, authenticated
  using (true) with check (true);
