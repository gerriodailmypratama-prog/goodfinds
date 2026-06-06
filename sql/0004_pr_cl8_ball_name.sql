-- ============================================================
-- Migration: 0004_pr_cl8_ball_name.sql
-- PR-CL8 - GoodFinds WMS - Purchasing: add Ball Name (ball_name)
-- Schema: goodfinds (isolated; never touch wms.*)
-- - Adds goodfinds.balls.ball_name (text).
-- - Rebuilds v_ball_economics to expose ball_name (alongside ball_code).
-- Idempotent & safe to re-run. (drop+create because column set changes.)
-- ============================================================

-- 1) New column: human-readable ball name
alter table goodfinds.balls add column if not exists ball_name text;

-- 2) Rebuild the economics view to expose ball_name
drop view if exists goodfinds.v_ball_economics;
create view goodfinds.v_ball_economics as select b.id, b.ball_code, b.ball_name, b.category, s.code as supplier_code, b.buy_price, b.shipping_cost, b.qty_pcs, b.qty_reject, (coalesce(b.qty_pcs,0) + b.qty_reject) as qty_total, case when b.qty_pcs > 0 then round((b.buy_price + coalesce(b.shipping_cost,0)) / b.qty_pcs, 0) else null end as modal_per_pcs, case when (coalesce(b.qty_pcs,0) + b.qty_reject) > 0 then round(b.qty_reject::numeric / (coalesce(b.qty_pcs,0) + b.qty_reject) * 100, 1) else null end as reject_pct, b.buy_date, b.status from goodfinds.balls b left join goodfinds.suppliers s on s.id = b.supplier_id;

-- 3) Keep API access (view recreated, so grant select again)
grant select on goodfinds.v_ball_economics to anon, authenticated;
