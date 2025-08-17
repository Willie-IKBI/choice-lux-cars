# Job Flow Fix Implementation Guide

## **Overview**
This guide provides step-by-step instructions to fix the ambiguous column reference error in the job flow system.

## **Root Cause**
The error occurs because:
1. **Multiple conflicting database functions** with different parameter signatures
2. **Ambiguous column references** where function parameters have the same name as table columns
3. **Schema inconsistencies** between Flutter app expectations and actual database structure

## **Solution Strategy**
1. **Clean up all conflicting functions**
2. **Create single, consistent functions** with proper parameter qualification
3. **Update Flutter app** to match the new function signatures
4. **Test thoroughly** to ensure the fix works

---

## **Phase 1: Database Fix (Run in Supabase SQL Editor)**

### **Step 1: Execute the Complete Fix**
1. Open your Supabase Dashboard
2. Go to SQL Editor
3. Copy and paste the entire contents of `fix_job_flow_schema.sql`
4. Click "Run" to execute

### **Step 2: Verify Functions Created**
After running the SQL, execute this verification query:
```sql
SELECT 
    routine_name, 
    routine_type,
    specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('start_job', 'arrive_at_pickup', 'passenger_onboard', 'arrive_at_dropoff', 'complete_trip')
ORDER BY routine_name;
```

**Expected Result:** You should see 5 functions listed with unique identifiers.

### **Step 3: Test Function (Optional)**
```sql
-- Replace 1 with an actual job ID from your database
SELECT start_job(1, 12345.0, 'test_image_url.jpg', -26.2041, 28.0473, 10.0);
```

---

## **Phase 2: Flutter App Update**

### **Step 1: Verify Changes Applied**
The following changes have been made to `lib/features/jobs/services/driver_flow_api_service.dart`:

1. **startJob method**: Changed `'job_id'` to `'p_job_id'`
2. **arriveAtPickup method**: Changed `'job_id'` to `'p_job_id'`
3. **passengerOnboard method**: Changed `'job_id'` to `'p_job_id'`
4. **arriveAtDropoff method**: Changed `'job_id'` to `'p_job_id'`
5. **completeTrip method**: Changed `'job_id'` to `'p_job_id'`

### **Step 2: Build and Test**
```bash
# Clean and rebuild the app
flutter clean
flutter pub get
flutter build apk --debug  # or flutter run
```

---

## **Phase 3: Testing**

### **Step 1: Test Job Flow**
1. **Open the app** and log in as a driver
2. **Navigate to Jobs screen**
3. **Select a job** assigned to the driver
4. **Tap "Start Job"** button
5. **Fill in the vehicle collection modal**:
   - Enter odometer reading
   - Capture odometer image
   - Ensure GPS location is captured
6. **Tap "Confirm"** to start the job

### **Step 2: Monitor Console Logs**
Look for these success messages:
```
=== STARTING JOB WITH FIXED RPC FUNCTION ===
Job ID: [job_id]
=== JOB STARTED SUCCESSFULLY ===
```

### **Step 3: Verify Database Records**
Check that records are created in:
- `driver_flow` table: Job started with `current_step = 'pickup_arrival'`
- `trip_progress` table: Initial trip record with `status = 'pending'`
- `jobs` table: Job status updated to `'started'`

### **Step 4: Test Complete Flow**
Continue through the job flow:
1. **Arrive at Pickup** - Should update trip_progress and move to next step
2. **Passenger Onboard** - Should update trip_progress and move to next step
3. **Arrive at Dropoff** - Should update trip_progress and move to next step
4. **Complete Trip** - Should update trip_progress and move to vehicle return

---

## **Phase 4: Troubleshooting**

### **If You Still Get Errors:**

#### **Error: "Function not found"**
- Verify the SQL script ran successfully
- Check that all 5 functions exist in the database
- Ensure you're using the correct parameter names (`p_job_id`)

#### **Error: "Column reference is ambiguous"**
- The fix should resolve this completely
- If it persists, check for any remaining conflicting functions

#### **Error: "Permission denied"**
- Ensure the functions have proper permissions granted
- Check that the user has authenticated access

#### **Error: "Foreign key constraint"**
- Verify that the job ID exists in the `jobs` table
- Ensure the driver is properly assigned to the job

### **Debugging Steps:**
1. **Check function signatures**:
```sql
SELECT 
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname IN ('start_job', 'arrive_at_pickup', 'passenger_onboard', 'arrive_at_dropoff', 'complete_trip');
```

2. **Check table structure**:
```sql
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'driver_flow'
ORDER BY ordinal_position;
```

3. **Test with minimal data**:
```sql
-- Create a test job first
INSERT INTO jobs (client_id, agent_id, driver_id, job_status) 
VALUES (1, 1, 'your-driver-uuid', 'assigned') 
RETURNING id;

-- Then test the function with the returned job ID
```

---

## **Phase 5: Rollback Plan**

### **If Issues Occur:**
1. **Backup current state** (if needed)
2. **Drop the new functions**:
```sql
DROP FUNCTION IF EXISTS start_job(bigint, numeric, text, numeric, numeric, numeric);
DROP FUNCTION IF EXISTS arrive_at_pickup(bigint, integer, numeric, numeric, numeric);
DROP FUNCTION IF EXISTS passenger_onboard(bigint, integer);
DROP FUNCTION IF EXISTS arrive_at_dropoff(bigint, integer, numeric, numeric, numeric);
DROP FUNCTION IF EXISTS complete_trip(bigint, integer, text);
```

3. **Revert Flutter changes** to use the original parameter names

---

## **Success Criteria**

The fix is successful when:
- ✅ **No ambiguous column reference errors**
- ✅ **Job flow progresses through all steps**
- ✅ **Database records are created correctly**
- ✅ **Flutter app shows proper progress updates**
- ✅ **All job flow functions work without errors**

---

## **Support**

If you encounter issues:
1. **Check the console logs** for detailed error messages
2. **Verify database function signatures** match Flutter app calls
3. **Ensure all required columns exist** in the database tables
4. **Test with a fresh job** to avoid any cached state issues

The fix addresses the core issue by using explicit parameter names (`p_job_id`) to avoid conflicts with table column names (`job_id`).
