-- Setup Notifications Table
-- Applied: 2025-08-15
-- Description: Create a clean notifications table without any HTTP dependencies

-- Create notifications table if it doesn't exist
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    job_id BIGINT REFERENCES jobs(id) ON DELETE CASCADE,
    body TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    notification_type VARCHAR(50) DEFAULT 'job_assignment',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_job_id ON notifications(job_id);

-- Enable real-time for notifications table
ALTER TABLE notifications REPLICA IDENTITY FULL;

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
DROP POLICY IF EXISTS "System can insert notifications" ON notifications;

CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications" ON notifications
    FOR INSERT WITH CHECK (true);

-- Create notifications for existing jobs that have drivers but no notifications
INSERT INTO notifications (
    user_id,
    job_id,
    body,
    notification_type,
    is_read
)
SELECT 
    j.driver_id,
    j.id,
    'New job assigned to you. Please confirm your job in the app.',
    'job_assignment',
    false
FROM jobs j
LEFT JOIN notifications n ON j.id = n.job_id AND j.driver_id = n.user_id
WHERE j.driver_id IS NOT NULL 
AND n.id IS NULL
AND j.job_status IN ('open', 'assigned');
