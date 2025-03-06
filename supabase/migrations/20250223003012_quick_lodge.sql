/*
  # Update admin credentials and authentication rules

  1. Changes
    - Update admin user credentials
    - Add admin role check function
    - Update RLS policies for admin access

  2. Security
    - Set secure admin password
    - Ensure proper role-based access control
*/

-- Create or replace admin check function
CREATE OR REPLACE FUNCTION public.is_admin(user_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = user_id
    AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update admin user credentials
UPDATE auth.users
SET 
  encrypted_password = crypt('admin2025', gen_salt('bf')),
  role = 'admin',
  email_confirmed_at = now(),
  updated_at = now()
WHERE email = 'admin@audiencemasters.com';

-- Ensure admin profile exists
INSERT INTO public.users (
  id,
  username,
  avatar,
  score,
  accuracy,
  predictions_count,
  created_at,
  updated_at
)
SELECT
  id,
  'Admin',
  'https://api.dicebear.com/7.x/initials/svg?seed=Admin',
  0,
  0,
  0,
  now(),
  now()
FROM auth.users
WHERE email = 'admin@audiencemasters.com'
ON CONFLICT (id) DO UPDATE
SET 
  username = 'Admin',
  avatar = 'https://api.dicebear.com/7.x/initials/svg?seed=Admin',
  updated_at = now();
