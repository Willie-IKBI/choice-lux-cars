-- Complete job details for BLUEBERRY - All fields with totals

-- First, get all job details
WITH blueberry_jobs AS (
  SELECT 
    j.*,
    t.id AS transport_id,
    t.pickup_date,
    t.pickup_location,
    t.dropoff_location,
    t.amount AS transport_amount,
    t.client_pickup_time,
    t.client_dropoff_time,
    c.company_name,
    p.display_name AS driver_name,
    v.make AS vehicle_make,
    v.model AS vehicle_model,
    v.reg_plate AS vehicle_reg,
    a.agent_name
  FROM jobs j
  INNER JOIN clients c ON j.client_id = c.id
  LEFT JOIN transport t ON j.id = t.job_id
  LEFT JOIN profiles p ON j.driver_id = p.id
  LEFT JOIN vehicles v ON j.vehicle_id = v.id
  LEFT JOIN agents a ON j.agent_id = a.id
  WHERE UPPER(c.company_name) LIKE '%BLUEBERRY%'
    AND c.deleted_at IS NULL
)
SELECT 
  job_number AS "Job #",
  job_start_date AS "Job Date",
  TO_CHAR(pickup_date, 'DD/MM/YYYY HH24:MI') AS "Pickup Date & Time",
  COALESCE(transport_amount, amount, 0) AS "Amount (R)",
  job_status AS "Status",
  pickup_location AS "From",
  dropoff_location AS "To",
  driver_name AS "Driver",
  passenger_name AS "Passenger",
  pax AS "Pax",
  number_bags AS "Bags",
  location AS "Branch",
  order_date AS "Order Date",
  created_at AS "Created",
  notes AS "Notes"
FROM blueberry_jobs
ORDER BY job_start_date DESC, pickup_date DESC NULLS LAST;

-- Summary totals (run separately)
SELECT 
  COUNT(*) AS "Total Jobs",
  COUNT(DISTINCT job_id) AS "Unique Jobs",
  SUM(COALESCE(transport_amount, amount, 0)) AS "Total Amount (R)",
  MIN(job_start_date) AS "Earliest Job",
  MAX(job_start_date) AS "Latest Job"
FROM (
  SELECT 
    j.id AS job_id,
    j.job_start_date,
    COALESCE(t.amount, j.amount, 0) AS transport_amount,
    j.amount
  FROM jobs j
  INNER JOIN clients c ON j.client_id = c.id
  LEFT JOIN transport t ON j.id = t.job_id
  WHERE UPPER(c.company_name) LIKE '%BLUEBERRY%'
    AND c.deleted_at IS NULL
) subquery;



