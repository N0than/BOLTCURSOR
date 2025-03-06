/*
  # Fix shows table RLS policies

  1. Changes
    - Drop existing policies to avoid conflicts
    - Create new policies for shows table with proper admin access
    - Add policies for CRUD operations
    - Add admin-specific policies

  2. Security
    - Enable RLS on shows table
    - Ensure admin users have full access
    - Allow public read access
*/

-- Make sure RLS is enabled
ALTER TABLE public.shows ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Shows are viewable by everyone" ON public.shows;
DROP POLICY IF EXISTS "Shows can be created by authenticated users" ON public.shows;
DROP POLICY IF EXISTS "Shows can be updated by authenticated users" ON public.shows;
DROP POLICY IF EXISTS "Shows can be deleted by authenticated users" ON public.shows;
DROP POLICY IF EXISTS "Allow admins to update actual_audience" ON public.shows;
DROP POLICY IF EXISTS "Allow public read access for shows" ON public.shows;
DROP POLICY IF EXISTS "Allow admin write access for shows" ON public.shows;

-- Create admin check function if it doesn't exist
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

-- Create new policies
CREATE POLICY "Enable read access for all users"
ON public.shows FOR SELECT
USING (true);

CREATE POLICY "Enable insert for admin users"
ON public.shows FOR INSERT
TO authenticated
WITH CHECK (public.is_admin());

CREATE POLICY "Enable update for admin users"
ON public.shows FOR UPDATE
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY "Enable delete for admin users"
ON public.shows FOR DELETE
TO authenticated
USING (public.is_admin());

-- Grant necessary permissions
GRANT SELECT ON public.shows TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.shows TO authenticated;