-- Bluberry jobs between 21 and 31 October 2025
WITH first_trip AS (
  SELECT DISTINCT ON (t.job_id)
    t.job_id,
    t.pickup_location,
    t.dropoff_location,
    t.pickup_date
  FROM transport t
  WHERE t.pickup_date IS NOT NULL
  ORDER BY t.job_id, t.pickup_date
)
SELECT
  j.id AS confirmation_number,
  j.confirmed_at AS job_confirmation_date,
  j.job_start_date AS job_date,
  j.passenger_name,
  ft.pickup_location,
  ft.dropoff_location,
  CONCAT_WS(' ', v.make, v.model, v.reg_plate) AS vehicle,
  c.company_name AS client_name,
  j.amount AS rate
FROM jobs j
JOIN clients c ON c.id = j.client_id
LEFT JOIN vehicles v ON v.id = j.vehicle_id
LEFT JOIN first_trip ft ON ft.job_id = j.id
WHERE c.company_name ILIKE 'blueberry'
  AND j.job_start_date BETWEEN DATE '2025-10-21' AND DATE '2025-10-31'
ORDER BY j.job_start_date, j.id;

