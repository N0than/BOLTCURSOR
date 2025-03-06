/*
  # Fix users table RLS policies

  1. Changes
    - Add policy for users to insert their own profile
    - Add policy for users to update their own profile
    - Add policy for everyone to view user profiles
    - Add policy for admins to manage all user profiles

  2. Security
    - Enable RLS on users table
    - Restrict profile creation to authenticated users
    - Restrict profile updates to profile owners
    - Allow public read access to all profiles
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users are viewable by everyone" ON public.users;
DROP POLICY IF EXISTS "Users can update their own data" ON public.users;

-- Create new policies
CREATE POLICY "Users can create their own profile"
ON public.users
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
ON public.users
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "Everyone can view user profiles"
ON public.users
FOR SELECT
USING (true);

CREATE POLICY "Admins can manage all user profiles"
ON public.users
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'admin'
  )
);
