-- Enable realtime for notifications table
ALTER TABLE notifications REPLICA IDENTITY FULL;

-- Verify realtime is enabled
SELECT schemaname, tablename, replica_identity 
FROM pg_tables 
WHERE tablename = 'notifications'; 