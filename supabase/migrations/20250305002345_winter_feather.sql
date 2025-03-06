/*
  # Fix RLS policies for shows table

  1. Changes
    - Drop all existing policies
    - Create new unified policies
    - Fix admin access permissions
    - Ensure proper table access

  2. Security
    - Enable RLS on shows table
    - Set up proper admin role checks
    - Grant necessary permissions
*/

-- Make sure RLS is enabled
ALTER TABLE public.shows ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies to avoid conflicts
DROP POLICY IF EXISTS "Shows viewable by everyone" ON public.shows;
DROP POLICY IF EXISTS "Shows manageable by admins" ON public.shows;
DROP POLICY IF EXISTS "Enable read access for everyone" ON public.shows;
DROP POLICY IF EXISTS "Enable admin full access" ON public.shows;

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
CREATE POLICY "Shows read access"
ON public.shows FOR SELECT
USING (true);

CREATE POLICY "Shows admin access"
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