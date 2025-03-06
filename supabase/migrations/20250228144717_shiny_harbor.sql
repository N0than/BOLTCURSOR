/*
  # Fix prediction permissions

  1. Changes
     - Remove dependency on users table in prediction operations
     - Create a new secure function for creating/updating predictions
     - Fix RLS policies for predictions table
*/

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

-- Update the user statistics function to avoid accessing users table directly
DO $$ 
BEGIN
  -- Check if the trigger already exists
  IF EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'update_prediction_accuracy'
  ) THEN
    -- Trigger exists, drop it first
    DROP TRIGGER IF EXISTS update_prediction_accuracy ON public.predictions;
  END IF;
  
  -- Check if the old trigger exists
  IF EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'update_user_stats_on_prediction'
  ) THEN
    -- Old trigger exists, drop it
    DROP TRIGGER IF EXISTS update_user_stats_on_prediction ON public.predictions;
  END IF;
END $$;

-- Create or replace the function
CREATE OR REPLACE FUNCTION update_user_statistics()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate accuracy if actual_audience is available
  IF NEW.actual_audience IS NOT NULL AND NEW.actual_audience > 0 THEN
    NEW.accuracy := GREATEST(0, 100 - ABS((NEW.prediction::float - NEW.actual_audience::float) / NEW.actual_audience::float * 100));
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER update_prediction_accuracy
  BEFORE INSERT OR UPDATE ON public.predictions
  FOR EACH ROW
  EXECUTE FUNCTION update_user_statistics();
