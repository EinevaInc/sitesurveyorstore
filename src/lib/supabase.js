import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

// Debug environment variables
console.log('Environment:', import.meta.env.MODE)
console.log('Supabase URL configured:', !!supabaseUrl)
console.log('Supabase Key configured:', !!supabaseAnonKey)

// Check if environment variables are properly configured
const isConfigured = supabaseUrl && 
  supabaseAnonKey && 
  supabaseUrl.includes('supabase.co')

if (!isConfigured) {
  console.warn('⚠️ Supabase not configured properly!')
  console.warn('Please set up your environment variables:')
  console.warn('1. Copy .env.example to .env')
  console.warn('2. Replace placeholder values with your actual Supabase credentials')
  console.warn('3. Restart the development server')
}

// Create Supabase client with additional options for better error handling
let supabaseInstance;
try {
  if (!supabaseUrl || !supabaseAnonKey) {
    throw new Error('Missing Supabase credentials');
  }
  supabaseInstance = createClient(supabaseUrl, supabaseAnonKey, {
    auth: {
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: true
    },
    global: {
      headers: {
        'X-Client-Info': 'sitesurveyor-web'
      }
    }
  });
  console.log('Supabase client initialized successfully');
} catch (error) {
  console.error('Failed to initialize Supabase client:', error);
  supabaseInstance = null;
}

export const supabase = supabaseInstance;

// Test connection function
export const testConnection = async () => {
  if (!isConfigured) {
    console.warn('⚠️ Skipping connection test - Supabase not configured')
    return false
  }

  try {
    // Test with a simple query that should work
    const { data, error } = await supabase
      .from('categories')
      .select('count')
      .limit(1)
    
    if (error) {
      console.error('❌ Supabase connection test failed:', error.message)
      return false
    }
    
    console.log('✅ Supabase connection successful!')
    return true
  } catch (error) {
    console.error('❌ Supabase connection error:', error)
    return false
  }
}

// Export configuration status
export const isSupabaseConfigured = isConfigured

// Only test connection if properly configured
if (isConfigured) {
  testConnection()
}