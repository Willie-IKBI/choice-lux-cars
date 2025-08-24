-- Fix Invoice Storage Policies
-- Run this script in your Supabase SQL Editor to fix the 403 error

-- Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies for pdfdocuments if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Allow authenticated users to upload to pdfdocuments" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to view pdfdocuments" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to update their own pdfdocuments" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete their own pdfdocuments" ON storage.objects;

-- Create new policies for pdfdocuments bucket
CREATE POLICY "Allow authenticated users to upload to pdfdocuments" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'pdfdocuments' AND 
  auth.role() = 'authenticated'
);

CREATE POLICY "Allow authenticated users to view pdfdocuments" ON storage.objects
FOR SELECT USING (
  bucket_id = 'pdfdocuments' AND 
  auth.role() = 'authenticated'
);

CREATE POLICY "Allow users to update their own pdfdocuments" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'pdfdocuments' AND 
  auth.role() = 'authenticated'
);

CREATE POLICY "Allow users to delete their own pdfdocuments" ON storage.objects
FOR DELETE USING (
  bucket_id = 'pdfdocuments' AND 
  auth.role() = 'authenticated'
);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.buckets TO authenticated;

-- Verify the pdfdocuments bucket exists
SELECT 
  id, 
  name, 
  public, 
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE id = 'pdfdocuments';

-- If the bucket doesn't exist, create it
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('pdfdocuments', 'pdfdocuments', true, 52428800, ARRAY['application/pdf'])
ON CONFLICT (id) DO NOTHING;

-- List all policies to verify they were created
SELECT 
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE '%pdfdocuments%';
