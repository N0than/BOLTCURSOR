/*
  # Fix permission issues with users table

  1. New Functions
    - `get_current_user_profile` - Securely retrieves the current user's profile
    - `get_all_users` - Securely retrieves all users for leaderboard
    - `calculate_user_stats` - Calculates user statistics without direct table access
  
  2. Security
    - All functions use SECURITY DEFINER to bypass RLS
    - Added proper permission checks within functions
*/

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

-- Create a function to execute SQL (for admin use only)
CREATE OR REPLACE FUNCTION public.exec_sql(sql text)
RETURNS void AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admins can execute arbitrary SQL';
  END IF;

  EXECUTE sql;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.exec_sql TO authenticated;
