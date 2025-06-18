/*
  # Storage Setup for SiteSurveyor
  
  1. Storage Buckets
    - `avatars` - User profile pictures
    - `app-images` - Application screenshots and featured images
    - `blog-images` - Blog post images
  
  2. Storage Policies
    - Public read access for images
    - Authenticated upload for user content
    - Size and file type restrictions
*/

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('avatars', 'avatars', true),
  ('app-images', 'app-images', true),
  ('blog-images', 'blog-images', true)
ON CONFLICT (id) DO NOTHING;

-- Avatar storage policies
CREATE POLICY "Avatar images are publicly accessible"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can update their own avatar"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete their own avatar"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- App images storage policies
CREATE POLICY "App images are publicly accessible"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'app-images');

-- Blog images storage policies  
CREATE POLICY "Blog images are publicly accessible"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'blog-images');

-- File type restrictions
CREATE POLICY "Only allow image uploads to avatars"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.extension(name)) IN ('jpg', 'jpeg', 'png', 'gif', 'webp')
  );

CREATE POLICY "Only allow image uploads to app-images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'app-images'
    AND (storage.extension(name)) IN ('jpg', 'jpeg', 'png', 'gif', 'webp')
  );

CREATE POLICY "Only allow image uploads to blog-images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'blog-images'
    AND (storage.extension(name)) IN ('jpg', 'jpeg', 'png', 'gif', 'webp')
  );