-- COMPREHENSIVE DATABASE INSPECTION
-- Run this in your Supabase SQL editor to get detailed database information

-- ========================================
-- STEP 1: CHECK ALL TABLES AND THEIR STRUCTURE
-- ========================================

-- Show all tables in the public schema
SELECT 
    'ALL TABLES:' as info,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- ========================================
-- STEP 2: CHECK NOTIFICATIONS TABLE STRUCTURE
-- ========================================

-- Detailed notifications table structure
SELECT 
    'NOTIFICATIONS TABLE STRUCTURE:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'notifications' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ========================================
-- STEP 3: CHECK JOBS TABLE STRUCTURE
-- ========================================

-- Detailed jobs table structure
SELECT 
    'JOBS TABLE STRUCTURE:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'jobs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ========================================
-- STEP 4: CHECK ALL TRIGGERS
-- ========================================

-- All triggers on jobs table
SELECT 
    'TRIGGERS ON JOBS TABLE:' as info,
    t.tgname as trigger_name,
    p.proname as function_name,
    t.tgenabled as enabled,
    t.tgisinternal as is_internal,
    CASE 
        WHEN t.tgenabled = 'D' THEN 'Disabled'
        WHEN t.tgenabled = 'O' THEN 'Enabled'
        WHEN t.tgenabled = 'R' THEN 'Replica'
        WHEN t.tgenabled = 'A' THEN 'Always'
        ELSE 'Unknown'
    END as status
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE c.relname = 'jobs' AND t.tgisinternal = false
ORDER BY t.tgname;

-- All triggers on notifications table
SELECT 
    'TRIGGERS ON NOTIFICATIONS TABLE:' as info,
    t.tgname as trigger_name,
    p.proname as function_name,
    t.tgenabled as enabled,
    t.tgisinternal as is_internal,
    CASE 
        WHEN t.tgenabled = 'D' THEN 'Disabled'
        WHEN t.tgenabled = 'O' THEN 'Enabled'
        WHEN t.tgenabled = 'R' THEN 'Replica'
        WHEN t.tgenabled = 'A' THEN 'Always'
        ELSE 'Unknown'
    END as status
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE c.relname = 'notifications' AND t.tgisinternal = false
ORDER BY t.tgname;

-- ========================================
-- STEP 5: CHECK ALL FUNCTIONS
-- ========================================

-- All functions in public schema
SELECT 
    'ALL FUNCTIONS:' as info,
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
ORDER BY p.proname;

-- ========================================
-- STEP 6: CHECK REPLICA IDENTITY SETTINGS
-- ========================================

-- Replica identity settings for key tables
SELECT 
    'REPLICA IDENTITY SETTINGS:' as info,
    schemaname,
    tablename,
    CASE 
        WHEN relreplident = 'd' THEN 'DEFAULT'
        WHEN relreplident = 'n' THEN 'NOTHING'
        WHEN relreplident = 'f' THEN 'FULL'
        WHEN relreplident = 'i' THEN 'INDEX'
        ELSE 'UNKNOWN'
    END as replica_identity
FROM pg_stat_user_tables 
WHERE tablename IN ('jobs', 'notifications', 'profiles')
ORDER BY tablename;

-- ========================================
-- STEP 7: CHECK ROW LEVEL SECURITY
-- ========================================

-- RLS status for key tables
SELECT 
    'ROW LEVEL SECURITY STATUS:' as info,
    schemaname,
    tablename,
    CASE 
        WHEN rowsecurity THEN 'ENABLED'
        ELSE 'DISABLED'
    END as rls_status
FROM pg_tables 
WHERE tablename IN ('jobs', 'notifications', 'profiles')
ORDER BY tablename;

-- ========================================
-- STEP 8: CHECK SAMPLE DATA
-- ========================================

-- Sample notifications
SELECT 
    'SAMPLE NOTIFICATIONS:' as info,
    id,
    user_id,
    message,
    notification_type,
    is_read,
    created_at
FROM notifications 
ORDER BY created_at DESC
LIMIT 5;

-- Sample jobs
SELECT 
    'SAMPLE JOBS:' as info,
    id,
    job_number,
    passenger_name,
    driver_id,
    driver_confirm_ind,
    created_at
FROM jobs 
ORDER BY created_at DESC
LIMIT 5;

-- Sample profiles
SELECT 
    'SAMPLE PROFILES:' as info,
    id,
    display_name,
    role,
    created_at
FROM profiles 
ORDER BY created_at DESC
LIMIT 5;

-- ========================================
-- STEP 9: CHECK FOR HTTP-RELATED FUNCTIONS
-- ========================================

-- Look for any functions that might use HTTP
SELECT 
    'POTENTIAL HTTP FUNCTIONS:' as info,
    p.proname as function_name,
    p.prosrc as function_source
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND (p.prosrc ILIKE '%http%' 
       OR p.prosrc ILIKE '%net.%'
       OR p.prosrc ILIKE '%webhook%'
       OR p.prosrc ILIKE '%supabase%'
       OR p.prosrc ILIKE '%realtime%')
ORDER BY p.proname;

-- ========================================
-- STEP 10: CHECK EXTENSIONS
-- ========================================

-- Installed extensions
SELECT 
    'INSTALLED EXTENSIONS:' as info,
    extname as extension_name,
    extversion as version
FROM pg_extension
ORDER BY extname;
