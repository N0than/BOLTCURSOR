-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Shows viewable by everyone" ON public.shows;
DROP POLICY IF EXISTS "Shows manageable by admins" ON public.shows;
DROP POLICY IF EXISTS "Users viewable by everyone" ON public.users;
DROP POLICY IF EXISTS "Users manageable by admins" ON public.users;

-- Make sure RLS is enabled on both tables
ALTER TABLE public.shows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Create or replace admin check function
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND role = 'admin'
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

-- Create policy for users to manage their own profiles
CREATE POLICY "Users can manage their own profiles"
ON public.users
FOR ALL
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Grant necessary permissions
GRANT ALL ON public.shows TO authenticated;
GRANT ALL ON public.users TO authenticated;

-- Ensure admin user exists with correct role and password
DO $$
BEGIN
  -- First, ensure the auth schema exists
  CREATE SCHEMA IF NOT EXISTS auth;

  -- Create the users table if it doesn't exist
  CREATE TABLE IF NOT EXISTS auth.users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text UNIQUE,
    encrypted_password text,
    role text DEFAULT 'user',
    email_confirmed_at timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
  );

  -- Update admin user if exists
  UPDATE auth.users 
  SET 
    role = 'admin',
    encrypted_password = crypt('admin2025', gen_salt('bf')),
    email_confirmed_at = now(),
    updated_at = now()
  WHERE email = 'admin@audiencemasters.com';

  -- If no admin exists, create one
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE email = 'admin@audiencemasters.com'
  ) THEN
    INSERT INTO auth.users (
      email,
      encrypted_password,
      role,
      email_confirmed_at,
      created_at,
      updated_at
    ) VALUES (
      'admin@audiencemasters.com',
      crypt('admin2025', gen_salt('bf')),
      'admin',
      now(),
      now(),
      now()
    );
  END IF;

  -- Create public profile for admin if it doesn't exist
  INSERT INTO public.users (
    id,
    username,
    email,
    avatar,
    score,
    accuracy,
    predictions_count,
    is_online
  )
  SELECT
    id,
    'Admin',
    'admin@audiencemasters.com',
    'https://api.dicebear.com/7.x/initials/svg?seed=Admin',
    0,
    0,
    0,
    true
  FROM auth.users
  WHERE email = 'admin@audiencemasters.com'
  ON CONFLICT (id) DO UPDATE
  SET 
    username = 'Admin',
    email = 'admin@audiencemasters.com',
    avatar = 'https://api.dicebear.com/7.x/initials/svg?seed=Admin',
    updated_at = now();
END $$;