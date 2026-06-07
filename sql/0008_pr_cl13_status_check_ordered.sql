-- 0008_pr_cl13_status_check_ordered.sql
-- PR-CL13 — fix balls_status_check to include 'ordered' (the column default + Purchasing insert).
-- Without this, inserting a new ball (status defaults to 'ordered') violates the old check that
-- only allowed 'bought'/'opened'/'closed'. Idempotent. Schema goodfinds only. No hard DELETE / DROP table.

alter table goodfinds.balls drop constraint if exists balls_status_check;

alter table goodfinds.balls
  add constraint balls_status_check
  check (status = any (array['ordered'::text, 'opened'::text, 'bought'::text, 'closed'::text]));
