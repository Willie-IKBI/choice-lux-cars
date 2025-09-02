-- =====================================================
-- CLEAR JOBS AND TRIPS TABLES
-- Choice Lux Cars - Complete Data Clearance
-- WARNING: This will DELETE ALL RECORDS from these tables
-- =====================================================

-- 1. CLEAR RELATED TABLES FIRST (to avoid foreign key constraint issues)
-- =====================================================

-- Clear job notification logs
DELETE FROM job_notification_log;
SELECT 'Cleared job_notification_log table' as status;

-- Clear trip progress records
DELETE FROM trip_progress;
SELECT 'Cleared trip_progress table' as status;

-- Clear driver flow records
DELETE FROM driver_flow;
SELECT 'Cleared driver_flow table' as status;

-- Clear transport records
DELETE FROM transport;
SELECT 'Cleared transport table' as status;

-- Clear expenses records
DELETE FROM expenses;
SELECT 'Cleared expenses table' as status;

-- Clear app notifications related to jobs
DELETE FROM app_notifications WHERE job_id IS NOT NULL;
SELECT 'Cleared job-related app_notifications' as status;

-- Clear notifications backup table
DELETE FROM notifications_backup;
SELECT 'Cleared notifications_backup table' as status;

-- Clear quotes and related data
-- =====================================================

-- Clear invoices first (foreign key dependency on quotes)
DELETE FROM invoices;
SELECT 'Cleared invoices table' as status;

-- Clear quotes transport details (foreign key dependency)
DELETE FROM quotes_transport_details;
SELECT 'Cleared quotes_transport_details table' as status;

-- Clear all quotes records
DELETE FROM quotes;
SELECT 'Cleared quotes table' as status;

-- Clear any app notifications related to quotes
DELETE FROM app_notifications WHERE notification_type LIKE '%quote%';
SELECT 'Cleared quote-related app_notifications' as status;

-- 2. CLEAR MAIN JOBS TABLE
-- =====================================================

-- Clear all records from jobs table
DELETE FROM jobs;
SELECT 'Cleared jobs table' as status;

-- 3. RESET IDENTITY COLUMNS (if needed)
-- =====================================================

-- Note: Identity columns automatically reset when all data is deleted
-- No manual sequence reset needed for GENERATED ALWAYS AS IDENTITY columns
SELECT 'Identity columns will auto-reset on next insert' as status;

-- 4. VERIFICATION
-- =====================================================

-- Check that all tables are empty
SELECT 
    'jobs' as table_name,
    COUNT(*) as record_count
FROM jobs
UNION ALL
SELECT 
    'driver_flow' as table_name,
    COUNT(*) as record_count
FROM driver_flow
UNION ALL
SELECT 
    'trip_progress' as table_name,
    COUNT(*) as record_count
FROM trip_progress
UNION ALL
SELECT 
    'transport' as table_name,
    COUNT(*) as record_count
FROM transport
UNION ALL
SELECT 
    'expenses' as table_name,
    COUNT(*) as record_count
FROM expenses
UNION ALL
SELECT 
    'job_notification_log' as table_name,
    COUNT(*) as record_count
FROM job_notification_log
UNION ALL
SELECT 
    'job-related app_notifications' as table_name,
    COUNT(*) as record_count
FROM app_notifications 
WHERE job_id IS NOT NULL
UNION ALL
SELECT 
    'notifications_backup' as table_name,
    COUNT(*) as record_count
FROM notifications_backup
UNION ALL
SELECT 
    'quotes' as table_name,
    COUNT(*) as record_count
FROM quotes
UNION ALL
SELECT 
    'invoices' as table_name,
    COUNT(*) as record_count
FROM invoices
UNION ALL
SELECT 
    'quotes_transport_details' as table_name,
    COUNT(*) as record_count
FROM quotes_transport_details
UNION ALL
SELECT 
    'quote-related app_notifications' as table_name,
    COUNT(*) as record_count
FROM app_notifications 
WHERE notification_type LIKE '%quote%';

-- =====================================================
-- CLEARANCE COMPLETE
-- All jobs and trip data has been removed
-- =====================================================
