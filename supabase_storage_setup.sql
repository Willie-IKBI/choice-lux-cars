-- Supabase Storage Setup for Choice Lux Cars
-- This script creates the necessary storage bucket for image uploads

-- Create the storage bucket for odometer images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'odometer',
  'odometer',
  true,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Create storage bucket for general vehicle images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'vehicle-images',
  'vehicle-images',
  true,
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Create storage bucket for profile images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-images',
  'profile-images',
  true,
  2097152, -- 2MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Set up Row Level Security (RLS) policies for the odometer bucket
-- Allow authenticated users to upload odometer images
CREATE POLICY "Allow authenticated users to upload odometer images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'odometer' AND 
  auth.role() = 'authenticated'
);

-- Allow authenticated users to view odometer images
CREATE POLICY "Allow authenticated users to view odometer images" ON storage.objects
FOR SELECT USING (
  bucket_id = 'odometer' AND 
  auth.role() = 'authenticated'
);

-- Allow users to update their own odometer images
CREATE POLICY "Allow users to update their own odometer images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'odometer' AND 
  auth.role() = 'authenticated'
);

-- Allow users to delete their own odometer images
CREATE POLICY "Allow users to delete their own odometer images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'odometer' AND 
  auth.role() = 'authenticated'
);

-- Set up RLS policies for vehicle-images bucket
CREATE POLICY "Allow authenticated users to upload vehicle images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'vehicle-images' AND 
  auth.role() = 'authenticated'
);

CREATE POLICY "Allow authenticated users to view vehicle images" ON storage.objects
FOR SELECT USING (
  bucket_id = 'vehicle-images' AND 
  auth.role() = 'authenticated'
);

CREATE POLICY "Allow users to update their own vehicle images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'vehicle-images' AND 
  auth.role() = 'authenticated'
);

CREATE POLICY "Allow users to delete their own vehicle images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'vehicle-images' AND 
  auth.role() = 'authenticated'
);

-- Set up RLS policies for profile-images bucket
CREATE POLICY "Allow authenticated users to upload profile images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profile-images' AND 
  auth.role() = 'authenticated'
);

CREATE POLICY "Allow authenticated users to view profile images" ON storage.objects
FOR SELECT USING (
  bucket_id = 'profile-images' AND 
  auth.role() = 'authenticated'
);

CREATE POLICY "Allow users to update their own profile images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'profile-images' AND 
  auth.role() = 'authenticated'
);

CREATE POLICY "Allow users to delete their own profile images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'profile-images' AND 
  auth.role() = 'authenticated'
);

-- Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Create a function to generate unique filenames
CREATE OR REPLACE FUNCTION generate_unique_filename(bucket_name text, original_filename text)
RETURNS text AS $$
DECLARE
  timestamp_part text;
  random_part text;
  file_extension text;
  unique_filename text;
BEGIN
  -- Extract file extension
  file_extension := CASE 
    WHEN original_filename LIKE '%.%' THEN '.' || split_part(original_filename, '.', -1)
    ELSE ''
  END;
  
  -- Generate timestamp part
  timestamp_part := to_char(now(), 'YYYYMMDD_HH24MISS');
  
  -- Generate random part (6 characters)
  random_part := substr(md5(random()::text), 1, 6);
  
  -- Combine parts
  unique_filename := timestamp_part || '_' || random_part || file_extension;
  
  RETURN unique_filename;
END;
$$ LANGUAGE plpgsql;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.buckets TO authenticated;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_storage_objects_bucket_id ON storage.objects(bucket_id);
CREATE INDEX IF NOT EXISTS idx_storage_objects_name ON storage.objects(name);
CREATE INDEX IF NOT EXISTS idx_storage_objects_created_at ON storage.objects(created_at);

-- Insert a comment for documentation
COMMENT ON TABLE storage.buckets IS 'Storage buckets for Choice Lux Cars application';
COMMENT ON COLUMN storage.buckets.id IS 'Unique identifier for the bucket';
COMMENT ON COLUMN storage.buckets.name IS 'Display name for the bucket';
COMMENT ON COLUMN storage.buckets.public IS 'Whether the bucket is publicly accessible';
COMMENT ON COLUMN storage.buckets.file_size_limit IS 'Maximum file size in bytes';
COMMENT ON COLUMN storage.buckets.allowed_mime_types IS 'Array of allowed MIME types';
