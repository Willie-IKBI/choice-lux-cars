-- Fix: view_dashboard_kpis SECURITY DEFINER → SECURITY INVOKER
-- Resolves Supabase advisor: view enforced owner's permissions instead of caller's (RLS bypass).
-- After this, the view runs with the querying user's privileges; RLS on base tables (quotes, jobs) applies.

ALTER VIEW public.view_dashboard_kpis SET (security_invoker = on);
