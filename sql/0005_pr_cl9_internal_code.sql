-- PR-CL9: auto-generate internal_code {NAMABALL12}-{BALLCODE}-{MMYY}-{NNN}, status default 'ordered'. Idempotent.
alter table goodfinds.balls add column if not exists internal_code text;
alter table goodfinds.balls alter column status set default 'ordered';

create or replace function goodfinds.gen_ball_internal_code()
returns trigger language plpgsql as $$
declare
  v_name text;
  v_code text;
  v_my text;
  v_seq int;
begin
  if new.internal_code is not null and new.internal_code <> '' then
    return new;
  end if;
  v_name := upper(regexp_replace(coalesce(new.ball_name, ''), '[^a-zA-Z0-9]', '', 'g'));
  v_name := left(v_name, 12);
  if v_name = '' then v_name := 'BALL'; end if;
  v_code := upper(regexp_replace(coalesce(new.ball_code, ''), '[^a-zA-Z0-9]', '', 'g'));
  v_my := to_char(coalesce(new.buy_date, current_date), 'MMYY');
  select count(*) + 1 into v_seq from goodfinds.balls
    where to_char(coalesce(buy_date, current_date), 'MMYY') = v_my;
  new.internal_code := v_name || '-' || v_code || '-' || v_my || '-' || lpad(v_seq::text, 3, '0');
  return new;
end $$;

drop trigger if exists trg_gen_ball_internal_code on goodfinds.balls;
create trigger trg_gen_ball_internal_code before insert on goodfinds.balls
  for each row execute function goodfinds.gen_ball_internal_code();

drop view if exists goodfinds.v_ball_economics;
create view goodfinds.v_ball_economics as select b.id, b.internal_code, b.ball_code, b.ball_name, b.category, s.code as supplier_code, b.buy_price, b.shipping_cost, b.qty_pcs, b.qty_reject, (coalesce(b.qty_pcs,0) + b.qty_reject) as qty_total, case when b.qty_pcs > 0 then round((b.buy_price + coalesce(b.shipping_cost,0)) / b.qty_pcs, 0) else null end as modal_per_pcs, case when (coalesce(b.qty_pcs,0) + b.qty_reject) > 0 then round(b.qty_reject::numeric / (coalesce(b.qty_pcs,0) + b.qty_reject) * 100, 1) else null end as reject_pct, b.buy_date, b.status from goodfinds.balls b left join goodfinds.suppliers s on s.id = b.supplier_id;
grant select on goodfinds.v_ball_economics to anon, authenticated;
