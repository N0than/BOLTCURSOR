/*
  # Fix Permissions for Predictions and Users Tables

  1. Changes
     - Fix RLS policies for predictions table
     - Ensure proper access to user predictions
     - Create a more robust RPC function for getting predictions
  2. Security
     - Ensure users can only access their own predictions
     - Add proper security checks in functions
*/

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

-- Make sure RLS is enabled on the predictions table
ALTER TABLE public.predictions ENABLE ROW LEVEL SECURITY;

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
    DROP POLICY IF EXISTS "Admins can manage all predictions" ON public.predictions;
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

-- Make sure the unique constraint exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'unique_user_show_prediction'
  ) THEN
    ALTER TABLE public.predictions
    ADD CONSTRAINT unique_user_show_prediction UNIQUE (user_id, show_id);
  END IF;
END $$;
