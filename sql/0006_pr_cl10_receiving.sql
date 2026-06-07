-- PR-CL10: Receiving — expose opened_at in v_ball_economics + status index. Idempotent. No DROP table / DELETE.
create index if not exists idx_balls_status on goodfinds.balls (status);

drop view if exists goodfinds.v_ball_economics;
create view goodfinds.v_ball_economics as
select b.id, b.internal_code, b.ball_code, b.ball_name, b.category,
       s.code as supplier_code, b.buy_price, b.shipping_cost,
       b.qty_pcs, b.qty_reject,
       (coalesce(b.qty_pcs,0) + b.qty_reject) as qty_total,
       case when b.qty_pcs > 0 then round((b.buy_price + coalesce(b.shipping_cost,0)) / b.qty_pcs, 0) else null end as modal_per_pcs,
       case when (coalesce(b.qty_pcs,0) + b.qty_reject) > 0 then round(b.qty_reject::numeric / (coalesce(b.qty_pcs,0) + b.qty_reject) * 100, 1) else null end as reject_pct,
       b.buy_date, b.opened_at, b.status
from goodfinds.balls b
left join goodfinds.suppliers s on s.id = b.supplier_id;
grant select on goodfinds.v_ball_economics to anon, authenticated;
