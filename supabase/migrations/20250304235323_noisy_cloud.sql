/*
  # Fix database permissions

  1. Changes
    - Drop and recreate RLS policies for users table
    - Add admin check function
    - Grant proper permissions to authenticated users
    - Fix show table policies
    
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

-- Make sure RLS is enabled on both tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shows ENABLE ROW LEVEL SECURITY;

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

-- Create new policies for users table
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

-- Drop existing policies for shows table
DROP POLICY IF EXISTS "Shows are viewable by everyone" ON public.shows;
DROP POLICY IF EXISTS "Shows can be created by authenticated users" ON public.shows;
DROP POLICY IF EXISTS "Shows can be updated by authenticated users" ON public.shows;
DROP POLICY IF EXISTS "Shows can be deleted by authenticated users" ON public.shows;

-- Create new policies for shows table
CREATE POLICY "Allow public read access for shows"
ON public.shows FOR SELECT
USING (true);

CREATE POLICY "Allow admin write access for shows"
ON public.shows FOR ALL
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON public.users TO authenticated;
GRANT SELECT ON public.shows TO authenticated;