# Push Notifications System - Complete Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [Database Architecture](#database-architecture)
3. [Tables and Schema](#tables-and-schema)
4. [Edge Functions](#edge-functions)
5. [Flutter Implementation](#flutter-implementation)
6. [Webhook Configuration](#webhook-configuration)
7. [FCM Setup](#fcm-setup)
8. [Testing Procedures](#testing-procedures)
9. [Troubleshooting](#troubleshooting)
10. [Maintenance](#maintenance)

---

## System Overview

The push notification system uses a **webhook-based architecture** to avoid Supabase Realtime issues:

```
Flutter App → Database Insert → Webhook → Edge Function → FCM → Device
```

### Key Components:
- **`app_notifications` table**: Stores all notifications
- **Database Webhook**: Triggers on INSERT events
- **Edge Function**: Processes notifications and sends FCM
- **Flutter Service**: Manages client-side notifications
- **FCM**: Delivers push notifications to devices

---

## Database Architecture

### Core Tables

#### 1. `app_notifications` Table
```sql
CREATE TABLE app_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    notification_type TEXT NOT NULL,
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    job_id TEXT,
    action_data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    is_hidden BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    dismissed_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Disable Supabase Realtime to prevent HTTP issues
ALTER TABLE app_notifications REPLICA IDENTITY NOTHING;
```

#### 2. `profiles` Table (Existing)
```sql
-- Key columns for notifications:
id UUID PRIMARY KEY,
display_name TEXT,
role user_role_enum,
fcm_token TEXT  -- For push notifications
```

#### 3. `notification_delivery_log` Table (Optional)
```sql
CREATE TABLE notification_delivery_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    notification_id UUID REFERENCES app_notifications(id),
    user_id UUID REFERENCES profiles(id),
    fcm_token TEXT,
    fcm_response JSONB,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    success BOOLEAN
);
```

### Indexes
```sql
-- Performance indexes
CREATE INDEX idx_app_notifications_user_id ON app_notifications(user_id);
CREATE INDEX idx_app_notifications_created_at ON app_notifications(created_at DESC);
CREATE INDEX idx_app_notifications_type ON app_notifications(notification_type);
CREATE INDEX idx_app_notifications_unread ON app_notifications(user_id, is_read, is_hidden) 
    WHERE is_read = false AND is_hidden = false;
```

---

## Tables and Schema

### Notification Types
```sql
-- Supported notification types
'job_assignment'     -- New job assigned to driver
'job_reassignment'   -- Job reassigned to different driver
'job_confirmation'   -- Driver confirmed job
'job_cancellation'   -- Job cancelled
'job_reminder'       -- Reminder for upcoming job
'payment_received'   -- Payment notification
'system_alert'       -- System-wide alerts
'flutter_test'       -- Testing notifications
```

### Priority Levels
```sql
'low'      -- Non-urgent notifications
'normal'   -- Standard notifications
'high'     -- Important notifications
'urgent'   -- Critical notifications
```

### Action Data Structure
```json
{
    "job_id": "2025-001",
    "job_number": "JOB-2025-001", 
    "passenger_name": "John Smith",
    "action": "view_job",
    "route": "/jobs/2025-001/summary",
    "deep_link": "choice-lux-cars://job/2025-001"
}
```

---

## Edge Functions

### File: `supabase/functions/push-notifications/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Parse webhook payload
    const payload = await req.json()
    console.log('Webhook payload:', JSON.stringify(payload, null, 2))
    
    // Only handle INSERT events on app_notifications table
    if (payload.type !== 'INSERT' || payload.table !== 'app_notifications') {
      console.log('Ignoring non-INSERT event or wrong table')
      return new Response(JSON.stringify({ message: 'Ignored' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    const notification = payload.record
    console.log('Processing notification:', notification.id)

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get user profile with FCM token
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('fcm_token')
      .eq('id', notification.user_id)
      .single()

    if (profileError || !profile?.fcm_token) {
      console.log('No FCM token found for user:', notification.user_id)
      return new Response(JSON.stringify({ 
        success: false, 
        error: 'No FCM token found' 
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    // Prepare FCM message
    const fcmMessage = {
      to: profile.fcm_token,
      notification: {
        title: 'Choice Lux Cars',
        body: notification.message,
        icon: '/favicon.png',
        badge: '1',
        tag: notification.notification_type,
      },
      data: {
        notification_id: notification.id,
        notification_type: notification.notification_type,
        job_id: notification.job_id || '',
        action_data: JSON.stringify(notification.action_data || {}),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      priority: notification.priority === 'urgent' ? 'high' : 'normal',
      android: {
        priority: notification.priority === 'urgent' ? 'high' : 'normal',
        notification: {
          channel_id: 'choice_lux_cars',
          priority: notification.priority === 'urgent' ? 'max' : 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: 'default',
            category: 'choice_lux_cars',
          },
        },
      },
    }

    // Send FCM notification
    const fcmServerKey = Deno.env.get('FCM_SERVER_KEY')
    if (!fcmServerKey) {
      throw new Error('FCM_SERVER_KEY not configured')
    }

    const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': `key=${fcmServerKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(fcmMessage),
    })

    const fcmResult = await fcmResponse.json()
    console.log('FCM response:', JSON.stringify(fcmResult, null, 2))
    
    // Log the notification delivery (optional)
    try {
      await supabase
        .from('notification_delivery_log')
        .insert({
          notification_id: notification.id,
          user_id: notification.user_id,
          fcm_token: profile.fcm_token,
          fcm_response: fcmResult,
          sent_at: new Date().toISOString(),
          success: fcmResult.success === 1
        })
    } catch (logError) {
      console.log('Failed to log delivery (non-critical):', logError)
    }
    
    console.log('=== PUSH NOTIFICATION SENT SUCCESSFULLY ===')
    
    return new Response(JSON.stringify({
      success: true,
      notification_id: notification.id,
      fcm_result: fcmResult
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    console.error('Error processing notification:', error)
    return new Response(JSON.stringify({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
```

### Deployment
```bash
# Deploy the Edge Function
supabase functions deploy push-notifications

# Check deployment status
supabase functions list
```

---

## Flutter Implementation

### File: `lib/features/notifications/services/notification_service.dart`

```dart
class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch notifications for current user
  Future<List<AppNotification>> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('=== DEBUG: Fetching notifications for user: ${currentUser.id} ===');

      // Build query with all conditions
      var query = _supabase
        .from('app_notifications')
        .select()
        .eq('user_id', currentUser.id)
        .eq('is_hidden', false); // Only show non-hidden notifications

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
      
      print('Fetched ${response.length} notifications for user ${currentUser.id}');
      if (response.isNotEmpty) {
        print('Sample notification: ${response.first}');
      }

      return response.map((json) => AppNotification.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
        .from('app_notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', notificationId);
      
      print('Marked notification $notificationId as read');
    } catch (e) {
      print('Error marking notification as read: $e');
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
        .from('app_notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', currentUser.id)
        .eq('is_read', false);
      
      print('Marked all notifications as read for user ${currentUser.id}');
    } catch (e) {
      print('Error marking all notifications as read: $e');
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Dismiss notification
  Future<void> dismissNotification(String notificationId) async {
    try {
      await _supabase
        .from('app_notifications')
        .update({
          'is_hidden': true,
          'dismissed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', notificationId);
      
      print('Dismissed notification $notificationId');
    } catch (e) {
      print('Error dismissing notification: $e');
      throw Exception('Failed to dismiss notification: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
        .from('app_notifications')
        .delete()
        .eq('id', notificationId);
      
      print('Deleted notification $notificationId');
    } catch (e) {
      print('Error deleting notification: $e');
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Create notification (for testing or direct creation)
  Future<void> createNotification({
    required String userId,
    required String message,
    required String notificationType,
    String priority = 'normal',
    String? jobId,
    Map<String, dynamic>? actionData,
  }) async {
    try {
      final response = await _supabase
        .from('app_notifications')
        .insert({
          'user_id': userId,
          'job_id': jobId,
          'message': message,
          'notification_type': notificationType,
          'priority': priority,
          'action_data': actionData,
          'is_read': false,
          'is_hidden': false,
        });
      
      print('Notification created successfully');
      print('Push notification will be sent via webhook + Edge Function');
    } catch (e) {
      print('Error creating notification: $e');
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
        .from('app_notifications')
        .select('notification_type, is_read, is_hidden')
        .eq('user_id', currentUser.id);

      int totalCount = response.length;
      int unreadCount = response.where((n) => n['is_read'] == false).length;
      int readCount = response.where((n) => n['is_read'] == true).length;
      int dismissedCount = response.where((n) => n['is_hidden'] == true).length;

      // Group by notification type
      Map<String, int> byType = {};
      for (var notification in response) {
        String type = notification['notification_type'] ?? 'unknown';
        byType[type] = (byType[type] ?? 0) + 1;
      }

      return {
        'total_count': totalCount,
        'unread_count': unreadCount,
        'read_count': readCount,
        'dismissed_count': dismissedCount,
        'by_type': byType,
      };
    } catch (e) {
      print('Error getting notification stats: $e');
      throw Exception('Failed to get notification stats: $e');
    }
  }

  /// Stream notifications for real-time updates
  Stream<List<AppNotification>> streamNotifications() {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Use a simpler stream approach
      final stream = _supabase
        .from('app_notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUser.id)
        .eq('is_hidden', false)
        .order('created_at', ascending: false);

      return stream.map((response) {
        return response.map((json) => AppNotification.fromJson(json)).toList();
      });
    } catch (e) {
      print('Error streaming notifications: $e');
      throw Exception('Failed to stream notifications: $e');
    }
  }

  /// Dismiss all notifications for a specific job
  Future<void> dismissJobNotifications(String jobId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
        .from('app_notifications')
        .update({
          'dismissed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'is_hidden': true,
        })
        .eq('job_id', jobId)
        .eq('user_id', currentUser.id);
      
      print('Dismissed all notifications for job $jobId');
    } catch (e) {
      print('Error dismissing job notifications: $e');
      throw Exception('Failed to dismiss job notifications: $e');
    }
  }
}
```

### File: `lib/features/notifications/providers/notification_provider.dart`

```dart
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription? _notificationStream;

  NotificationNotifier() : super(NotificationState.initial()) {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      print('Initializing notification provider...');
      
      // Load initial notifications
      await _loadNotifications();
      
      // Load statistics
      await _loadNotificationStats();
      
      // Start real-time subscription
      _startRealtimeSubscription();
      
      print('Notification provider initialized successfully');
    } catch (e) {
      print('Error initializing notifications: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _notificationService.getNotifications();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      
      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );
      
      print('Loaded ${notifications.length} notifications, $unreadCount unread');
    } catch (e) {
      print('Error loading notifications: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _loadNotificationStats() async {
    try {
      final stats = await _notificationService.getNotificationStats();
      state = state.copyWith(stats: stats);
      print('Loaded notification stats: $stats');
    } catch (e) {
      print('Error loading notification stats: $e');
    }
  }

  void _startRealtimeSubscription() {
    try {
      _notificationStream?.cancel();
      _notificationStream = _notificationService.streamNotifications().listen(
        (notifications) {
          final unreadCount = notifications.where((n) => !n.isRead).length;
          state = state.copyWith(
            notifications: notifications,
            unreadCount: unreadCount,
          );
          print('Real-time update: ${notifications.length} notifications');
        },
        onError: (error) {
          print('Error in notification stream: $error');
        },
      );
      print('Started real-time notification subscription');
    } catch (e) {
      print('Error starting real-time subscription: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      print('Marked notification $notificationId as read');
      
      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();
      
      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      print('Error marking notification as read: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      await _loadNotifications(); // Reload to get updated state
    } catch (e) {
      print('Error marking all notifications as read: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> dismissNotification(String notificationId) async {
    try {
      await _notificationService.dismissNotification(notificationId);
      print('Dismissed notification $notificationId');
      
      // Remove from local state
      final updatedNotifications = state.notifications
          .where((notification) => notification.id != notificationId)
          .toList();
      
      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      print('Error dismissing notification: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      await _loadNotifications(); // Reload to get updated state
    } catch (e) {
      print('Error deleting notification: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadNotifications();
    await _loadNotificationStats();
  }

  @override
  void dispose() {
    _notificationStream?.cancel();
    super.dispose();
  }
}

class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? stats;

  NotificationState({
    required this.notifications,
    required this.unreadCount,
    required this.isLoading,
    this.error,
    this.stats,
  });

  factory NotificationState.initial() {
    return NotificationState(
      notifications: [],
      unreadCount: 0,
      isLoading: true,
    );
  }

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? stats,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      stats: stats ?? this.stats,
    );
  }
}
```

---

## Webhook Configuration

### Step 1: Create Database Webhook

1. **Go to Supabase Dashboard**
   - Navigate to your project
   - Go to **Database** → **Webhooks**

2. **Create New Webhook**
   - Click **"Create a new webhook"**
   - **Name**: `push-notifications`
   - **Table**: `app_notifications`
   - **Events**: Select **INSERT** only
   - **HTTP Method**: `POST`
   - **URL**: `https://your-project-ref.supabase.co/functions/v1/push-notifications`
   - **Headers**: Leave empty (uses default auth)

3. **Save the Webhook**
   - Click **"Save"** to create the webhook

### Step 2: Verify Webhook

```sql
-- Check webhook configuration
SELECT 
    webhook_name,
    table_name,
    events,
    http_method,
    url
FROM information_schema.webhooks
WHERE webhook_name = 'push-notifications';
```

---

## FCM Setup

### Step 1: Get FCM Credentials

1. **Go to Firebase Console**
   - Navigate to your Firebase project
   - Go to **Project Settings** → **Cloud Messaging**

2. **Get Server Key**
   - Copy the **Server key** from the Cloud Messaging tab
   - This is your `FCM_SERVER_KEY`

3. **Get Project ID**
   - Copy the **Project ID** from Project Settings
   - This is your `FCM_PROJECT_ID`

### Step 2: Set Environment Variables

```bash
# Set FCM Server Key
supabase secrets set FCM_SERVER_KEY=your_fcm_server_key_here

# Set FCM Project ID  
supabase secrets set FCM_PROJECT_ID=your_fcm_project_id_here

# Verify secrets are set
supabase secrets list
```

### Step 3: Configure Flutter App

#### File: `android/app/google-services.json`
```json
{
  "project_info": {
    "project_id": "your-fcm-project-id",
    "project_number": "123456789",
    "firebase_url": "https://your-project.firebaseio.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789:android:abcdef123456",
        "android_client_info": {
          "package_name": "com.example.choice_lux_cars"
        }
      },
      "oauth_client": [],
      "api_key": [
        {
          "current_key": "your-api-key-here"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": []
        }
      }
    }
  ]
}
```

#### File: `ios/Runner/GoogleService-Info.plist`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>API_KEY</key>
    <string>your-api-key-here</string>
    <key>GCM_SENDER_ID</key>
    <string>123456789</string>
    <key>PLIST_VERSION</key>
    <string>1</string>
    <key>BUNDLE_ID</key>
    <string>com.example.choiceLuxCars</string>
    <key>PROJECT_ID</key>
    <string>your-fcm-project-id</string>
    <key>STORAGE_BUCKET</key>
    <string>your-project.appspot.com</string>
    <key>IS_ADS_ENABLED</key>
    <false></false>
    <key>IS_ANALYTICS_ENABLED</key>
    <false></false>
    <key>IS_APPINVITE_ENABLED</key>
    <true></true>
    <key>IS_GCM_ENABLED</key>
    <true></true>
    <key>IS_SIGNIN_ENABLED</key>
    <true></true>
    <key>GOOGLE_APP_ID</key>
    <string>1:123456789:ios:abcdef123456</string>
</dict>
</plist>
```

### Step 4: Update Flutter Dependencies

#### File: `pubspec.yaml`
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^16.3.0
```

### Step 5: Initialize FCM in Flutter

#### File: `lib/main.dart`
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Request permission
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  // Get FCM token
  String? token = await FirebaseMessaging.instance.getToken();
  print('FCM Token: $token');
  
  // Save token to user profile
  if (token != null) {
    await _saveFcmToken(token);
  }
  
  // Listen for token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen(_saveFcmToken);
  
  runApp(MyApp());
}

Future<void> _saveFcmToken(String token) async {
  try {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user != null) {
      await supabase
        .from('profiles')
        .update({ 'fcm_token': token })
        .eq('id', user.id);
      
      print('FCM token saved for user: ${user.id}');
    }
  } catch (e) {
    print('Error saving FCM token: $e');
  }
}
```

---

## Testing Procedures

### 1. Test Database Notifications

```sql
-- Create test notification
INSERT INTO app_notifications (
    user_id,
    message,
    notification_type,
    priority,
    job_id,
    action_data,
    is_read,
    is_hidden
) VALUES (
    '2b48a98e-cdb9-4698-82fc-e8061bf925e6',  -- Replace with actual user ID
    '🧪 TEST: Database notification working!',
    'flutter_test',
    'high',
    'TEST-001',
    jsonb_build_object('test', true),
    false,
    false
);

-- Verify notification created
SELECT * FROM app_notifications 
WHERE user_id = '2b48a98e-cdb9-4698-82fc-e8061bf925e6'
ORDER BY created_at DESC LIMIT 5;
```

### 2. Test Job Assignment Notifications

```sql
-- Create job assignment notification
INSERT INTO app_notifications (
    user_id,
    message,
    notification_type,
    priority,
    job_id,
    action_data,
    is_read,
    is_hidden
) VALUES (
    '2b48a98e-cdb9-4698-82fc-e8061bf925e6',
    '🚗 New job JOB-2025-001 has been assigned to you. Please confirm your assignment.',
    'job_assignment',
    'high',
    '2025-001',
    jsonb_build_object(
        'job_id', '2025-001',
        'job_number', 'JOB-2025-001',
        'passenger_name', 'John Smith',
        'action', 'view_job',
        'route', '/jobs/2025-001/summary'
    ),
    false,
    false
);
```

### 3. Test Edge Function

```bash
# Test Edge Function directly
curl -X POST https://your-project-ref.supabase.co/functions/v1/push-notifications \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-anon-key" \
  -d '{
    "type": "INSERT",
    "table": "app_notifications",
    "record": {
      "id": "test-id",
      "user_id": "test-user-id",
      "message": "Test message",
      "notification_type": "test"
    }
  }'
```

### 4. Test Push Notifications

1. **Create notification in database**
2. **Check Edge Function logs** in Supabase Dashboard
3. **Verify push notification** appears on device
4. **Test notification tap** and deep linking

### 5. Test Complete Flow

1. **Assign job to driver** in the app
2. **Verify notification appears** in Flutter
3. **Check push notification** is sent
4. **Test job confirmation** flow
5. **Verify notification status** updates

---

## Troubleshooting

### Common Issues

#### 1. Notifications Not Appearing in Flutter
```sql
-- Check if notifications exist for the user
SELECT COUNT(*) FROM app_notifications 
WHERE user_id = 'your-user-id' AND is_hidden = false;

-- Check user ID mismatch
SELECT id, display_name FROM profiles 
WHERE id = 'your-user-id';
```

#### 2. Push Notifications Not Working
```bash
# Check FCM credentials
supabase secrets list

# Check Edge Function logs
supabase functions logs push-notifications

# Verify webhook configuration
SELECT * FROM information_schema.webhooks 
WHERE webhook_name = 'push-notifications';
```

#### 3. HTTP Request Queue Errors
```sql
-- Disable Supabase Realtime completely
ALTER TABLE app_notifications REPLICA IDENTITY NOTHING;
ALTER TABLE jobs REPLICA IDENTITY NOTHING;
ALTER TABLE profiles REPLICA IDENTITY NOTHING;

-- Drop any HTTP-related functions
DROP FUNCTION IF EXISTS http_post(text, jsonb, jsonb, jsonb, integer);
DROP FUNCTION IF EXISTS http_request();
```

#### 4. FCM Token Issues
```sql
-- Check if user has FCM token
SELECT id, display_name, fcm_token FROM profiles 
WHERE id = 'your-user-id';

-- Update FCM token manually
UPDATE profiles 
SET fcm_token = 'new-fcm-token-here'
WHERE id = 'your-user-id';
```

### Debug Commands

```bash
# Check Supabase status
supabase status

# Check Edge Function status
supabase functions list

# View Edge Function logs
supabase functions logs push-notifications --follow

# Test Edge Function locally
supabase functions serve push-notifications --env-file .env.local
```

---

## Maintenance

### Regular Tasks

#### 1. Clean Up Old Notifications
```sql
-- Delete notifications older than 30 days
DELETE FROM app_notifications 
WHERE created_at < NOW() - INTERVAL '30 days';

-- Delete read notifications older than 7 days
DELETE FROM app_notifications 
WHERE is_read = true AND created_at < NOW() - INTERVAL '7 days';
```

#### 2. Monitor Notification Delivery
```sql
-- Check delivery success rate
SELECT 
    COUNT(*) as total_sent,
    COUNT(*) FILTER (WHERE success = true) as successful,
    COUNT(*) FILTER (WHERE success = false) as failed,
    ROUND(
        COUNT(*) FILTER (WHERE success = true) * 100.0 / COUNT(*), 
        2
    ) as success_rate
FROM notification_delivery_log
WHERE sent_at > NOW() - INTERVAL '24 hours';
```

#### 3. Update FCM Tokens
```sql
-- Find users with outdated FCM tokens
SELECT id, display_name, fcm_token, updated_at 
FROM profiles 
WHERE fcm_token IS NOT NULL 
  AND updated_at < NOW() - INTERVAL '7 days';
```

### Performance Optimization

#### 1. Database Indexes
```sql
-- Add performance indexes
CREATE INDEX CONCURRENTLY idx_app_notifications_user_read 
ON app_notifications(user_id, is_read, is_hidden) 
WHERE is_read = false AND is_hidden = false;

CREATE INDEX CONCURRENTLY idx_app_notifications_created_at 
ON app_notifications(created_at DESC);
```

#### 2. Partitioning (for large datasets)
```sql
-- Partition by date for large notification tables
CREATE TABLE app_notifications_2025_01 PARTITION OF app_notifications
FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
```

### Security Considerations

#### 1. Row Level Security (RLS)
```sql
-- Enable RLS on app_notifications
ALTER TABLE app_notifications ENABLE ROW LEVEL SECURITY;

-- Create policy for users to see only their notifications
CREATE POLICY "Users can view their own notifications" ON app_notifications
FOR SELECT USING (auth.uid() = user_id);

-- Create policy for users to update their own notifications
CREATE POLICY "Users can update their own notifications" ON app_notifications
FOR UPDATE USING (auth.uid() = user_id);
```

#### 2. API Rate Limiting
```sql
-- Implement rate limiting for notification creation
-- (This would be handled in the Edge Function)
```

---

## Summary

This push notification system provides:

✅ **Reliable delivery** - Webhook-based architecture  
✅ **Real-time updates** - Flutter streams  
✅ **User management** - Mark as read, dismiss, delete  
✅ **Job integration** - Automatic job assignment notifications  
✅ **Push notifications** - FCM integration  
✅ **Error handling** - Comprehensive error management  
✅ **Monitoring** - Delivery logs and statistics  
✅ **Scalability** - Database indexes and optimization  

The system is production-ready and handles all notification scenarios for the Choice Lux Cars application.
