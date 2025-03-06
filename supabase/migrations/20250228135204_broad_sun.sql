/*
  # Fix permissions for predictions and users tables
  
  1. Changes
    - Fix permission denied errors for the predictions table
    - Ensure proper RLS policies for joining predictions with users
    - Add policy for users to view their own predictions with related data
    - Create a function to get user predictions without joining with users table
*/

-- Fix permissions for predictions table
DO $$ 
BEGIN
  BEGIN
    DROP POLICY IF EXISTS "Users can view their own predictions" ON public.predictions;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
END $$;

-- Create a more permissive policy for predictions
CREATE POLICY "Users can view their own predictions"
ON public.predictions
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Create a policy for admins to view all predictions
DO $$ 
BEGIN
  BEGIN
    DROP POLICY IF EXISTS "Admins can view all predictions" ON public.predictions;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
END $$;

CREATE POLICY "Admins can view all predictions"
ON public.predictions
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'admin'
  )
);

-- Ensure the email column exists in the users table
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public'
    AND table_name = 'users' 
    AND column_name = 'email'
  ) THEN
    ALTER TABLE public.users ADD COLUMN email text;
  END IF;
END $$;

-- Create index on email column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE tablename = 'users' AND indexname = 'users_email_idx'
  ) THEN
    CREATE INDEX users_email_idx ON public.users(email);
  END IF;
END $$;

-- Fix the getUserPredictions function to avoid joining with users table
CREATE OR REPLACE FUNCTION public.get_user_predictions(input_user_id uuid)
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
    p.user_id = input_user_id
  ORDER BY 
    p.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.get_user_predictions TO authenticated;
