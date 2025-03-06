/*
  # Allow Show Management for All Users

  1. Changes
    - Allow all authenticated users to manage shows
    - Enable full CRUD operations for authenticated users
    - Keep read access for everyone
    - Add functions for managing actual audiences

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

-- Create function to validate actual audience
CREATE OR REPLACE FUNCTION validate_actual_audience()
RETURNS TRIGGER AS $$
BEGIN
  -- Convert empty string to null
  IF NEW.actual_audience = 0 OR NEW.actual_audience IS NULL THEN
    NEW.actual_audience := NULL;
  END IF;

  -- Ensure actual_audience is positive when set
  IF NEW.actual_audience IS NOT NULL AND NEW.actual_audience < 0 THEN
    RAISE EXCEPTION 'L''audience réelle doit être un nombre positif';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to validate actual audience
DROP TRIGGER IF EXISTS validate_actual_audience_trigger ON public.shows;
CREATE TRIGGER validate_actual_audience_trigger
  BEFORE INSERT OR UPDATE ON public.shows
  FOR EACH ROW
  EXECUTE FUNCTION validate_actual_audience();

-- Grant necessary permissions
GRANT ALL ON public.shows TO authenticated;