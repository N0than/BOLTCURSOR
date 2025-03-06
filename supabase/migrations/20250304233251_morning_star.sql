/*
  # Add improved error handling and data validation

  1. New Functions
    - `validate_prediction_data`: Validates prediction data
    - `create_or_update_prediction`: Updated with better validation
    - `get_user_predictions`: Updated with better error handling

  2. Security
    - All functions are SECURITY DEFINER
    - Input validation for all parameters
    - Proper error messages in French
*/

-- Create a function to validate prediction data
CREATE OR REPLACE FUNCTION public.validate_prediction_data(
  p_show_id uuid,
  p_prediction integer
)
RETURNS boolean AS $$
BEGIN
  IF p_show_id IS NULL THEN
    RAISE EXCEPTION 'ID du programme requis';
  END IF;

  IF p_prediction IS NULL OR p_prediction < 0 THEN
    RAISE EXCEPTION 'Prédiction invalide';
  END IF;

  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Update create_or_update_prediction with better validation
CREATE OR REPLACE FUNCTION public.create_or_update_prediction(
  p_show_id uuid,
  p_prediction integer
)
RETURNS json AS $$
DECLARE
  v_user_id uuid;
  v_prediction_id uuid;
  v_result json;
  v_show_locked boolean;
BEGIN
  -- Validate user session
  v_user_id := public.validate_user_session();
  
  -- Validate input data
  PERFORM public.validate_prediction_data(p_show_id, p_prediction);
  
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
    SET 
      prediction = p_prediction,
      updated_at = now()
    WHERE id = v_prediction_id
    RETURNING to_json(predictions.*) INTO v_result;
  ELSE
    -- Create new prediction
    INSERT INTO public.predictions (
      user_id, 
      show_id, 
      prediction
    )
    VALUES (
      v_user_id, 
      p_show_id, 
      p_prediction
    )
    RETURNING to_json(predictions.*) INTO v_result;
  END IF;

  IF v_result IS NULL THEN
    RETURN public.handle_empty_result();
  END IF;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update get_user_predictions with better error handling
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
  v_user_id uuid;
BEGIN
  -- Validate user session
  v_user_id := public.validate_user_session();

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
    s.datetime DESC;

  -- Return empty result set if no predictions found
  IF NOT FOUND THEN
    RETURN;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.validate_prediction_data TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_or_update_prediction TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_predictions TO authenticated;