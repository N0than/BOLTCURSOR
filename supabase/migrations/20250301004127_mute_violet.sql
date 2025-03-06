-- Create a function to get the current user's profile
CREATE OR REPLACE FUNCTION public.get_current_user_profile()
RETURNS json AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_result json;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT to_json(u) INTO v_result
  FROM public.users u
  WHERE u.id = v_user_id;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.get_current_user_profile TO authenticated;

-- Create a function to get all users for leaderboard
CREATE OR REPLACE FUNCTION public.get_all_users()
RETURNS SETOF public.users AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM public.users
  ORDER BY score DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.get_all_users TO authenticated;

-- Create a function to calculate user statistics
CREATE OR REPLACE FUNCTION public.calculate_user_stats(p_user_id uuid)
RETURNS json AS $$
DECLARE
  v_predictions_count integer;
  v_accuracy float;
  v_score integer;
  v_result json;
BEGIN
  -- Calculate statistics from predictions
  SELECT 
    COUNT(*),
    AVG(accuracy),
    SUM(FLOOR(COALESCE(accuracy, 0)))
  INTO
    v_predictions_count,
    v_accuracy,
    v_score
  FROM public.predictions
  WHERE user_id = p_user_id;

  -- Handle null values
  v_predictions_count := COALESCE(v_predictions_count, 0);
  v_accuracy := COALESCE(v_accuracy, 0);
  v_score := COALESCE(v_score, 0);

  -- Return the statistics as JSON
  v_result := json_build_object(
    'predictions_count', v_predictions_count,
    'accuracy', v_accuracy,
    'score', v_score
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.calculate_user_stats TO authenticated;
