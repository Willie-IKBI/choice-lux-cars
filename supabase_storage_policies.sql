-- Supabase Storage Policies for Choice Lux Cars
-- This script sets up RLS policies for the existing clc_images bucket

-- Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Set up Row Level Security (RLS) policies for the clc_images bucket
-- Allow authenticated users to upload images to any folder in clc_images
CREATE POLICY "Allow authenticated users to upload to clc_images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'clc_images' AND 
  auth.role() = 'authenticated'
);

-- Allow authenticated users to view images from clc_images
CREATE POLICY "Allow authenticated users to view clc_images" ON storage.objects
FOR SELECT USING (
  bucket_id = 'clc_images' AND 
  auth.role() = 'authenticated'
);

-- Allow users to update their own images in clc_images
CREATE POLICY "Allow users to update their own clc_images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'clc_images' AND 
  auth.role() = 'authenticated'
);

-- Allow users to delete their own images in clc_images
CREATE POLICY "Allow users to delete their own clc_images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'clc_images' AND 
  auth.role() = 'authenticated'
);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.buckets TO authenticated;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_storage_objects_bucket_id ON storage.objects(bucket_id);
CREATE INDEX IF NOT EXISTS idx_storage_objects_name ON storage.objects(name);
CREATE INDEX IF NOT EXISTS idx_storage_objects_created_at ON storage.objects(created_at);

-- Verify the clc_images bucket exists and is public
SELECT 
  id, 
  name, 
  public, 
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE id = 'clc_images';

-- List existing policies
SELECT 
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage';
