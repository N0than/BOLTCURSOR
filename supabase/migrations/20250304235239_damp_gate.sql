/*
  # Fix users table permissions

  1. Changes
    - Drop and recreate RLS policies for users table
    - Add admin role check function
    - Grant proper permissions to authenticated users
    
  2. Security
    - Enable RLS
    - Allow public read access
    - Restrict write access to own records
    - Grant full access to admins
*/

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Enable read access for everyone" ON public.users;
DROP POLICY IF EXISTS "Enable update for users based on id" ON public.users;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.users;
DROP POLICY IF EXISTS "Enable full access for admin users" ON public.users;

-- Make sure RLS is enabled
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

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
CREATE POLICY "Enable read access for everyone"
ON public.users FOR SELECT
USING (true);

CREATE POLICY "Enable update for users based on id"
ON public.users FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "Enable insert for authenticated users only"
ON public.users FOR INSERT
WITH CHECK (auth.uid() = id);

CREATE POLICY "Enable full access for admin users"
ON public.users FOR ALL
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Grant necessary permissions (without sequence)
GRANT SELECT, INSERT, UPDATE ON public.users TO authenticated;