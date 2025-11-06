-- Simplified summary of BLUEBERRY jobs
-- Shows: Job ID, Job Number, Client Name, Date, Time, Amount, Status

SELECT 
  j.id AS "Job ID",
  j.job_number AS "Job Number",
  c.company_name AS "Client Name",
  j.job_start_date AS "Job Date",
  TO_CHAR(t.pickup_date, 'DD/MM/YYYY') AS "Pickup Date",
  TO_CHAR(t.pickup_date, 'HH24:MI') AS "Pickup Time",
  COALESCE(t.amount, j.amount, 0) AS "Amount",
  j.job_status AS "Status",
  t.pickup_location AS "Pickup Location",
  t.dropoff_location AS "Dropoff Location",
  p.display_name AS "Driver",
  j.passenger_name AS "Passenger"
FROM jobs j
INNER JOIN clients c ON j.client_id = c.id
LEFT JOIN transport t ON j.id = t.job_id
LEFT JOIN profiles p ON j.driver_id = p.id
WHERE UPPER(c.company_name) LIKE '%BLUEBERRY%'
  AND c.deleted_at IS NULL
ORDER BY j.job_start_date DESC, t.pickup_date DESC NULLS LAST;

