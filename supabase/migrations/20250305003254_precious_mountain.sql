-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Shows viewable by everyone" ON public.shows;
DROP POLICY IF EXISTS "Shows manageable by admins" ON public.shows;

-- Make sure RLS is enabled
ALTER TABLE public.shows ENABLE ROW LEVEL SECURITY;

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

-- Create new policies with explicit admin role check
CREATE POLICY "Shows viewable by everyone"
ON public.shows FOR SELECT
USING (true);

CREATE POLICY "Shows manageable by admins"
ON public.shows
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Grant necessary permissions
GRANT ALL ON public.shows TO authenticated;

-- Ensure admin user exists with correct role and password
DO $$
BEGIN
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
END $$;