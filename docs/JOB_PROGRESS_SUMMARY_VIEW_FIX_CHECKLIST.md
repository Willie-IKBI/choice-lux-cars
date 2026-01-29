# job_progress_summary view: SECURITY INVOKER fix – tests and checks

When you implement the fix (change the view from SECURITY DEFINER to SECURITY INVOKER), use this checklist to verify behaviour.

---

## 1. Database checks (Supabase SQL Editor)

Run the queries in **`supabase/queries/job_progress_summary_security_invoker_fix.sql`** in order:

| Step | What to do | Pass criteria |
|------|------------|----------------|
| **1) CHECK** | Run the “CHECK: Current view security property” query. | You see `job_progress_summary` with `security_invoker_option` NULL or `false` (DEFINER) before fix. |
| **2) FIX** | Run `ALTER VIEW public.job_progress_summary SET (security_invoker = on);` | No error. (If Postgres &lt; 15, recreate the view with INVOKER instead.) |
| **3) VERIFY** | Run “VERIFY: View still returns data” (`SELECT COUNT(*) FROM public.job_progress_summary`). | Returns a number (no permission error). Count may be lower than before if RLS now correctly filters. |
| **5) RE-CHECK** | Run “RE-CHECK: Confirm view is now INVOKER”. | `security_invoker_option` = `on`. |

---

## 2. Role-based behaviour (optional but recommended)

- **Service role / backend:** From the app (using service role key), any code that reads `job_progress_summary` should still work; service role bypasses RLS, so no change expected.
- **Admin (e.g. `administrator` / `super_admin`):** In Dashboard or SQL Editor as an admin user, `SELECT * FROM public.job_progress_summary` should return rows (at least all rows allowed by RLS on underlying tables).
- **Driver:** As an authenticated driver, `SELECT * FROM public.job_progress_summary` should return only rows for jobs where `jobs.driver_id = auth.uid()`. If you previously saw “all” rows as a driver, you should now see fewer (correct behaviour).
- **Other roles (e.g. manager, driver_manager):** Same as driver: only rows allowed by RLS on `jobs` (and any other base tables the view uses).

If any role gets **permission denied** on the view or on underlying tables, grant that role `SELECT` on the view and on the base tables the view uses (`jobs`, `driver_flow`, `trip_progress`, etc.) as needed; RLS will still restrict which rows they see.

---

## 3. App / integration checks

- The **Flutter app** does **not** reference `job_progress_summary`; it uses `jobs`, `driver_flow`, and `trip_progress` directly. So no app code changes are required for this fix.
- If **reports, BI, or other services** (e.g. Blueberry, SQL reports) query `job_progress_summary`:
  - Run those reports as the same role(s) they use in production.
  - Confirm they still return expected data and that row counts/visibility match the role (e.g. driver sees only their jobs).

---

## 4. Supabase Dashboard

- In **Database → Views**, open `public.job_progress_summary`. The security finding (“defined with SECURITY DEFINER”) should disappear after the view is set to SECURITY INVOKER and the advisor re-runs.

---

## 5. Quick reference

- **Fix:** `ALTER VIEW public.job_progress_summary SET (security_invoker = on);` (Postgres 15+).
- **Script:** `supabase/queries/job_progress_summary_security_invoker_fix.sql`.
- **Impact:** View runs with the **caller’s** permissions and RLS; no privilege escalation; some roles may see fewer rows than before (correct).
