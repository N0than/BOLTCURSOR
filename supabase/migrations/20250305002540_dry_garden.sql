/*
  # Fix permissions and RLS policies

  1. Changes
    - Enable RLS on shows table
    - Drop existing policies
    - Create new policies for shows table
    - Set up proper admin access
    - Grant necessary permissions

  2. Security
    - Ensure proper admin role checks
    - Maintain data integrity
    - Fix permission denied errors
*/

-- Make sure RLS is enabled
ALTER TABLE public.shows ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies to avoid conflicts
DROP POLICY IF EXISTS "Shows read access" ON public.shows;
DROP POLICY IF EXISTS "Shows admin access" ON public.shows;
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
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'admin'
  )
);

-- Grant necessary permissions
GRANT ALL ON public.shows TO authenticated;

-- Ensure admin role exists in auth.users
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE role = 'admin'
  ) THEN
    UPDATE auth.users 
    SET role = 'admin'
    WHERE email = 'admin@audiencemasters.com';
  END IF;
END $$;