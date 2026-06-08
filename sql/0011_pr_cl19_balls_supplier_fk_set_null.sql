-- PR-CL19 | migration 0011 | balls_supplier_id_fkey -> ON DELETE SET NULL
-- Fix: app error "update or delete on table suppliers violates foreign key
-- constraint balls_supplier_id_fkey on table balls" saat hapus supplier.
-- Penyebab: FK balls.supplier_id pakai NO ACTION (default), jadi supplier yang
-- masih dipake ball ga bisa dihapus.
-- Behavior baru: hapus supplier -> ball yang make-nya di-set supplier_id = NULL
-- (ball tetap ada, cuma kehilangan link supplier). supplier_id memang nullable.
-- Idempotent: drop constraint if exists + add ulang; cleanup orphan aman diulang.

-- 1. Bersihin orphan supplier_id (nunjuk supplier yang udah ga ada) jadi NULL
update goodfinds.balls b
   set supplier_id = null
 where supplier_id is not null
   and not exists (select 1 from goodfinds.suppliers s where s.id = b.supplier_id);

-- 2. Recreate FK dengan ON DELETE SET NULL
alter table goodfinds.balls drop constraint if exists balls_supplier_id_fkey;
alter table goodfinds.balls
  add constraint balls_supplier_id_fkey
  foreign key (supplier_id) references goodfinds.suppliers(id) on delete set null;

