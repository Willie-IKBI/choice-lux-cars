-- Check Actual Database Schema
-- Run this in Supabase Dashboard SQL Editor to see what columns actually exist

-- Check driver_flow table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'driver_flow'
ORDER BY ordinal_position;

-- Check if driver_user column exists
SELECT 
    column_name, 
    data_type 
FROM information_schema.columns 
WHERE table_name = 'driver_flow' 
AND column_name = 'driver_user';

-- Check all driver-related columns
SELECT 
    column_name, 
    data_type 
FROM information_schema.columns 
WHERE table_name = 'driver_flow' 
AND (column_name LIKE '%driver%' OR column_name LIKE '%user%' OR column_name LIKE '%profile%')
ORDER BY column_name;

-- Check if start_job function exists
SELECT 
    routine_name, 
    routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'start_job';
