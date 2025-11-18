-- Quick verification script - run this to check permissions
SELECT 
  has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'USAGE') as has_usage,
  has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'SELECT') as has_select,
  has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'UPDATE') as has_update;



