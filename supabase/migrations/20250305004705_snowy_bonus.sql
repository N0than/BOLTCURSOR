/*
  # Allow Show Management for All Users

  1. Changes
    - Allow all authenticated users to delete shows
    - Allow all authenticated users to update actual audience
    - Keep read access for everyone
    - Remove admin-only restrictions

  2. Security
    - Everyone can view shows
    - Authenticated users can manage shows
    - Proper RLS policies
*/

-- Make sure RLS is enabled
ALTER TABLE public.shows ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Shows viewable by everyone" ON public.shows;
DROP POLICY IF EXISTS "Shows manageable by admins" ON public.shows;
DROP POLICY IF EXISTS "Shows manageable by authenticated users" ON public.shows;

-- Create new policies
CREATE POLICY "Shows viewable by everyone"
ON public.shows FOR SELECT
USING (true);

CREATE POLICY "Shows manageable by authenticated users"
ON public.shows
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Grant necessary permissions
GRANT ALL ON public.shows TO authenticated;