-- List all open jobs with job_start_date before 23 Nov 2025
select *
from public.jobs
where job_status = 'open'
  and job_start_date < date '2025-11-23'
order by job_start_date;

-- Bulk update those jobs to completed
update public.jobs
set job_status = 'completed',
    updated_at = now()
where job_status = 'open'
  and job_start_date < date '2025-11-23';

