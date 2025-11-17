# Supabase Broadcasting Management Guide

## **🎛️ SUPABASE DASHBOARD SETTINGS**

### **Option 1: Disable Realtime in Dashboard**

1. **Go to your Supabase Dashboard**
2. **Navigate to Database → Replication**
3. **Find the "Realtime" section**
4. **Disable realtime for specific tables:**
   - `jobs`
   - `notifications` 
   - `profiles`
   - `driver_flow`

### **Option 2: Configure Realtime Filters**

1. **Go to Database → Replication → Realtime**
2. **Set up filters to exclude certain operations:**
   ```sql
   -- Only broadcast specific events
   INSERT, UPDATE, DELETE ON jobs WHERE driver_id IS NOT NULL
   ```

### **Option 3: Use Database Policies**

1. **Go to Database → Policies**
2. **Create policies that prevent broadcasting:**
   ```sql
   -- Example policy to prevent realtime on notifications
   CREATE POLICY "no_realtime_notifications" ON notifications
   FOR ALL USING (false);
   ```

## **🔧 ALTERNATIVE APPROACHES**

### **Option 4: Use Edge Functions Instead**

Instead of database triggers, use Supabase Edge Functions:

```typescript
// supabase/functions/handle-job-assignment/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const { jobId, driverId } = await req.json()
  
  // Handle job assignment logic here
  // No database triggers needed
  
  return new Response(JSON.stringify({ success: true }))
})
```

### **Option 5: Use Database Functions Without HTTP**

Create functions that don't trigger realtime:

```sql
-- Function that doesn't trigger broadcasting
CREATE OR REPLACE FUNCTION create_notification_silent(
  p_user_id UUID,
  p_message TEXT,
  p_type TEXT
) RETURNS UUID AS $$
DECLARE
  notification_id UUID;
BEGIN
  -- Temporarily disable realtime
  SET session_replication_role = replica;
  
  INSERT INTO notifications (user_id, message, notification_type)
  VALUES (p_user_id, p_message, p_type)
  RETURNING id INTO notification_id;
  
  -- Re-enable realtime
  SET session_replication_role = origin;
  
  RETURN notification_id;
END;
$$ LANGUAGE plpgsql;
```

## **🎯 RECOMMENDED SOLUTION**

**Use the SQL script `disable_supabase_realtime_completely.sql`** - it's the most effective approach because:

1. ✅ **Completely disables broadcasting** for problematic tables
2. ✅ **No HTTP calls triggered** when inserting data
3. ✅ **Maintains data integrity** 
4. ✅ **Allows manual control** through Flutter app
5. ✅ **Easy to re-enable** if needed later

## **📱 FLUTTER INTEGRATION**

After disabling realtime, use the `JobAssignmentService` to handle notifications manually:

```dart
// This will work without HTTP errors
await JobAssignmentService.assignJobToDriver(
  jobId: 123,
  driverId: 'driver-uuid',
);
```

## **🔄 RE-ENABLING REALTIME (IF NEEDED)**

If you need realtime later, you can re-enable it:

```sql
-- Re-enable realtime for specific tables
ALTER TABLE jobs REPLICA IDENTITY DEFAULT;
ALTER TABLE notifications REPLICA IDENTITY DEFAULT;
```
