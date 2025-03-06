/*
  # Fix permission issues with users table
  
  1. Changes
    - Ensure proper RLS policies for the users table
    - Fix permission denied errors when accessing user data
    - Add policy for authenticated users to view all users
*/

-- Make sure RLS is enabled on the users table
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DO $$ 
BEGIN
  BEGIN
    DROP POLICY IF EXISTS "View profiles" ON public.users;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
  
  BEGIN
    DROP POLICY IF EXISTS "Update own profile" ON public.users;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
  
  BEGIN
    DROP POLICY IF EXISTS "Create own profile" ON public.users;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
  
  BEGIN
    DROP POLICY IF EXISTS "Allow public profile viewing" ON public.users;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
  
  BEGIN
    DROP POLICY IF EXISTS "Allow users to update their profile" ON public.users;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
  
  BEGIN
    DROP POLICY IF EXISTS "Allow users to create their profile" ON public.users;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
  
  BEGIN
    DROP POLICY IF EXISTS "Enable public profile viewing" ON public.users;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
  
  BEGIN
    DROP POLICY IF EXISTS "Enable user profile updates" ON public.users;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
  
  BEGIN
    DROP POLICY IF EXISTS "Enable user profile creation" ON public.users;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
END $$;

-- Create new policies with clear names
CREATE POLICY "Anyone can view users"
ON public.users
FOR SELECT
USING (true);

CREATE POLICY "Users can update their own profile"
ON public.users
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
ON public.users
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Fix permissions for predictions table
DO $$ 
BEGIN
  BEGIN
    DROP POLICY IF EXISTS "Users can view their own predictions" ON public.predictions;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
END $$;

CREATE POLICY "Users can view their own predictions"
ON public.predictions
FOR SELECT
TO authenticated
USING (auth.uid() = user_id OR EXISTS (
  SELECT 1 FROM auth.users
  WHERE auth.users.id = auth.uid()
  AND auth.users.role = 'admin'
));
