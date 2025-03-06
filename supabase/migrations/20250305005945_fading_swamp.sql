/*
  # Fix User Constraints and Foreign Keys

  1. Changes
    - Modify username length constraint to be more permissive
    - Add trigger to automatically create user profile
    - Add function to handle user creation
    - Update RLS policies
*/

-- Drop existing username length constraint
ALTER TABLE public.users 
DROP CONSTRAINT IF EXISTS username_length;

-- Add new more permissive username length constraint
ALTER TABLE public.users 
ADD CONSTRAINT username_length CHECK (char_length(username) >= 1);

-- Create function to ensure user profile exists
CREATE OR REPLACE FUNCTION ensure_user_profile()
RETURNS TRIGGER AS $$
DECLARE
  v_username text;
BEGIN
  -- Get username from metadata or email
  v_username := NEW.raw_user_meta_data->>'username';
  IF v_username IS NULL THEN
    v_username := split_part(NEW.email, '@', 1);
  END IF;

  -- Create user profile if it doesn't exist
  INSERT INTO public.users (
    id,
    username,
    email,
    avatar,
    score,
    accuracy,
    predictions_count,
    is_online
  ) VALUES (
    NEW.id,
    v_username,
    NEW.email,
    'https://api.dicebear.com/7.x/initials/svg?seed=' || v_username,
    0,
    0,
    0,
    true
  ) ON CONFLICT (id) DO UPDATE
  SET 
    email = NEW.email,
    updated_at = now();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to ensure user profile exists
DROP TRIGGER IF EXISTS ensure_user_profile_trigger ON auth.users;
CREATE TRIGGER ensure_user_profile_trigger
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION ensure_user_profile();

-- Update RLS policies for users table
DROP POLICY IF EXISTS "Users viewable by everyone" ON public.users;
DROP POLICY IF EXISTS "Users can manage their own profile" ON public.users;

CREATE POLICY "Users viewable by everyone"
ON public.users FOR SELECT
USING (true);

CREATE POLICY "Users can manage their own profile"
ON public.users
FOR ALL
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Create function to get user predictions
CREATE OR REPLACE FUNCTION get_user_predictions()
RETURNS TABLE (
  id uuid,
  user_id uuid,
  show_id uuid,
  prediction integer,
  actual_audience integer,
  accuracy float,
  created_at timestamptz,
  show_title text,
  show_channel text,
  show_datetime timestamptz,
  show_description text,
  show_genre text,
  show_image_url text
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.user_id,
    p.show_id,
    p.prediction,
    p.actual_audience,
    p.accuracy,
    p.created_at,
    s.title,
    s.channel,
    s.datetime,
    s.description,
    s.genre,
    s."imageUrl"
  FROM 
    public.predictions p
  JOIN 
    public.shows s ON p.show_id = s.id
  WHERE 
    p.user_id = auth.uid()
  ORDER BY 
    p.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_user_predictions TO authenticated;