import { supabase } from './supabase'

// ==================== APPLICATIONS ====================

export const getApplications = async (filters = {}) => {
  let query = supabase
    .from('applications')
    .select(`
      *,
      categories (
        name,
        color,
        icon
      )
    `)
    .eq('is_active', true)
    .order('is_featured', { ascending: false })
    .order('download_count', { ascending: false })

  if (filters.category && filters.category !== 'all') {
    // Join with categories table to filter by category name
    query = query.eq('categories.name', filters.category)
  }

  if (filters.app_type && filters.app_type !== 'all') {
    query = query.eq('app_type', filters.app_type)
  }

  if (filters.featured) {
    query = query.eq('is_featured', true)
  }

  if (filters.search) {
    query = query.or(`name.ilike.%${filters.search}%,description.ilike.%${filters.search}%`)
  }

  const { data, error } = await query
  return { data, error }
}

export const getApplication = async (id) => {
  const { data, error } = await supabase
    .from('applications')
    .select(`
      *,
      categories (
        name,
        color,
        icon
      )
    `)
    .eq('id', id)
    .eq('is_active', true)
    .single()
  
  return { data, error }
}

export const incrementAppDownloads = async (appId) => {
  const { data, error } = await supabase.rpc('increment_app_downloads', {
    app_id: appId
  })
  
  return { data, error }
}

export const trackAppDownload = async (appId, userEmail = null) => {
  const downloadData = {
    app_id: appId,
    downloaded_at: new Date().toISOString()
  }

  if (userEmail) {
    downloadData.user_email = userEmail
  }

  const { data, error } = await supabase
    .from('app_downloads')
    .insert(downloadData)
  
  // Also increment the download count
  await incrementAppDownloads(appId)
  
  return { data, error }
}

// ==================== CATEGORIES ====================

export const getCategories = async () => {
  const { data, error } = await supabase
    .from('categories')
    .select('*')
    .eq('is_active', true)
    .order('name')
  
  return { data, error }
}

// ==================== BLOG POSTS ====================

export const getBlogPosts = async (filters = {}) => {
  let query = supabase
    .from('blog_posts')
    .select('*')
    .eq('is_published', true)
    .order('is_featured', { ascending: false })
    .order('published_at', { ascending: false })

  if (filters.category && filters.category !== 'All') {
    query = query.eq('category', filters.category)
  }

  if (filters.featured) {
    query = query.eq('is_featured', true)
  }

  if (filters.search) {
    query = query.or(`title.ilike.%${filters.search}%,excerpt.ilike.%${filters.search}%`)
  }

  const { data, error } = await query
  return { data, error }
}

export const getBlogPost = async (id) => {
  const { data, error } = await supabase
    .from('blog_posts')
    .select('*')
    .eq('id', id)
    .eq('is_published', true)
    .single()
  
  return { data, error }
}

export const getBlogPostBySlug = async (slug) => {
  const { data, error } = await supabase
    .from('blog_posts')
    .select('*')
    .eq('slug', slug)
    .eq('is_published', true)
    .single()
  
  return { data, error }
}

export const incrementBlogViews = async (postId) => {
  const { data, error } = await supabase.rpc('increment_blog_views', {
    post_id: postId
  })
  
  return { data, error }
}

export const trackBlogView = async (postId, userEmail = null) => {
  const viewData = {
    post_id: postId,
    viewed_at: new Date().toISOString()
  }

  if (userEmail) {
    viewData.user_email = userEmail
  }

  const { data, error } = await supabase
    .from('blog_views')
    .insert(viewData)
  
  // Also increment the view count
  await incrementBlogViews(postId)
  
  return { data, error }
}

// ==================== SOLUTION REQUESTS ====================

export const createSolutionRequest = async (request) => {
  const { data, error } = await supabase
    .from('solution_requests')
    .insert(request)
    .select()
    .single()
  
  return { data, error }
}

export const getSolutionRequests = async (filters = {}) => {
  let query = supabase
    .from('solution_requests')
    .select('*')
    .order('created_at', { ascending: false })

  if (filters.status) {
    query = query.eq('status', filters.status)
  }

  if (filters.category) {
    query = query.eq('category', filters.category)
  }

  const { data, error } = await query
  return { data, error }
}

// ==================== STATISTICS ====================

export const getAppStats = async () => {
  const { data, error } = await supabase
    .from('applications')
    .select('app_type, download_count, price')
    .eq('is_active', true)

  if (error) return { data: null, error }

  const stats = {
    total: data.length,
    openSource: data.filter(app => app.app_type === 'open_source').length,
    pro: data.filter(app => app.app_type === 'pro').length,
    totalDownloads: data.reduce((sum, app) => sum + (app.download_count || 0), 0),
    totalRevenue: data
      .filter(app => app.app_type === 'pro')
      .reduce((sum, app) => sum + (app.price * app.download_count), 0)
  }

  return { data: stats, error: null }
}

export const getBlogStats = async () => {
  const { data, error } = await supabase
    .from('blog_posts')
    .select('view_count, like_count, comment_count')
    .eq('is_published', true)

  if (error) return { data: null, error }

  const stats = {
    totalPosts: data.length,
    totalViews: data.reduce((sum, post) => sum + (post.view_count || 0), 0),
    totalLikes: data.reduce((sum, post) => sum + (post.like_count || 0), 0),
    totalComments: data.reduce((sum, post) => sum + (post.comment_count || 0), 0)
  }

  return { data: stats, error: null }
}