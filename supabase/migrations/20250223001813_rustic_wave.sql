/*
  # Fix admin role check

  1. Changes
    - Add admin role check function
    - Update admin user role check policy
    - Ensure admin user exists with correct role

  2. Security
    - Only allow admin role check through secure function
    - Maintain RLS policies
*/

-- Create a function to check admin role
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

-- Update admin user if needed
UPDATE auth.users
SET role = 'admin'
WHERE email = 'admin@audiencemasters.com'
AND role != 'admin';

-- Update RLS policies for admin features
DROP POLICY IF EXISTS "Only admins can access admin features" ON public.shows;

CREATE POLICY "Only admins can access admin features"
ON public.shows
FOR ALL
TO authenticated
USING (public.is_admin(auth.uid()));
