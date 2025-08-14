-- Create Odometer Readings Storage Bucket
-- Applied: 2025-08-14
-- Description: Create storage bucket for odometer reading images

-- Create the odometer-readings bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'odometer-readings',
  'odometer-readings',
  true,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Create RLS policies for the odometer-readings bucket
-- Allow authenticated users to upload odometer images
CREATE POLICY "Allow authenticated users to upload odometer images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'odometer-readings' 
  AND auth.role() = 'authenticated'
);

-- Allow authenticated users to view odometer images
CREATE POLICY "Allow authenticated users to view odometer images" ON storage.objects
FOR SELECT USING (
  bucket_id = 'odometer-readings' 
  AND auth.role() = 'authenticated'
);

-- Allow authenticated users to update their own odometer images
CREATE POLICY "Allow authenticated users to update odometer images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'odometer-readings' 
  AND auth.role() = 'authenticated'
);

-- Allow authenticated users to delete their own odometer images
CREATE POLICY "Allow authenticated users to delete odometer images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'odometer-readings' 
  AND auth.role() = 'authenticated'
);

COMMENT ON TABLE storage.objects IS 'Storage objects for odometer reading images';
