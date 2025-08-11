-- Add is_hidden field to notifications table for soft delete
ALTER TABLE notifications 
ADD COLUMN is_hidden BOOLEAN DEFAULT FALSE;

-- Add index for better performance when filtering hidden notifications
CREATE INDEX idx_notifications_hidden ON notifications(is_hidden, user_id);

-- Update existing notifications to ensure they're not hidden
UPDATE notifications SET is_hidden = FALSE WHERE is_hidden IS NULL; 