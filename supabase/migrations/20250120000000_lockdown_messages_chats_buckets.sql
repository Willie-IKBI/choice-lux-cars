-- Migration: Lock down public storage bucket access for messages and chats buckets
-- Date: 2025-01-20
-- Purpose: Remove public access policies and replace with authenticated-only policies
-- 
-- This migration addresses the critical security vulnerability where messages and chats
-- buckets had full public read/write access, allowing unauthenticated users to access
-- and modify files without authentication.
--
-- Rollback: See rollback section at the end of this file

BEGIN;

-- ============================================================================
-- STEP 1: Drop existing public policies for 'messages' bucket
-- ============================================================================

-- Drop SELECT policy
DROP POLICY IF EXISTS "Allow full Acess 1rdzryk_0" ON storage.objects;

-- Drop INSERT policy
DROP POLICY IF EXISTS "Allow full Acess 1rdzryk_1" ON storage.objects;

-- Drop UPDATE policy
DROP POLICY IF EXISTS "Allow full Acess 1rdzryk_2" ON storage.objects;

-- Drop DELETE policy
DROP POLICY IF EXISTS "Allow full Acess 1rdzryk_3" ON storage.objects;

-- ============================================================================
-- STEP 2: Drop existing public policies for 'chats' bucket
-- ============================================================================

-- Drop SELECT policy
DROP POLICY IF EXISTS "Allow full access 1kc463_0" ON storage.objects;

-- Drop INSERT policy
DROP POLICY IF EXISTS "Allow full access 1kc463_1" ON storage.objects;

-- Drop UPDATE policy
DROP POLICY IF EXISTS "Allow full access 1kc463_2" ON storage.objects;

-- Drop DELETE policy
DROP POLICY IF EXISTS "Allow full access 1kc463_3" ON storage.objects;

-- ============================================================================
-- STEP 3: Create authenticated-only policies for 'messages' bucket
-- ============================================================================

-- SELECT policy: Authenticated users can read files from messages bucket
CREATE POLICY "messages_authenticated_select"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (bucket_id = 'messages');

-- INSERT policy: Authenticated users can upload files to messages bucket
CREATE POLICY "messages_authenticated_insert"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'messages');

-- UPDATE policy: Authenticated users can update files in messages bucket
CREATE POLICY "messages_authenticated_update"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (bucket_id = 'messages')
  WITH CHECK (bucket_id = 'messages');

-- DELETE policy: Authenticated users can delete files from messages bucket
CREATE POLICY "messages_authenticated_delete"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'messages');

-- ============================================================================
-- STEP 4: Create authenticated-only policies for 'chats' bucket
-- ============================================================================

-- SELECT policy: Authenticated users can read files from chats bucket
CREATE POLICY "chats_authenticated_select"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (bucket_id = 'chats');

-- INSERT policy: Authenticated users can upload files to chats bucket
CREATE POLICY "chats_authenticated_insert"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'chats');

-- UPDATE policy: Authenticated users can update files in chats bucket
CREATE POLICY "chats_authenticated_update"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (bucket_id = 'chats')
  WITH CHECK (bucket_id = 'chats');

-- DELETE policy: Authenticated users can delete files from chats bucket
CREATE POLICY "chats_authenticated_delete"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'chats');

COMMIT;

-- ============================================================================
-- ROLLBACK SCRIPT
-- ============================================================================
-- 
-- To rollback this migration, execute the following SQL:
--
-- BEGIN;
--
-- -- Drop authenticated policies for messages bucket
-- DROP POLICY IF EXISTS "messages_authenticated_select" ON storage.objects;
-- DROP POLICY IF EXISTS "messages_authenticated_insert" ON storage.objects;
-- DROP POLICY IF EXISTS "messages_authenticated_update" ON storage.objects;
-- DROP POLICY IF EXISTS "messages_authenticated_delete" ON storage.objects;
--
-- -- Drop authenticated policies for chats bucket
-- DROP POLICY IF EXISTS "chats_authenticated_select" ON storage.objects;
-- DROP POLICY IF EXISTS "chats_authenticated_insert" ON storage.objects;
-- DROP POLICY IF EXISTS "chats_authenticated_update" ON storage.objects;
-- DROP POLICY IF EXISTS "chats_authenticated_delete" ON storage.objects;
--
-- -- Restore public policies for messages bucket
-- CREATE POLICY "Allow full Acess 1rdzryk_0"
--   ON storage.objects
--   AS PERMISSIVE
--   FOR SELECT
--   TO public
--   USING ((bucket_id = 'messages'::text));
--
-- CREATE POLICY "Allow full Acess 1rdzryk_1"
--   ON storage.objects
--   AS PERMISSIVE
--   FOR INSERT
--   TO public
--   WITH CHECK ((bucket_id = 'messages'::text));
--
-- CREATE POLICY "Allow full Acess 1rdzryk_2"
--   ON storage.objects
--   AS PERMISSIVE
--   FOR UPDATE
--   TO public
--   USING ((bucket_id = 'messages'::text));
--
-- CREATE POLICY "Allow full Acess 1rdzryk_3"
--   ON storage.objects
--   AS PERMISSIVE
--   FOR DELETE
--   TO public
--   USING ((bucket_id = 'messages'::text));
--
-- -- Restore public policies for chats bucket
-- CREATE POLICY "Allow full access 1kc463_0"
--   ON storage.objects
--   AS PERMISSIVE
--   FOR SELECT
--   TO public
--   USING ((bucket_id = 'chats'::text));
--
-- CREATE POLICY "Allow full access 1kc463_1"
--   ON storage.objects
--   AS PERMISSIVE
--   FOR INSERT
--   TO public
--   WITH CHECK ((bucket_id = 'chats'::text));
--
-- CREATE POLICY "Allow full access 1kc463_2"
--   ON storage.objects
--   AS PERMISSIVE
--   FOR UPDATE
--   TO public
--   USING ((bucket_id = 'chats'::text));
--
-- CREATE POLICY "Allow full access 1kc463_3"
--   ON storage.objects
--   AS PERMISSIVE
--   FOR DELETE
--   TO public
--   USING ((bucket_id = 'chats'::text));
--
-- COMMIT;
--
-- ============================================================================

