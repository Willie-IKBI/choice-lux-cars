-- Diagnostic Check - Current Database State
-- Applied: 2025-08-14
-- Description: Check current database state to understand what exists

-- 1. Check if start_job function exists
SELECT 
    routine_name, 
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'start_job';

-- 2. Check start_job function parameters
SELECT 
    parameter_name,
    data_type,
    parameter_mode,
    parameter_default,
    ordinal_position
FROM information_schema.parameters 
WHERE specific_schema = 'public' 
AND specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name = 'start_job'
)
ORDER BY ordinal_position;

-- 3. Check driver_flow table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'driver_flow'
ORDER BY ordinal_position;

-- 4. Check if driver_user column exists specifically
SELECT 
    column_name, 
    data_type 
FROM information_schema.columns 
WHERE table_name = 'driver_flow' 
AND column_name = 'driver_user';

-- 5. Check all functions that might be related to start_job
SELECT 
    routine_name, 
    routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND (routine_name LIKE '%start%' OR routine_name LIKE '%job%')
ORDER BY routine_name;
