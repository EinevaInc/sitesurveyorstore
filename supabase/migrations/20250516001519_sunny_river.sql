/*
  # SiteSurveyor Database Schema
  
  1. New Tables
    - `profiles` - User profile information
    - `categories` - Application categories
    - `applications` - Geomatics applications (open source and pro)
    - `app_downloads` - Download tracking
    - `app_favorites` - User favorites
    - `blog_posts` - Blog articles
    - `blog_views` - Blog view tracking
    - `blog_likes` - Blog likes
    - `solution_requests` - User problem submissions
    - `user_activity` - User activity tracking

  2. Security
    - Enable RLS on all tables
    - Add appropriate policies for each table
    - Secure user data access

  3. Features
    - UUID primary keys
    - Automatic timestamps
    - Utility functions for statistics
    - Performance indexes
*/

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==================== PROFILES ====================

CREATE TABLE IF NOT EXISTS profiles (
  id uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username text,
  full_name text,
  bio text,
  avatar_url text,
  website text,
  organization text,
  location text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view all profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- ==================== CATEGORIES ====================

CREATE TABLE IF NOT EXISTS categories (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  name text UNIQUE NOT NULL,
  description text,
  icon text DEFAULT 'folder',
  color text DEFAULT 'bg-blue-100 text-blue-800',
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Categories policies
CREATE POLICY "Anyone can view active categories"
  ON categories FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

-- ==================== APPLICATIONS ====================

CREATE TABLE IF NOT EXISTS applications (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  name text NOT NULL,
  description text NOT NULL,
  category_id uuid REFERENCES categories(id),
  app_type text CHECK (app_type IN ('open_source', 'pro')) DEFAULT 'open_source',
  price numeric(10,2) DEFAULT 0,
  currency text DEFAULT 'USD',
  trial_available boolean DEFAULT false,
  trial_days integer DEFAULT 0,
  version text DEFAULT '1.0.0',
  author_name text,
  author_email text,
  license text DEFAULT 'Apache-2.0',
  homepage_url text,
  repo_url text,
  documentation_url text,
  download_url text,
  icon text DEFAULT 'default',
  featured_image text,
  screenshots text[],
  tags text[],
  features text[],
  pro_features text[],
  requirements text,
  installation_notes text,
  download_count integer DEFAULT 0,
  view_count integer DEFAULT 0,
  like_count integer DEFAULT 0,
  is_featured boolean DEFAULT false,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE applications ENABLE ROW LEVEL SECURITY;

-- Applications policies
CREATE POLICY "Anyone can view active applications"
  ON applications FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

-- ==================== APP DOWNLOADS ====================

CREATE TABLE IF NOT EXISTS app_downloads (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  app_id uuid REFERENCES applications(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  ip_address inet,
  user_agent text,
  downloaded_at timestamptz DEFAULT now()
);

ALTER TABLE app_downloads ENABLE ROW LEVEL SECURITY;

-- App downloads policies
CREATE POLICY "Users can view own downloads"
  ON app_downloads FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Anyone can insert downloads"
  ON app_downloads FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- ==================== APP FAVORITES ====================

CREATE TABLE IF NOT EXISTS app_favorites (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  app_id uuid REFERENCES applications(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(app_id, user_id)
);

ALTER TABLE app_favorites ENABLE ROW LEVEL SECURITY;

-- App favorites policies
CREATE POLICY "Users can manage own favorites"
  ON app_favorites FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ==================== BLOG POSTS ====================

CREATE TABLE IF NOT EXISTS blog_posts (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  title text NOT NULL,
  slug text UNIQUE NOT NULL,
  excerpt text NOT NULL,
  content text NOT NULL,
  featured_image text,
  category text NOT NULL,
  tags text[],
  author_name text NOT NULL,
  author_role text,
  author_bio text,
  author_avatar text,
  read_time text DEFAULT '5 min read',
  view_count integer DEFAULT 0,
  like_count integer DEFAULT 0,
  comment_count integer DEFAULT 0,
  is_featured boolean DEFAULT false,
  is_published boolean DEFAULT false,
  published_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;

-- Blog posts policies
CREATE POLICY "Anyone can view published posts"
  ON blog_posts FOR SELECT
  TO anon, authenticated
  USING (is_published = true);

-- ==================== BLOG VIEWS ====================

CREATE TABLE IF NOT EXISTS blog_views (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  post_id uuid REFERENCES blog_posts(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  ip_address inet,
  user_agent text,
  viewed_at timestamptz DEFAULT now()
);

ALTER TABLE blog_views ENABLE ROW LEVEL SECURITY;

-- Blog views policies
CREATE POLICY "Users can view own blog views"
  ON blog_views FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Anyone can insert blog views"
  ON blog_views FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- ==================== BLOG LIKES ====================

CREATE TABLE IF NOT EXISTS blog_likes (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  post_id uuid REFERENCES blog_posts(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(post_id, user_id)
);

ALTER TABLE blog_likes ENABLE ROW LEVEL SECURITY;

-- Blog likes policies
CREATE POLICY "Users can manage own blog likes"
  ON blog_likes FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ==================== SOLUTION REQUESTS ====================

CREATE TABLE IF NOT EXISTS solution_requests (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  email text,
  problem text NOT NULL,
  category text NOT NULL,
  urgency text CHECK (urgency IN ('low', 'medium', 'high')),
  location text,
  organization text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE solution_requests ENABLE ROW LEVEL SECURITY;

-- Solution requests policies
CREATE POLICY "Users can view own requests"
  ON solution_requests FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Anyone can create requests"
  ON solution_requests FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- ==================== USER ACTIVITY ====================

CREATE TABLE IF NOT EXISTS user_activity (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  activity_type text NOT NULL,
  resource_type text,
  resource_id uuid,
  metadata jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE user_activity ENABLE ROW LEVEL SECURITY;

-- User activity policies
CREATE POLICY "Users can view own activity"
  ON user_activity FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own activity"
  ON user_activity FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- ==================== INDEXES ====================

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_applications_category ON applications(category_id);
CREATE INDEX IF NOT EXISTS idx_applications_type ON applications(app_type);
CREATE INDEX IF NOT EXISTS idx_applications_active ON applications(is_active);
CREATE INDEX IF NOT EXISTS idx_applications_featured ON applications(is_featured);
CREATE INDEX IF NOT EXISTS idx_applications_downloads ON applications(download_count DESC);

CREATE INDEX IF NOT EXISTS idx_blog_posts_published ON blog_posts(is_published);
CREATE INDEX IF NOT EXISTS idx_blog_posts_category ON blog_posts(category);
CREATE INDEX IF NOT EXISTS idx_blog_posts_featured ON blog_posts(is_featured);
CREATE INDEX IF NOT EXISTS idx_blog_posts_published_at ON blog_posts(published_at DESC);

CREATE INDEX IF NOT EXISTS idx_app_downloads_app ON app_downloads(app_id);
CREATE INDEX IF NOT EXISTS idx_app_downloads_user ON app_downloads(user_id);
CREATE INDEX IF NOT EXISTS idx_app_downloads_date ON app_downloads(downloaded_at);

CREATE INDEX IF NOT EXISTS idx_blog_views_post ON blog_views(post_id);
CREATE INDEX IF NOT EXISTS idx_blog_views_user ON blog_views(user_id);
CREATE INDEX IF NOT EXISTS idx_blog_views_date ON blog_views(viewed_at);

CREATE INDEX IF NOT EXISTS idx_user_activity_user ON user_activity(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_type ON user_activity(activity_type);
CREATE INDEX IF NOT EXISTS idx_user_activity_date ON user_activity(created_at DESC);

-- ==================== TRIGGERS ====================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_applications_updated_at
  BEFORE UPDATE ON applications
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_blog_posts_updated_at
  BEFORE UPDATE ON blog_posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_solution_requests_updated_at
  BEFORE UPDATE ON solution_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==================== UTILITY FUNCTIONS ====================

-- Function to increment app download count
CREATE OR REPLACE FUNCTION increment_app_downloads(app_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE applications 
  SET download_count = download_count + 1,
      updated_at = now()
  WHERE id = app_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment blog view count
CREATE OR REPLACE FUNCTION increment_blog_views(post_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE blog_posts 
  SET view_count = view_count + 1,
      updated_at = now()
  WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get app statistics
CREATE OR REPLACE FUNCTION get_app_statistics()
RETURNS TABLE (
  total_apps bigint,
  open_source_apps bigint,
  pro_apps bigint,
  total_downloads bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as total_apps,
    COUNT(*) FILTER (WHERE app_type = 'open_source') as open_source_apps,
    COUNT(*) FILTER (WHERE app_type = 'pro') as pro_apps,
    COALESCE(SUM(download_count), 0) as total_downloads
  FROM applications 
  WHERE is_active = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get blog statistics
CREATE OR REPLACE FUNCTION get_blog_statistics()
RETURNS TABLE (
  total_posts bigint,
  total_views bigint,
  total_likes bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as total_posts,
    COALESCE(SUM(view_count), 0) as total_views,
    COALESCE(SUM(like_count), 0) as total_likes
  FROM blog_posts 
  WHERE is_published = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==================== SAMPLE DATA ====================

-- Insert categories
INSERT INTO categories (name, description, icon, color) VALUES
  ('Field Tools', 'Mobile and field data collection tools', 'map', 'bg-green-100 text-green-800'),
  ('Data Analysis', 'GIS and spatial analysis applications', 'bar-chart', 'bg-blue-100 text-blue-800'),
  ('Documentation', 'Photo mapping and documentation tools', 'camera', 'bg-purple-100 text-purple-800'),
  ('Utilities', 'Coordinate conversion and utility tools', 'settings', 'bg-orange-100 text-orange-800'),
  ('Land Management', 'Property and land management systems', 'home', 'bg-indigo-100 text-indigo-800'),
  ('Remote Sensing', 'Drone and satellite imagery processing', 'satellite', 'bg-pink-100 text-pink-800')
ON CONFLICT (name) DO NOTHING;

-- Insert sample applications
DO $$
DECLARE
  field_tools_id uuid;
  data_analysis_id uuid;
  documentation_id uuid;
  utilities_id uuid;
  land_mgmt_id uuid;
  remote_sensing_id uuid;
BEGIN
  -- Get category IDs
  SELECT id INTO field_tools_id FROM categories WHERE name = 'Field Tools';
  SELECT id INTO data_analysis_id FROM categories WHERE name = 'Data Analysis';
  SELECT id INTO documentation_id FROM categories WHERE name = 'Documentation';
  SELECT id INTO utilities_id FROM categories WHERE name = 'Utilities';
  SELECT id INTO land_mgmt_id FROM categories WHERE name = 'Land Management';
  SELECT id INTO remote_sensing_id FROM categories WHERE name = 'Remote Sensing';

  -- Open Source Applications
  INSERT INTO applications (
    name, description, category_id, app_type, author_name, license, 
    homepage_url, repo_url, icon, tags, features, download_count, is_featured
  ) VALUES
  (
    'Site Survey Tool',
    'A comprehensive tool for site surveying and mapping in the field with GPS integration and offline capabilities.',
    field_tools_id,
    'open_source',
    'SiteSurveyor Team',
    'Apache-2.0',
    'https://sitesurveyor.com/survey-tool',
    'https://github.com/sitesurveyor/survey-tool',
    'map',
    ARRAY['surveying', 'mapping', 'gis', 'field-work'],
    ARRAY['GPS Integration', 'Offline Mapping', 'Data Export', 'Basic Reporting'],
    1250,
    true
  ),
  (
    'GIS Data Viewer',
    'View and analyze GIS data with this powerful viewer application supporting multiple file formats.',
    data_analysis_id,
    'open_source',
    'SiteSurveyor Team',
    'Apache-2.0',
    'https://sitesurveyor.com/gis-viewer',
    'https://github.com/sitesurveyor/gis-viewer',
    'database',
    ARRAY['gis', 'data', 'visualization', 'analysis'],
    ARRAY['Multiple Format Support', 'Basic Visualization', 'Data Import/Export', 'Layer Management'],
    890,
    false
  ),
  (
    'Photo Mapper',
    'Geo-tag and organize field photos with GPS coordinates for better documentation and analysis.',
    documentation_id,
    'open_source',
    'SiteSurveyor Team',
    'Apache-2.0',
    'https://sitesurveyor.com/photo-mapper',
    'https://github.com/sitesurveyor/photo-mapper',
    'camera',
    ARRAY['photography', 'gps', 'field-work', 'documentation'],
    ARRAY['GPS Geotagging', 'Photo Organization', 'Basic Metadata', 'Export Options'],
    1560,
    false
  );

  -- Professional Applications
  INSERT INTO applications (
    name, description, category_id, app_type, price, trial_available, trial_days,
    author_name, license, homepage_url, icon, tags, features, pro_features, 
    download_count, is_featured
  ) VALUES
  (
    'Coordinate Converter Pro',
    'Professional-grade coordinate system converter with advanced precision calculations and batch processing capabilities.',
    utilities_id,
    'pro',
    149.99,
    true,
    14,
    'GeoTools Africa',
    'Commercial',
    'https://geotools.africa/coord-converter-pro',
    'database',
    ARRAY['coordinates', 'conversion', 'precision', 'surveying', 'professional'],
    ARRAY['Basic Coordinate Conversion', 'Standard Datum Support', 'Single Point Processing'],
    ARRAY['Batch Processing (1000+ points)', 'Custom Datum Creation', 'Advanced Precision Algorithms', 'API Integration', 'Priority Support', 'Advanced Reporting', 'Cloud Sync', 'Team Collaboration'],
    156,
    true
  ),
  (
    'Land Parcel Manager Pro',
    'Enterprise land management solution with advanced boundary mapping, ownership tracking, and legal documentation features.',
    land_mgmt_id,
    'pro',
    299.99,
    true,
    30,
    'LandTech Solutions',
    'Commercial',
    'https://landtech.solutions/parcel-manager-pro',
    'map',
    ARRAY['land-management', 'parcels', 'boundaries', 'property', 'enterprise'],
    ARRAY['Basic Parcel Mapping', 'Simple Boundary Tools', 'Basic Reporting'],
    ARRAY['Advanced CAD Integration', 'Legal Document Generation', 'Multi-user Collaboration', 'Advanced Analytics', 'Custom Workflows', 'API Access', 'Priority Support', 'Data Migration Tools', 'Compliance Reporting', 'Cloud Backup'],
    89,
    false
  ),
  (
    'DroneView Analytics Pro',
    'AI-powered drone image analysis with machine learning algorithms for advanced photogrammetry and automated feature detection.',
    remote_sensing_id,
    'pro',
    499.99,
    true,
    7,
    'AeroTech Solutions',
    'Commercial',
    'https://aerotech.solutions/droneview-pro',
    'camera',
    ARRAY['ai', 'drones', 'photogrammetry', 'machine-learning', 'professional'],
    ARRAY['Basic Image Processing', 'Simple Orthomosaic Generation', 'Standard 3D Models'],
    ARRAY['AI-Powered Feature Detection', 'Advanced Machine Learning Models', 'Automated Quality Control', 'High-Resolution Processing', 'Custom AI Training', 'Batch Processing', 'Cloud Processing', 'Advanced Analytics', 'API Integration', 'Priority Support'],
    67,
    true
  );
END $$;

-- Insert sample blog posts
INSERT INTO blog_posts (
  title, slug, excerpt, content, featured_image, category, tags, 
  author_name, author_role, author_bio, author_avatar, read_time,
  is_featured, is_published, published_at, view_count, like_count, comment_count
) VALUES
(
  'The Future of AI in African Geomatics: Transforming Surveying with Machine Learning',
  'ai-african-geomatics-machine-learning',
  'Discover how artificial intelligence is revolutionizing geomatics workflows across Africa, from automated feature detection to predictive terrain modeling.',
  '<h2>Introduction</h2><p>Artificial Intelligence is reshaping the geomatics landscape across Africa, offering unprecedented opportunities to automate complex surveying tasks and improve accuracy. In this comprehensive guide, we explore how machine learning algorithms are being integrated into modern surveying workflows.</p><h2>The Current State of AI in Geomatics</h2><p>The integration of AI in geomatics has accelerated dramatically over the past five years. From automated feature detection in satellite imagery to predictive modeling for terrain analysis, AI is transforming how we collect, process, and analyze spatial data.</p>',
  'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=1200&h=600&fit=crop',
  'Technology',
  ARRAY['AI', 'Machine Learning', 'Surveying', 'Innovation'],
  'Consolation Mangena',
  'Founder & Lead Developer',
  'Consolation is a geomatics student at Midlands State University and the founder of SiteSurveyor.',
  '/profile.jpg',
  '8 min read',
  true,
  true,
  '2024-03-15T10:00:00Z',
  2847,
  156,
  23
),
(
  'Open Source vs Premium: Choosing the Right Geomatics Tools',
  'open-source-vs-premium-geomatics-tools',
  'A comprehensive comparison of open-source and premium geomatics solutions, helping you make informed decisions for your surveying projects.',
  '<h2>Introduction</h2><p>The choice between open-source and premium geomatics tools can significantly impact your project success and budget. This detailed analysis examines the pros and cons of each approach.</p><h2>Understanding the Landscape</h2><p>The geomatics software landscape has evolved dramatically over the past decade. Traditional proprietary solutions now compete with sophisticated open-source alternatives.</p>',
  'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=1200&h=600&fit=crop',
  'Guide',
  ARRAY['Open Source', 'Premium', 'Tools', 'Decision Making'],
  'Dr. Sarah Mukamuri',
  'GIS Specialist',
  'Dr. Mukamuri is a GIS specialist with over 15 years of experience in both open source and commercial geomatics solutions.',
  'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100&h=100&fit=crop&crop=face',
  '6 min read',
  false,
  true,
  '2024-03-12T09:00:00Z',
  1923,
  89,
  15
),
(
  'Blockchain Technology in Land Management: Securing Property Rights',
  'blockchain-land-management-property-rights',
  'Exploring how blockchain technology is being used to create transparent, tamper-proof land registry systems across Zimbabwe and Africa.',
  '<h2>Introduction</h2><p>Blockchain technology offers a revolutionary approach to land management, providing immutable records and transparent transactions. In Zimbabwe, where land rights have been a complex issue, blockchain presents new opportunities.</p><h2>Current Challenges</h2><p>Traditional land registry systems face numerous challenges including corruption, data loss, and lack of transparency.</p>',
  'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=1200&h=600&fit=crop',
  'Innovation',
  ARRAY['Blockchain', 'Land Management', 'Security', 'Zimbabwe'],
  'James Chikwanha',
  'Blockchain Developer',
  'James specializes in blockchain applications for land management and has worked on several pilot projects across Africa.',
  'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop&crop=face',
  '10 min read',
  true,
  true,
  '2024-03-10T14:00:00Z',
  3156,
  201,
  34
);