-- Fix: job_progress_summary SECURITY DEFINER → SECURITY INVOKER
-- Resolves Supabase advisor: view enforced owner's permissions instead of caller's (RLS bypass).
-- After this, the view runs with the querying user's privileges; RLS on base tables applies.

ALTER VIEW public.job_progress_summary SET (security_invoker = on);
