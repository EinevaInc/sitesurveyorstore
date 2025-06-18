# SiteSurveyor Database Migrations

This directory contains the database migrations for the SiteSurveyor application.

## Migration Files

1. **20250101000000_initial_schema.sql** - Main database schema with all tables, policies, and sample data
2. **20250101000001_storage_setup.sql** - Storage buckets and policies for file uploads

## Running Migrations

### Local Development
```bash
# Reset and apply all migrations
supabase db reset

# Apply new migrations
supabase db push
```

### Production
Migrations are automatically applied when you push to your Supabase project:
```bash
supabase db push --linked
```

## Database Schema Overview

### Core Tables
- `profiles` - User profile information
- `categories` - Application categories
- `applications` - Geomatics applications (open source and pro)
- `blog_posts` - Blog articles and content

### Tracking Tables
- `app_downloads` - Download tracking
- `app_favorites` - User favorites
- `blog_views` - Blog view tracking
- `blog_likes` - Blog likes
- `user_activity` - User activity tracking

### Request Tables
- `solution_requests` - User problem submissions

### Storage Buckets
- `avatars` - User profile pictures
- `app-images` - Application screenshots
- `blog-images` - Blog post images

## Security

All tables have Row Level Security (RLS) enabled with appropriate policies:
- Users can only access their own data
- Public content is accessible to everyone
- Anonymous users can view published content

## Sample Data

The initial migration includes sample data for:
- Application categories
- Sample applications (both open source and pro)
- Sample blog posts
- Utility functions for statistics

## Utility Functions

- `increment_app_downloads(app_id)` - Increment download count
- `increment_blog_views(post_id)` - Increment view count  
- `get_app_statistics()` - Get application statistics
- `get_blog_statistics()` - Get blog statistics