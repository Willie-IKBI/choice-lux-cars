-- =====================================================
-- JOBS TABLE DATA CLEANUP SCRIPT
-- Choice Lux Cars - Data Quality Cleanup
-- Based on actual schema structure
-- =====================================================

-- 1. CLEAN UP NULL/EMPTY VALUES
-- =====================================================

-- Fix empty strings to NULL for better data consistency
UPDATE jobs 
SET 
    passenger_name = NULL 
WHERE passenger_name = '' OR passenger_name = 'null';

UPDATE jobs 
SET 
    passenger_contact = NULL 
WHERE passenger_contact = '' OR passenger_contact = 'null';

UPDATE jobs 
SET 
    notes = NULL 
WHERE notes = '' OR notes = 'null';

UPDATE jobs 
SET 
    location = NULL 
WHERE location = '' OR location = 'null';

UPDATE jobs 
SET 
    cancel_reason = NULL 
WHERE cancel_reason = '' OR cancel_reason = 'null';

UPDATE jobs 
SET 
    voucher_pdf = NULL 
WHERE voucher_pdf = '' OR voucher_pdf = 'null';

UPDATE jobs 
SET 
    invoice_pdf = NULL 
WHERE invoice_pdf = '' OR invoice_pdf = 'null';

UPDATE jobs 
SET 
    created_by = 'Unknown' 
WHERE created_by = '' OR created_by = 'null' OR created_by IS NULL;

-- 2. FIX INVALID DATES
-- =====================================================

