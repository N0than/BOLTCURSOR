/*
  # Add admin role and default admin account

  1. Changes
    - Add role column to auth.users
    - Create default admin account
    - Add RLS policies for admin access

  2. Security
    - Only admins can access admin features
    - Admin role is protected by RLS
*/

-- Add role column to auth.users if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'auth' 
    AND table_name = 'users' 
    AND column_name = 'role'
  ) THEN
    ALTER TABLE auth.users ADD COLUMN role text DEFAULT 'user';
  END IF;
END $$;

-- Create the admin user if it doesn't exist
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at
)
SELECT
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'admin',
  'admin@audiencemasters.com',
  crypt('admin', gen_salt('bf')),
  NOW(),
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM auth.users WHERE email = 'admin@audiencemasters.com'
);

-- Create admin user profile
INSERT INTO public.users (
  id,
  username,
  avatar,
  score,
  accuracy,
  predictions_count
)
SELECT
  id,
  'Admin',
  'https://api.dicebear.com/7.x/initials/svg?seed=Admin',
  0,
  0,
  0
FROM auth.users
WHERE email = 'admin@audiencemasters.com'
AND NOT EXISTS (
  SELECT 1 FROM public.users WHERE username = 'Admin'
);

-- Update RLS policies for admin features
CREATE POLICY "Only admins can access admin features"
ON public.shows
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'admin'
  )
);
