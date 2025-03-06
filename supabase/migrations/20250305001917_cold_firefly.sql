/*
  # Fix shows table permissions

  1. Changes
    - Drop existing policies
    - Create new policies with proper admin access
    - Add explicit admin role check
    - Grant necessary permissions

  2. Security
    - Enable RLS on shows table
    - Ensure admin users have full access
    - Allow public read access
*/

-- Make sure RLS is enabled
ALTER TABLE public.shows ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Enable read access for all users" ON public.shows;
DROP POLICY IF EXISTS "Enable insert for admin users" ON public.shows;
DROP POLICY IF EXISTS "Enable update for admin users" ON public.shows;
DROP POLICY IF EXISTS "Enable delete for admin users" ON public.shows;

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
CREATE POLICY "Allow public read access"
ON public.shows FOR SELECT
USING (true);

CREATE POLICY "Allow admin full access"
ON public.shows
FOR ALL
TO authenticated
USING (
  (SELECT role = 'admin' FROM auth.users WHERE id = auth.uid())
)
WITH CHECK (
  (SELECT role = 'admin' FROM auth.users WHERE id = auth.uid())
);

-- Grant necessary permissions
GRANT SELECT ON public.shows TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.shows TO authenticated;