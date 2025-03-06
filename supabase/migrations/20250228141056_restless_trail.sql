/*
  # Fix Prediction Functionality

  1. Changes
    - Create a new secure function for getting user predictions
    - Fix permission issues with predictions table
    - Add proper RLS policies for predictions
*/

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.get_user_predictions(uuid);
DROP FUNCTION IF EXISTS public.get_user_predictions_secure(uuid);

-- Create a new secure function to get user predictions
CREATE OR REPLACE FUNCTION public.get_user_predictions_secure(p_user_id uuid)
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
  -- Only return predictions for the authenticated user
  IF auth.uid() = p_user_id THEN
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
  END IF;
  
  RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.get_user_predictions_secure TO authenticated;

-- Drop existing policies to avoid conflicts
DO $$ 
BEGIN
  BEGIN
    DROP POLICY IF EXISTS "Users can view their own predictions" ON public.predictions;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
  
  BEGIN
    DROP POLICY IF EXISTS "Users can create their own predictions" ON public.predictions;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
  
  BEGIN
    DROP POLICY IF EXISTS "Users can update their own predictions" ON public.predictions;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
  
  BEGIN
    DROP POLICY IF EXISTS "Admins can view all predictions" ON public.predictions;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
END $$;

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

-- Make sure the predictions table has RLS enabled
ALTER TABLE public.predictions ENABLE ROW LEVEL SECURITY;
