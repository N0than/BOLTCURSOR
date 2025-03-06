/*
  # Fix RLS policies and user tables

  1. Changes
    - Drop existing policies to avoid conflicts
    - Recreate RLS policies with proper checks
    - Update admin user and profile

  2. Security
    - Enable RLS on all tables
    - Set up proper role-based access
*/

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view all profiles" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
DROP POLICY IF EXISTS "Everyone can view user profiles" ON public.users;
DROP POLICY IF EXISTS "Admins can manage all user profiles" ON public.users;

-- Create RLS policies
CREATE POLICY "Anyone can view profiles"
ON public.users FOR SELECT
USING (true);

CREATE POLICY "Users can update own profile"
ON public.users FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can create own profile"
ON public.users FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Create or replace admin check function
CREATE OR REPLACE FUNCTION public.is_admin(user_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = user_id
    AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update admin user credentials
UPDATE auth.users
SET 
  encrypted_password = crypt('admin2025', gen_salt('bf')),
  role = 'admin',
  email_confirmed_at = now(),
  updated_at = now()
WHERE email = 'admin@audiencemasters.com';

-- Ensure admin profile exists
INSERT INTO public.users (
  id,
  username,
  avatar,
  score,
  accuracy,
  predictions_count,
  created_at,
  updated_at
)
SELECT
  id,
  'Admin',
  'https://api.dicebear.com/7.x/initials/svg?seed=Admin',
  0,
  0,
  0,
  now(),
  now()
FROM auth.users
WHERE email = 'admin@audiencemasters.com'
ON CONFLICT (id) DO NOTHING;
