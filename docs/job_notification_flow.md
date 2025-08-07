# Job Notification Flow Documentation

## Overview
This document describes the complete notification system for job assignments in the Choice Lux Cars application. The system provides real-time notifications to drivers when they are assigned new jobs, with the ability to view, navigate to, and confirm jobs directly from notifications.

## Flow Diagram
```
Job Assignment → Notification Creation → Badge Update → User Interaction → Job Confirmation → Notification Clear
```

## Database Schema

### Notifications Table
```sql
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    notification_type VARCHAR(50) DEFAULT 'job_assignment',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for performance
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
```

### Jobs Table Updates
```sql
-- Add confirmation status if not exists
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS is_confirmed BOOLEAN DEFAULT FALSE;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS confirmed_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS confirmed_by UUID REFERENCES auth.users(id);
```

## Triggers and Actions

### 1. Job Assignment Trigger
**Trigger**: New job is assigned to a driver
**Location**: `supabase/functions/job-assignment-notification/index.ts`

**Actions**:
- Create notification record in database
- Send real-time notification to driver's client
- Update notification badge count

**Code Flow**:
```typescript
// When job is assigned
1. Insert notification record
2. Broadcast to user's real-time channel
3. Update client-side notification count
```

### 2. Notification Badge Update
**Trigger**: New notification created or notification status changed
**Location**: Dashboard app bar component

**Actions**:
- Query unread notifications count
- Update badge number display
- Animate badge if new notification arrives

### 3. Notification List Display
**Trigger**: User clicks notification bell
**Location**: Notification list modal/screen

**Actions**:
- Fetch user's unread notifications
- Display notification cards with job details
- Show "New job assigned, click to confirm" message

### 4. Navigation to Job Summary
**Trigger**: User clicks on notification item
**Location**: Notification list → Job summary screen

**Actions**:
- Navigate to job summary screen
- Pass job_id as parameter
- Mark notification as read
- Update badge count

### 5. Job Confirmation
**Trigger**: User confirms job in summary screen
**Location**: Job summary screen

**Actions**:
- Update job.is_confirmed = true
- Set confirmed_at timestamp
- Set confirmed_by user_id
- Mark all related notifications as read
- Update notification badge count
- Show confirmation success message

## Implementation Components

### 1. Notification Provider
**File**: `lib/features/notifications/providers/notification_provider.dart`

**Responsibilities**:
- Manage notification state
- Handle real-time updates
- Provide notification count
- Mark notifications as read

**Key Methods**:
```dart
class NotificationProvider extends ChangeNotifier {
  List<Notification> _notifications = [];
  int _unreadCount = 0;
  
  Future<void> fetchNotifications();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  void updateUnreadCount();
  void listenToRealtimeUpdates();
}
```

### 2. Notification Service
**File**: `lib/features/notifications/services/notification_service.dart`

**Responsibilities**:
- API calls to Supabase
- Real-time subscription management
- Notification CRUD operations

**Key Methods**:
```dart
class NotificationService {
  Future<List<Notification>> getNotifications();
  Future<void> createNotification(Notification notification);
  Future<void> markAsRead(String notificationId);
  Future<void> deleteNotification(String notificationId);
  Stream<List<Notification>> subscribeToNotifications();
}
```

### 3. Notification Model
**File**: `lib/features/notifications/models/notification.dart`

**Structure**:
```dart
class Notification {
  final String id;
  final String userId;
  final String jobId;
  final String message;
  final bool isRead;
  final String notificationType;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Constructor, fromJson, toJson methods
}
```

### 4. UI Components

#### Notification Bell Widget
**File**: `lib/shared/widgets/notification_bell.dart`

**Features**:
- Animated badge with count
- Click handler to open notification list
- Real-time count updates

#### Notification List Screen
**File**: `lib/features/notifications/screens/notification_list_screen.dart`

**Features**:
- List of unread notifications
- Job assignment messages
- Click navigation to job summary
- Mark as read functionality

