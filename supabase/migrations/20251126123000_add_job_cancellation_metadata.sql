-- Add cancellation metadata to jobs
alter table public.jobs
  add column if not exists cancelled_by uuid references auth.users (id),
  add column if not exists cancelled_at timestamptz;

create index if not exists idx_jobs_cancelled_by on public.jobs (cancelled_by);

