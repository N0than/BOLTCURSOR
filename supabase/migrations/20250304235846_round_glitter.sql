-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Enable read access for everyone" ON public.users;
DROP POLICY IF EXISTS "Enable update for users based on id" ON public.users;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.users;
DROP POLICY IF EXISTS "Enable full access for admin users" ON public.users;

-- Make sure RLS is enabled
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

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

-- Create new policies with clear names and proper permissions
CREATE POLICY "Allow public read access"
ON public.users FOR SELECT
USING (true);

CREATE POLICY "Allow users to update own profile"
ON public.users FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "Allow users to insert own profile"
ON public.users FOR INSERT
WITH CHECK (auth.uid() = id);

CREATE POLICY "Allow admins full access"
ON public.users FOR ALL
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON public.users TO authenticated;