-- PR-CL18 | migration 0010 | grant DELETE on goodfinds.suppliers
-- Fix: app error "permission denied for table suppliers" saat hapus reference supplier.
-- Penyebab: 0009 nambah name-only supplier + RLS policy ALL, tapi GRANT DELETE
-- di level tabel kelewat (suppliers cuma punya INSERT/SELECT/UPDATE).
-- Idempotent: GRANT bersifat additive, aman dijalankan berkali-kali.

grant delete on goodfinds.suppliers to anon, authenticated;
