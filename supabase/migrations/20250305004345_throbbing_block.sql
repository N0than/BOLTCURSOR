/*
  # Fix Admin Permissions and Role Management

  1. Changes
    - Add admin role check function
    - Set up proper RLS policies for shows table
    - Ensure admin user exists with correct role
    - Fix permissions for managing shows

  2. Security
    - Only admins can manage shows
    - Everyone can view shows
    - Proper role-based access control
*/

-- Create or replace admin check function
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Make sure RLS is enabled
ALTER TABLE public.shows ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Shows viewable by everyone" ON public.shows;
DROP POLICY IF EXISTS "Shows manageable by admins" ON public.shows;
DROP POLICY IF EXISTS "Shows manageable by authenticated users" ON public.shows;

-- Create new policies with explicit admin role check
CREATE POLICY "Shows viewable by everyone"
ON public.shows FOR SELECT
USING (true);

CREATE POLICY "Shows manageable by admins"
ON public.shows
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Grant necessary permissions
GRANT ALL ON public.shows TO authenticated;

-- Ensure admin user exists with correct role and password
DO $$
BEGIN
  -- Update admin user if exists
  UPDATE auth.users 
  SET 
    role = 'admin',
    encrypted_password = crypt('admin2025', gen_salt('bf')),
    email_confirmed_at = now(),
    updated_at = now()
  WHERE email = 'admin@audiencemasters.com';

  -- If no admin exists, create one
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE email = 'admin@audiencemasters.com'
  ) THEN
    INSERT INTO auth.users (
      email,
      encrypted_password,
      role,
      email_confirmed_at,
      created_at,
      updated_at
    ) VALUES (
      'admin@audiencemasters.com',
      crypt('admin2025', gen_salt('bf')),
      'admin',
      now(),
      now(),
      now()
    );
  END IF;

  -- Create public profile for admin if it doesn't exist
  INSERT INTO public.users (
    id,
    username,
    email,
    avatar,
    score,
    accuracy,
    predictions_count,
    is_online
  )
  SELECT
    id,
    'Admin',
    'admin@audiencemasters.com',
    'https://api.dicebear.com/7.x/initials/svg?seed=Admin',
    0,
    0,
    0,
    true
  FROM auth.users
  WHERE email = 'admin@audiencemasters.com'
  ON CONFLICT (id) DO UPDATE
  SET 
    username = 'Admin',
    email = 'admin@audiencemasters.com',
    avatar = 'https://api.dicebear.com/7.x/initials/svg?seed=Admin',
    updated_at = now();
END $$;