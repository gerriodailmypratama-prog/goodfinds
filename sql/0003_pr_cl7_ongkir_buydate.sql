-- ============================================================
-- Migration: 0003_pr_cl7_ongkir_buydate.sql
-- PR-CL7 - GoodFinds WMS - Purchasing: add Ongkir (shipping_cost) + expose buy_date
-- Schema: goodfinds (isolated; never touch wms.*)
-- - Adds goodfinds.balls.shipping_cost (numeric, default 0).
-- - Rebuilds v_ball_economics so modal_per_pcs = (buy_price + shipping_cost) / qty_pcs,
--   exposes shipping_cost, and keeps buy_date for the date input.
-- Idempotent & safe to re-run. (drop+create because column set/order changes.)
-- ============================================================

-- 1) New column: shipping cost per ball (Ongkir)
alter table goodfinds.balls
  add column if not exists shipping_cost numeric not null default 0;

-- 2) Rebuild the economics view (modal now includes ongkir)
drop view if exists goodfinds.v_ball_economics;
create view goodfinds.v_ball_economics as
select
  b.id,
  b.ball_code,
  b.category,
  s.code as supplier_code,
  b.buy_price,
  b.shipping_cost,
  b.qty_pcs,
  b.qty_reject,
  (coalesce(b.qty_pcs,0) + b.qty_reject) as qty_total,
  case when b.qty_pcs > 0
    then round((b.buy_price + coalesce(b.shipping_cost,0)) / b.qty_pcs, 0)
    else null end as modal_per_pcs,
  case when (coalesce(b.qty_pcs,0) + b.qty_reject) > 0
    then round(b.qty_reject::numeric / (coalesce(b.qty_pcs,0) + b.qty_reject) * 100, 1)
    else null end as reject_pct,
  b.buy_date,
  b.status
from goodfinds.balls b
left join goodfinds.suppliers s on s.id = b.supplier_id;

-- 3) Keep API access (view recreated, so grant select again)
grant select on goodfinds.v_ball_economics to anon, authenticated;

-- (no-op touch: re-trigger build for PR-CL7)
