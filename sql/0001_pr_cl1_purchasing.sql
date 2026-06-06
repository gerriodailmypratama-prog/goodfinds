-- ============================================================
-- Migration: 0001_pr_cl1_purchasing.sql
-- PR-CL1 — GoodFinds WMS — Module 1: Purchasing
-- Schema: goodfinds (isolated; never touch wms.*)
-- Idempotent & safe to re-run. Reflects current Supabase prod state.
-- ============================================================

create schema if not exists goodfinds;

-- Seller / supplier master (e.g. A, B). Used to compare cost efficiency over time.
create table if not exists goodfinds.suppliers (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique,
  name        text,
  notes       text,
  created_at  timestamptz not null default now()
);

-- Each "ball" (bale) purchased. Contents are mixed & inexact by nature.
-- qty_pcs = sellable pcs counted after sorting; qty_reject = discarded (not sellable).
-- Cost-per-pcs is derived (see view), NOT stored. Rejects are absorbed into sellable cost.
create table if not exists goodfinds.balls (
  id           uuid primary key default gen_random_uuid(),
  ball_code    text not null,
  category     text not null,
  supplier_id  uuid references goodfinds.suppliers(id),
  buy_price    numeric(14,2) not null,
  qty_pcs      integer,
  qty_reject   integer not null default 0,
  buy_date     date not null default current_date,
  opened_at    date,
  status       text not null default 'bought'
               check (status in ('bought','opened','closed')),
  notes        text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists idx_balls_supplier on goodfinds.balls(supplier_id);
create index if not exists idx_balls_buy_date  on goodfinds.balls(buy_date);

-- View: per-ball economics. modal_per_pcs = buy_price / qty_pcs (sellable only).
-- reject_pct = qty_reject / (qty_pcs + qty_reject).
create or replace view goodfinds.v_ball_economics as
select
  b.id,
  b.ball_code,
  b.category,
  s.code as supplier_code,
  b.buy_price,
  b.qty_pcs,
  b.qty_reject,
  (coalesce(b.qty_pcs,0) + b.qty_reject) as qty_total,
  case when b.qty_pcs > 0
       then round(b.buy_price / b.qty_pcs, 2)
       else null end as modal_per_pcs,
  case when (coalesce(b.qty_pcs,0) + b.qty_reject) > 0
       then round(b.qty_reject::numeric / (coalesce(b.qty_pcs,0) + b.qty_reject) * 100, 1)
       else null end as reject_pct,
  b.buy_date,
  b.status
from goodfinds.balls b
left join goodfinds.suppliers s on s.id = b.supplier_id;
