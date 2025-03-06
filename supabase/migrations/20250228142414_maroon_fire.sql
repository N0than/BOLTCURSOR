/*
  # Fix Remaining Permissions Issues

  1. Changes
     - Fix permission issues with the predictions table when creating new predictions
     - Create a secure RPC function for creating and updating predictions
     - Update trigger functions to avoid accessing the users table directly
*/

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
CREATE OR REPLACE FUNCTION update_user_statistics()
RETURNS TRIGGER AS $$
BEGIN
  -- We'll use a direct update to the predictions table instead of joining with users
  -- This avoids permission issues with the users table
  
  -- Calculate accuracy if actual_audience is available
  IF NEW.actual_audience IS NOT NULL AND NEW.actual_audience > 0 THEN
    NEW.accuracy := GREATEST(0, 100 - ABS((NEW.prediction::float - NEW.actual_audience::float) / NEW.actual_audience::float * 100));
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate trigger for updating prediction accuracy
DROP TRIGGER IF EXISTS update_user_stats_on_prediction ON public.predictions;
CREATE TRIGGER update_prediction_accuracy
  BEFORE INSERT OR UPDATE ON public.predictions
  FOR EACH ROW
  EXECUTE FUNCTION update_user_statistics();

-- Create a function to update user statistics in a separate process
CREATE OR REPLACE FUNCTION public.update_user_stats_from_predictions()
RETURNS void AS $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN 
    SELECT 
      user_id,
      COUNT(*) as prediction_count,
      AVG(accuracy) as avg_accuracy,
      SUM(FLOOR(COALESCE(accuracy, 0))) as total_score
    FROM 
      public.predictions
    GROUP BY 
      user_id
  LOOP
    UPDATE public.users
    SET 
      predictions_count = r.prediction_count,
      accuracy = r.avg_accuracy,
      score = r.total_score
    WHERE 
      id = r.user_id;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.update_user_stats_from_predictions TO authenticated;
