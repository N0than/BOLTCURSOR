/*
  # Fix permissions for shows and users tables

  1. Changes
    - Drop existing policies
    - Create new policies with proper admin access
    - Add explicit admin role check
    - Grant necessary permissions

  2. Security
    - Enable RLS on both tables
    - Ensure admin users have full access
    - Allow public read access
*/

-- Make sure RLS is enabled on both tables
ALTER TABLE public.shows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Allow public read access" ON public.shows;
DROP POLICY IF EXISTS "Allow admin full access" ON public.shows;

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
CREATE POLICY "Enable read access for everyone"
ON public.shows FOR SELECT
USING (true);

CREATE POLICY "Enable admin full access"
ON public.shows
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Create policies for users table
CREATE POLICY "Enable public read access for users"
ON public.users FOR SELECT
USING (true);

CREATE POLICY "Enable admin full access for users"
ON public.users
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Grant necessary permissions
GRANT ALL ON public.shows TO authenticated;
GRANT ALL ON public.users TO authenticated;