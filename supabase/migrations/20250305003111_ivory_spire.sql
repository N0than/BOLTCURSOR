/*
  # Fix admin permissions and role setup

  1. Changes
    - Ensure admin role exists in auth.users
    - Set up proper RLS policies for shows table
    - Grant necessary permissions
    - Add validation for show creation

  2. Security
    - Maintain proper access control
    - Ensure admin operations work correctly
    - Keep data integrity
*/

-- Make sure RLS is enabled
ALTER TABLE public.shows ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Shows viewable by everyone" ON public.shows;
DROP POLICY IF EXISTS "Shows manageable by admins" ON public.shows;

-- Create or replace admin check function
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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

-- Ensure admin role exists and is set correctly
DO $$
BEGIN
  -- Update admin user if exists
  UPDATE auth.users 
  SET role = 'admin'
  WHERE email = 'admin@audiencemasters.com';

  -- If no admin exists, raise an exception
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE role = 'admin'
  ) THEN
    RAISE EXCEPTION 'No admin user found. Please ensure admin@audiencemasters.com exists.';
  END IF;
END $$;