#### Notification Card Widget
**File**: `lib/features/notifications/widgets/notification_card.dart`

**Features**:
- Display notification message
- Show job details
- Click handler for navigation
- Read/unread status indicator

## Real-time Implementation

### Supabase Real-time Setup
```sql
-- Enable real-time for notifications table
ALTER TABLE notifications REPLICA IDENTITY FULL;

-- Create policy for real-time access
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);
```

### Client-side Subscription
```dart
// In NotificationProvider
void listenToRealtimeUpdates() {
  supabase
    .channel('notifications')
    .on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: currentUserId,
        ),
      ),
      (payload, [ref]) {
        // Handle new notification
        _addNotification(Notification.fromJson(payload['new']));
        _updateUnreadCount();
      },
    )
    .subscribe();
}
```

## API Endpoints

### Supabase Functions

#### 1. Create Job Assignment Notification
**Endpoint**: `POST /functions/v1/job-assignment-notification`
**Purpose**: Create notification when job is assigned

**Request Body**:
```json
{
  "job_id": "uuid",
  "driver_id": "uuid",
  "message": "New job assigned, click to confirm"
}
```

**Response**:
```json
{
  "success": true,
  "notification_id": "uuid"
}
```

#### 2. Mark Notification as Read
**Endpoint**: `PATCH /functions/v1/mark-notification-read`
**Purpose**: Mark notification as read

**Request Body**:
```json
{
  "notification_id": "uuid"
}
```

## Error Handling

### Common Scenarios
1. **Network Failure**: Retry mechanism for API calls
2. **Real-time Connection Lost**: Auto-reconnect with exponential backoff
3. **Invalid Job ID**: Graceful error handling with user feedback
4. **Permission Denied**: Redirect to login if authentication fails

### Error Messages
- "Failed to load notifications. Please try again."
- "Unable to mark notification as read."
- "Connection lost. Reconnecting..."
- "You don't have permission to view this notification."

## Testing Scenarios

### Unit Tests
1. Notification creation with valid data
2. Badge count calculation
3. Mark as read functionality
4. Real-time update handling

### Integration Tests
1. Complete flow from job assignment to confirmation
2. Multiple notifications handling
3. Offline/online behavior
4. Permission-based access

### User Acceptance Tests
1. Driver receives notification immediately after job assignment
2. Badge count updates in real-time
3. Navigation to job summary works correctly
4. Notification clears after job confirmation

## Performance Considerations

### Database Optimization
- Index on frequently queried columns
- Pagination for notification lists
- Cleanup old notifications (older than 30 days)

### Client-side Optimization
- Debounce real-time updates
- Cache notification data
- Lazy loading for notification lists
- Background sync for offline scenarios

## Security Considerations

### Row Level Security (RLS)
```sql
-- Ensure users can only access their own notifications
CREATE POLICY "Users can only access their own notifications" ON notifications
    FOR ALL USING (auth.uid() = user_id);
```

### Data Validation
- Validate notification data before insertion
- Sanitize user inputs
- Check permissions before operations

## Monitoring and Analytics

### Metrics to Track
- Notification delivery success rate
- Time from assignment to notification
- Time from notification to job confirmation
- Notification read rates
- User engagement with notifications

### Logging
- Log all notification events
- Track error rates and types
- Monitor real-time connection health
- Performance metrics for API calls

## Future Enhancements

### Potential Features
1. **Push Notifications**: Send push notifications to mobile devices
2. **Email Notifications**: Fallback email notifications
3. **Notification Preferences**: Allow users to customize notification types
4. **Bulk Actions**: Mark multiple notifications as read
5. **Notification History**: View all notifications (read and unread)
6. **Custom Messages**: Allow custom notification messages per job type

### Technical Improvements
1. **WebSocket Optimization**: Implement connection pooling
2. **Caching Strategy**: Redis caching for frequently accessed data
3. **Message Queue**: Use message queue for reliable notification delivery
4. **Analytics Integration**: Detailed user behavior tracking
