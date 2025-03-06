/*
  # Fix Shows Table Permissions

  1. Changes
    - Drop existing policies
    - Create new policies for shows table:
      - Everyone can view shows
      - Authenticated users can create shows
      - Only show owners can update/delete their own shows
      - Admins can manage all shows
    - Add owner_id column to shows table
    - Add trigger to set owner_id on insert

  2. Security
    - Enable RLS
    - Add policies for different access levels
    - Ensure proper permission checks
*/

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Shows viewable by everyone" ON public.shows;
DROP POLICY IF EXISTS "Shows manageable by admins" ON public.shows;
DROP POLICY IF EXISTS "Shows manageable by authenticated users" ON public.shows;

-- Make sure RLS is enabled
ALTER TABLE public.shows ENABLE ROW LEVEL SECURITY;

-- Add owner_id column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'shows' 
    AND column_name = 'owner_id'
  ) THEN
    ALTER TABLE public.shows ADD COLUMN owner_id uuid REFERENCES auth.users(id);
  END IF;
END $$;

-- Create trigger to set owner_id on insert
CREATE OR REPLACE FUNCTION set_show_owner()
RETURNS TRIGGER AS $$
BEGIN
  NEW.owner_id := auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_show_owner_trigger ON public.shows;
CREATE TRIGGER set_show_owner_trigger
  BEFORE INSERT ON public.shows
  FOR EACH ROW
  EXECUTE FUNCTION set_show_owner();

-- Create new policies for shows table
CREATE POLICY "Shows viewable by everyone"
ON public.shows FOR SELECT
USING (true);

CREATE POLICY "Shows insertable by authenticated users"
ON public.shows FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Shows updatable by owner"
ON public.shows FOR UPDATE
TO authenticated
USING (auth.uid() = owner_id OR EXISTS (
  SELECT 1 FROM auth.users
  WHERE auth.users.id = auth.uid()
  AND auth.users.role = 'admin'
))
WITH CHECK (auth.uid() = owner_id OR EXISTS (
  SELECT 1 FROM auth.users
  WHERE auth.users.id = auth.uid()
  AND auth.users.role = 'admin'
));

CREATE POLICY "Shows deletable by owner"
ON public.shows FOR DELETE
TO authenticated
USING (auth.uid() = owner_id OR EXISTS (
  SELECT 1 FROM auth.users
  WHERE auth.users.id = auth.uid()
  AND auth.users.role = 'admin'
));

-- Grant necessary permissions
GRANT ALL ON public.shows TO authenticated;