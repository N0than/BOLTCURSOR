/*
  # Add prediction locking functionality
  
  1. Changes
    - Modify create_or_update_prediction function to check if show is locked
    - Add check for actual_audience before allowing prediction updates
  
  2. Security
    - Function uses SECURITY DEFINER to bypass RLS
    - Added proper validation to prevent modifying locked predictions
*/

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.create_or_update_prediction(uuid, integer);

-- Create an improved function to create or update a prediction with locking check
CREATE OR REPLACE FUNCTION public.create_or_update_prediction(
  p_show_id uuid,
  p_prediction integer
)
RETURNS json AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_prediction_id uuid;
  v_result json;
  v_show_locked boolean;
BEGIN
  -- Check if user is authenticated
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Check if the show has an actual audience (locked)
  SELECT (actual_audience IS NOT NULL) INTO v_show_locked
  FROM public.shows
  WHERE id = p_show_id;
  
  IF v_show_locked THEN
    RAISE EXCEPTION 'Ce programme est verrouillé, vous ne pouvez plus modifier votre pronostic';
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