-- Fix future order dates (shouldn't be in the future)
UPDATE jobs 
SET order_date = CURRENT_DATE 
WHERE order_date > CURRENT_DATE;

-- Fix future job start dates (shouldn't be in the future unless it's a scheduled job)
UPDATE jobs 
SET job_start_date = CURRENT_DATE 
WHERE job_start_date > CURRENT_DATE + INTERVAL '30 days';

-- Fix invalid created_at dates
UPDATE jobs 
SET created_at = CURRENT_TIMESTAMP 
WHERE created_at > CURRENT_TIMESTAMP OR created_at < '2020-01-01';

-- Fix invalid updated_at dates
UPDATE jobs 
SET updated_at = CURRENT_TIMESTAMP 
WHERE updated_at > CURRENT_TIMESTAMP OR updated_at < created_at;

-- Fix invalid confirmed_at dates
UPDATE jobs 
SET confirmed_at = CURRENT_TIMESTAMP 
WHERE confirmed_at > CURRENT_TIMESTAMP OR confirmed_at < created_at;

-- 3. FIX AMOUNT ISSUES
-- =====================================================

-- Fix negative amounts
UPDATE jobs 
SET amount = ABS(amount) 
WHERE amount < 0;

-- Fix extremely high amounts (over R100,000 - adjust as needed)
UPDATE jobs 
SET amount = 1000.00 
WHERE amount > 100000;

-- Fix zero amounts for completed jobs (should have some value)
UPDATE jobs 
SET amount = 500.00 
WHERE amount = 0 AND job_status IN ('completed', 'closed');

-- 4. FIX STATUS INCONSISTENCIES
-- =====================================================

-- Standardize status values based on your schema
UPDATE jobs 
SET job_status = 'open' 
WHERE job_status IN ('new', 'pending', '');

UPDATE jobs 
SET job_status = 'assigned' 
WHERE job_status IN ('assigned', 'allocated');

UPDATE jobs 
SET job_status = 'in_progress' 
WHERE job_status IN ('started', 'active', 'running', 'in_progress');

UPDATE jobs 
SET job_status = 'completed' 
WHERE job_status IN ('closed', 'finished', 'done', 'completed');

UPDATE jobs 
SET job_status = 'cancelled' 
WHERE job_status IN ('canceled', 'cancelled');

-- 5. FIX PAX (PASSENGER COUNT) ISSUES
-- =====================================================

-- Fix negative passenger counts
UPDATE jobs 
SET pax = ABS(pax) 
WHERE pax < 0;

-- Fix zero passenger counts (should be at least 1)
UPDATE jobs 
SET pax = 1 
WHERE pax = 0;

-- Fix extremely high passenger counts
UPDATE jobs 
SET pax = 10 
WHERE pax > 50;

-- 6. FIX BOOLEAN FIELDS
-- =====================================================

-- Ensure boolean fields are properly set
UPDATE jobs 
SET amount_collect = false 
WHERE amount_collect IS NULL;

UPDATE jobs 
SET driver_confirm_ind = false 
WHERE driver_confirm_ind IS NULL;

UPDATE jobs 
SET is_confirmed = false 
WHERE is_confirmed IS NULL;

-- 7. CLEAN UP JOB NUMBERS
-- =====================================================

-- Fix empty job numbers
UPDATE jobs 
SET job_number = 'JOB-' || id::text 
WHERE job_number = '' OR job_number IS NULL;

-- Remove duplicate job numbers (keep the one with the lowest ID)
UPDATE jobs 
SET job_number = 'JOB-' || id::text || '-DUP' 
WHERE job_number IN (
    SELECT job_number 
    FROM jobs 
    WHERE job_number IS NOT NULL 
    GROUP BY job_number 
    HAVING COUNT(*) > 1
) AND id NOT IN (
    SELECT MIN(id) 
    FROM jobs 
    WHERE job_number IS NOT NULL 
    GROUP BY job_number 
    HAVING COUNT(*) > 1
);

-- 8. FIX FOREIGN KEY REFERENCES
-- =====================================================

-- Check for orphaned records (jobs without valid references)
-- Note: These are commented out - uncomment only if you want to delete orphaned records

-- Delete jobs without valid client_id
-- DELETE FROM jobs WHERE client_id IS NULL OR client_id NOT IN (SELECT id FROM clients);

-- Delete jobs without valid vehicle_id  
-- DELETE FROM jobs WHERE vehicle_id IS NULL OR vehicle_id NOT IN (SELECT id FROM vehicles);

-- Delete jobs without valid agent_id
-- DELETE FROM jobs WHERE agent_id IS NULL OR agent_id NOT IN (SELECT id FROM agents);

-- Delete jobs without valid driver_id (if driver is required)
-- DELETE FROM jobs WHERE driver_id IS NULL OR driver_id NOT IN (SELECT id FROM profiles);

-- 9. CLEAN UP TEXT FIELDS
-- =====================================================

-- Remove extra whitespace
UPDATE jobs 
SET 
    passenger_name = TRIM(passenger_name),
    passenger_contact = TRIM(passenger_contact),
    notes = TRIM(notes),
    location = TRIM(location),
    cancel_reason = TRIM(cancel_reason),
    created_by = TRIM(created_by),
    job_number = TRIM(job_number)
WHERE 
    passenger_name IS NOT NULL OR 
    passenger_contact IS NOT NULL OR 
    notes IS NOT NULL OR 
    location IS NOT NULL OR 
    cancel_reason IS NOT NULL OR 
    created_by IS NOT NULL OR 
    job_number IS NOT NULL;

-- 10. FIX NUMBER_BAGS FIELD
-- =====================================================

-- Fix empty number_bags
UPDATE jobs 
SET number_bags = '0' 
WHERE number_bags = '' OR number_bags = 'null' OR number_bags IS NULL;

-- Fix invalid number_bags (should be numeric)
UPDATE jobs 
SET number_bags = '0' 
WHERE number_bags !~ '^[0-9]+$';

-- 11. CLEAN UP QUOTE REFERENCES
-- =====================================================

-- Fix invalid quote_no references
UPDATE jobs 
SET quote_no = NULL 
WHERE quote_no IS NOT NULL AND quote_no NOT IN (SELECT id FROM quotes);

-- 12. FINAL VALIDATION AND CLEANUP
-- =====================================================

-- Update all updated_at timestamps
UPDATE jobs 
SET updated_at = CURRENT_TIMESTAMP 
WHERE updated_at < created_at;

-- Ensure created_at is not null
UPDATE jobs 
SET created_at = CURRENT_TIMESTAMP 
WHERE created_at IS NULL;

-- 13. CLEAN UP RELATED TABLES
-- =====================================================

-- Clean up orphaned driver_flow records
DELETE FROM driver_flow 
WHERE job_id NOT IN (SELECT id FROM jobs);

-- Clean up orphaned expenses records
DELETE FROM expenses 
WHERE job_id NOT IN (SELECT id FROM jobs);

-- Clean up orphaned transport records
DELETE FROM transport 
WHERE job_id NOT IN (SELECT id FROM jobs);

-- Clean up orphaned trip_progress records
DELETE FROM trip_progress 
WHERE job_id NOT IN (SELECT id FROM jobs);

-- Clean up orphaned job_notification_log records
DELETE FROM job_notification_log 
WHERE job_id NOT IN (SELECT id FROM jobs);

-- 14. GENERATE CLEANUP REPORT
-- =====================================================

-- Count records by status
SELECT 
    'Jobs by Status' as report_type,
    job_status,
    COUNT(*) as count
FROM jobs 
GROUP BY job_status
ORDER BY job_status;

-- Count records by year
SELECT 
    'Jobs by Year' as report_type,
    EXTRACT(YEAR FROM created_at) as year,
    COUNT(*) as count
FROM jobs 
GROUP BY EXTRACT(YEAR FROM created_at)
ORDER BY year;

-- Count records with issues
SELECT 
    'Data Quality Issues' as report_type,
    'Jobs with NULL client_id' as issue,
    COUNT(*) as count
FROM jobs 
WHERE client_id IS NULL
UNION ALL
SELECT 
    'Data Quality Issues' as report_type,
    'Jobs with NULL vehicle_id' as issue,
    COUNT(*) as count
FROM jobs 
WHERE vehicle_id IS NULL
UNION ALL
SELECT 
    'Data Quality Issues' as report_type,
    'Jobs with NULL driver_id' as issue,
    COUNT(*) as count
FROM jobs 
WHERE driver_id IS NULL
UNION ALL
SELECT 
    'Data Quality Issues' as report_type,
    'Jobs with zero amount' as issue,
    COUNT(*) as count
FROM jobs 
WHERE amount = 0
UNION ALL
SELECT 
    'Data Quality Issues' as report_type,
    'Jobs with zero pax' as issue,
    COUNT(*) as count
FROM jobs 
WHERE pax = 0
UNION ALL
SELECT 
    'Data Quality Issues' as report_type,
    'Jobs with NULL agent_id' as issue,
    COUNT(*) as count
FROM jobs 
WHERE agent_id IS NULL;

-- Show total job count
SELECT 
    'Summary' as report_type,
    'Total Jobs' as metric,
    COUNT(*) as count
FROM jobs;

-- =====================================================
-- CLEANUP COMPLETE
-- =====================================================
