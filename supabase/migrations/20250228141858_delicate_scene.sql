/*
  # Fix Predictions Table Permissions

  1. Changes
     - Fix permission issues with the predictions table
     - Create a more robust function to get user predictions without joining users table
     - Update RLS policies to ensure proper access control
     - Fix the createPrediction function to handle both insert and update cases properly
*/

-- Make sure RLS is enabled on the predictions table
ALTER TABLE public.predictions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own predictions" ON public.predictions;
DROP POLICY IF EXISTS "Users can create their own predictions" ON public.predictions;
DROP POLICY IF EXISTS "Users can update their own predictions" ON public.predictions;
DROP POLICY IF EXISTS "Admins can manage all predictions" ON public.predictions;
DROP POLICY IF EXISTS "Admins can view all predictions" ON public.predictions;

-- Create more permissive policies for predictions
CREATE POLICY "Users can view their own predictions"
ON public.predictions
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own predictions"
ON public.predictions
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own predictions"
ON public.predictions
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can manage all predictions"
ON public.predictions
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'admin'
  )
);

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.get_user_predictions(uuid);

-- Create a more robust function to get user predictions
CREATE OR REPLACE FUNCTION public.get_user_predictions(p_user_id uuid)
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
    p.user_id = p_user_id
  ORDER BY 
    p.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.get_user_predictions TO authenticated;

-- Make sure the unique constraint exists
ALTER TABLE public.predictions
DROP CONSTRAINT IF EXISTS unique_user_show_prediction;

ALTER TABLE public.predictions
ADD CONSTRAINT unique_user_show_prediction UNIQUE (user_id, show_id);

-- Create a function to get a single prediction for a user and show
CREATE OR REPLACE FUNCTION public.get_user_prediction_for_show(p_user_id uuid, p_show_id uuid)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  show_id uuid,
  prediction integer,
  actual_audience integer,
  accuracy float,
  created_at timestamptz
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
    p.created_at
  FROM 
    public.predictions p
  WHERE 
    p.user_id = p_user_id AND
    p.show_id = p_show_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.get_user_prediction_for_show TO authenticated;
