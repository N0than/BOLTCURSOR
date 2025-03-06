/*
  # Fix RLS policies and permissions

  1. Changes
    - Drop all existing policies
    - Create new unified policies
    - Fix admin access permissions
    - Ensure proper table access

  2. Security
    - Enable RLS on all tables
    - Set up proper admin role checks
    - Grant necessary permissions
*/

-- Make sure RLS is enabled on both tables
ALTER TABLE public.shows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies to avoid conflicts
DROP POLICY IF EXISTS "Enable read access for everyone" ON public.shows;
DROP POLICY IF EXISTS "Enable admin full access" ON public.shows;
DROP POLICY IF EXISTS "Enable public read access for users" ON public.users;
DROP POLICY IF EXISTS "Enable admin full access for users" ON public.users;

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

-- Create new policies for shows table
CREATE POLICY "Shows viewable by everyone"
ON public.shows FOR SELECT
USING (true);

CREATE POLICY "Shows manageable by admins"
ON public.shows
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Create new policies for users table
CREATE POLICY "Users viewable by everyone"
ON public.users FOR SELECT
USING (true);

CREATE POLICY "Users manageable by admins"
ON public.users
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Grant necessary permissions
GRANT ALL ON public.shows TO authenticated;
GRANT ALL ON public.users TO authenticated;