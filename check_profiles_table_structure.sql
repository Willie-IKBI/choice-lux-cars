-- CHECK PROFILES TABLE STRUCTURE
-- This shows the actual columns in the profiles table

-- ========================================
-- STEP 1: SHOW PROFILES TABLE COLUMNS
-- ========================================

SELECT 
    'PROFILES TABLE COLUMNS:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- ========================================
-- STEP 2: SHOW SAMPLE PROFILES DATA
-- ========================================

SELECT 
    'SAMPLE PROFILES DATA:' as info,
    *
FROM profiles 
LIMIT 5;

-- ========================================
-- STEP 3: SHOW ALL USERS (CORRECTED)
-- ========================================

SELECT 
    'ALL USERS:' as info,
    id,
    display_name,
    role
FROM profiles 
LIMIT 10;
