-- Query to get all job details for BLUEBERRY client
-- Includes: job record, job time, amount, and date

SELECT 
  j.id AS job_id,
  j.job_number,
  j.job_status,
  j.order_date AS job_order_date,
  j.job_start_date AS job_date,
  j.amount AS job_amount,
  j.passenger_name,
  j.passenger_contact,
  j.pax AS passenger_count,
  j.number_bags,
  j.location AS job_location,
  j.notes AS job_notes,
  j.created_at AS job_created_at,
  j.updated_at AS job_updated_at,
  -- Transport details (pickup times and locations)
  t.id AS transport_id,
  t.pickup_date AS pickup_datetime,
  DATE(t.pickup_date) AS pickup_date,
  TO_CHAR(t.pickup_date, 'HH24:MI') AS pickup_time,
  t.pickup_location,
  t.dropoff_location,
  t.amount AS transport_amount,
  t.client_pickup_time AS actual_pickup_time,
  t.client_dropoff_time AS actual_dropoff_time,
  t.notes AS transport_notes,
  -- Client information
  c.id AS client_id,
  c.company_name,
  c.contact_person,
  c.contact_email,
  c.contact_number,
  -- Driver information
  p.display_name AS driver_name,
  -- Vehicle information  
  v.make AS vehicle_make,
  v.model AS vehicle_model,
  v.reg_plate AS vehicle_registration,
  -- Agent information
  a.agent_name
FROM jobs j
INNER JOIN clients c ON j.client_id = c.id
LEFT JOIN transport t ON j.id = t.job_id
LEFT JOIN profiles p ON j.driver_id = p.id
LEFT JOIN vehicles v ON j.vehicle_id = v.id
LEFT JOIN agents a ON j.agent_id = a.id
WHERE UPPER(c.company_name) LIKE '%BLUEBERRY%'
  AND c.deleted_at IS NULL  -- Exclude soft-deleted clients
ORDER BY 
  j.job_start_date DESC,
  t.pickup_date DESC NULLS LAST,
  j.created_at DESC;



