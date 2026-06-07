-- 0007_pr_cl11_reference_softdelete.sql
-- PR-CL11: reference tables (categories, ball_codes, ball_names) for reuse/autocomplete,
-- soft-delete on balls (deleted_at), and v_ball_economics filtered to non-deleted rows.
-- Idempotent. Schema goodfinds only. No hard DELETE / DROP table.

-- 1) Soft-delete column on balls
alter table goodfinds.balls
  add column if not exists deleted_at timestamptz;

-- 2) Reference tables (free-text values that recur, stored for reuse)
create table if not exists goodfinds.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists goodfinds.ball_codes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists goodfinds.ball_names (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

-- 3) Backfill reference tables from existing balls (distinct, non-null, non-empty)
insert into goodfinds.categories (name)
select distinct trim(category) from goodfinds.balls
where category is not null and trim(category) <> ''
on conflict (name) do nothing;

insert into goodfinds.ball_codes (code)
select distinct trim(ball_code) from goodfinds.balls
where ball_code is not null and trim(ball_code) <> ''
on conflict (code) do nothing;

insert into goodfinds.ball_names (name)
select distinct trim(ball_name) from goodfinds.balls
where ball_name is not null and trim(ball_name) <> ''
on conflict (name) do nothing;

-- 4) Grants + RLS for new reference tables (public app, anon key) -- same pattern as suppliers
grant usage on schema goodfinds to anon, authenticated;
grant select, insert, update, delete on goodfinds.categories to anon, authenticated;
grant select, insert, update, delete on goodfinds.ball_codes to anon, authenticated;
grant select, insert, update, delete on goodfinds.ball_names to anon, authenticated;

alter table goodfinds.categories enable row level security;
alter table goodfinds.ball_codes enable row level security;
alter table goodfinds.ball_names enable row level security;

drop policy if exists categories_all on goodfinds.categories;
create policy categories_all on goodfinds.categories for all using (true) with check (true);

drop policy if exists ball_codes_all on goodfinds.ball_codes;
create policy ball_codes_all on goodfinds.ball_codes for all using (true) with check (true);

drop policy if exists ball_names_all on goodfinds.ball_names;
create policy ball_names_all on goodfinds.ball_names for all using (true) with check (true);

-- 5) Recreate v_ball_economics to exclude soft-deleted balls
drop view if exists goodfinds.v_ball_economics;
create view goodfinds.v_ball_economics as
 SELECT b.id,
    b.internal_code,
    b.ball_code,
    b.ball_name,
    b.category,
    s.code AS supplier_code,
    b.buy_price,
    b.shipping_cost,
    b.qty_pcs,
    b.qty_reject,
    COALESCE(b.qty_pcs, 0) + b.qty_reject AS qty_total,
        CASE
            WHEN b.qty_pcs > 0 THEN round((b.buy_price + COALESCE(b.shipping_cost, 0::numeric)) / b.qty_pcs::numeric, 0)
            ELSE NULL::numeric
        END AS modal_per_pcs,
        CASE
            WHEN (COALESCE(b.qty_pcs, 0) + b.qty_reject) > 0 THEN round(b.qty_reject::numeric / (COALESCE(b.qty_pcs, 0) + b.qty_reject)::numeric * 100::numeric, 1)
            ELSE NULL::numeric
        END AS reject_pct,
    b.buy_date,
    b.opened_at,
    b.status
   FROM goodfinds.balls b
     LEFT JOIN goodfinds.suppliers s ON s.id = b.supplier_id
  WHERE b.deleted_at IS NULL;

grant select on goodfinds.v_ball_economics to anon, authenticated;
