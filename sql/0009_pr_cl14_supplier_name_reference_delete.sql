-- PR-CL14 / migration 0009: supplier name-only + show name in view
-- Idempotent.

-- 1) Allow name-only suppliers (drop NOT NULL on code so suppliers can be added by name)
alter table goodfinds.suppliers alter column code drop not null;

-- 2) v_ball_economics: expose supplier as name (fallback to code) under supplier_code
create or replace view goodfinds.v_ball_economics as
 SELECT b.id,
    b.internal_code,
    b.ball_code,
    b.ball_name,
    b.category,
    COALESCE(s.name, s.code) AS supplier_code,
    b.buy_price,
    b.shipping_cost,
    b.qty_pcs,
    b.qty_reject,
    COALESCE(b.qty_pcs, 0) - b.qty_reject AS qty_total,
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
