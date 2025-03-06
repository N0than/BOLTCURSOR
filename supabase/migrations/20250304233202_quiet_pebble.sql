/*
  # Add improved error handling functions

  1. New Functions
    - `handle_empty_result`: Handles empty query results
    - `validate_user_session`: Validates user authentication
    - `get_user_prediction_for_show`: Updated with better error handling
    - `get_user_predictions`: Updated with better error handling

  2. Security
    - All functions are SECURITY DEFINER
    - Proper error messages in French
*/

-- Create a function to handle empty results
CREATE OR REPLACE FUNCTION public.handle_empty_result()
RETURNS json AS $$
BEGIN
  RETURN json_build_object(
    'error', 'Aucune donnée trouvée',
    'code', 'EMPTY_RESULT'
  );
END;
$$ LANGUAGE plpgsql;

-- Create a function to validate user session
CREATE OR REPLACE FUNCTION public.validate_user_session()
RETURNS uuid AS $$
DECLARE
  v_user_id uuid;
BEGIN
  SELECT auth.uid() INTO v_user_id;
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifié';
  END IF;
  RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update get_user_prediction_for_show function with better error handling
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
    p.created_at
  FROM 
    public.predictions p
  WHERE 
    p.user_id = v_user_id AND
    p.show_id = p_show_id;

  IF NOT FOUND THEN
    RETURN;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update get_user_predictions function with better error handling
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
    p.created_at DESC;

  IF NOT FOUND THEN
    RETURN;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.handle_empty_result TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_user_session TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_prediction_for_show TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_predictions TO authenticated;