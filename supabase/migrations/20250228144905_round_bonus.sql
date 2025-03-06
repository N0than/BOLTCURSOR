/*
  # Fix permissions for predictions and users tables

  1. Updates
    - Fix RLS policies for predictions table
    - Create a new stored procedure to get user predictions without joining users table
    - Update function to create or update predictions
  
  2. Security
    - Ensure proper RLS policies are in place
    - Use security definer functions to bypass RLS when needed
*/

-- Create a new migration to fix the permissions issues

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.get_user_prediction_for_show(uuid, uuid);

-- Create a new function to get a user's prediction for a specific show
-- This avoids joining with the users table which was causing permission issues
CREATE OR REPLACE FUNCTION public.get_user_prediction_for_show(p_show_id uuid)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  show_id uuid,
  prediction integer,
  actual_audience integer,
  accuracy float,
  created_at timestamptz
) AS $$
DECLARE
  v_user_id uuid := auth.uid();
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
    p.user_id = v_user_id AND
    p.show_id = p_show_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.get_user_prediction_for_show TO authenticated;

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.get_user_predictions(uuid);

-- Create a new function to get all predictions for a user
-- This avoids joining with the users table which was causing permission issues
CREATE OR REPLACE FUNCTION public.get_user_predictions()
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
DECLARE
  v_user_id uuid := auth.uid();
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
    p.user_id = v_user_id
  ORDER BY 
    p.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.get_user_predictions TO authenticated;

-- Make sure RLS is enabled on the predictions table
ALTER TABLE public.predictions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own predictions" ON public.predictions;
DROP POLICY IF EXISTS "Users can create their own predictions" ON public.predictions;
DROP POLICY IF EXISTS "Users can update their own predictions" ON public.predictions;
DROP POLICY IF EXISTS "Admins can manage all predictions" ON public.predictions;

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

-- Create a secure function to create or update a prediction
CREATE OR REPLACE FUNCTION public.create_or_update_prediction(
  p_show_id uuid,
  p_prediction integer
)
RETURNS json AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_prediction_id uuid;
  v_result json;
BEGIN
  -- Check if user is authenticated
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Check if prediction already exists
  SELECT id INTO v_prediction_id
  FROM public.predictions
  WHERE user_id = v_user_id AND show_id = p_show_id;

  IF v_prediction_id IS NOT NULL THEN
    -- Update existing prediction
    UPDATE public.predictions
    SET prediction = p_prediction
    WHERE id = v_prediction_id
    RETURNING to_json(predictions.*) INTO v_result;
  ELSE
    -- Create new prediction
    INSERT INTO public.predictions (user_id, show_id, prediction)
    VALUES (v_user_id, p_show_id, p_prediction)
    RETURNING to_json(predictions.*) INTO v_result;
  END IF;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.create_or_update_prediction TO authenticated;
