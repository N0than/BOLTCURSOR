/*
  # Fix Predictions Validation and User Profiles

  1. Changes
    - Add trigger to automatically create user profiles
    - Add function to validate predictions
    - Add function to create or update predictions with validation
    - Update RLS policies for predictions
*/

-- Create function to ensure user profile exists
CREATE OR REPLACE FUNCTION ensure_user_profile()
RETURNS TRIGGER AS $$
DECLARE
  v_username text;
BEGIN
  -- Get username from metadata or email
  v_username := NEW.raw_user_meta_data->>'username';
  IF v_username IS NULL OR v_username = '' THEN
    v_username := split_part(NEW.email, '@', 1);
  END IF;

  -- Create user profile if it doesn't exist
  INSERT INTO public.users (
    id,
    username,
    email,
    avatar,
    score,
    accuracy,
    predictions_count,
    is_online
  ) VALUES (
    NEW.id,
    v_username,
    NEW.email,
    'https://api.dicebear.com/7.x/initials/svg?seed=' || v_username,
    0,
    0,
    0,
    true
  ) ON CONFLICT (id) DO UPDATE
  SET 
    email = NEW.email,
    updated_at = now();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to ensure user profile exists
DROP TRIGGER IF EXISTS ensure_user_profile_trigger ON auth.users;
CREATE TRIGGER ensure_user_profile_trigger
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION ensure_user_profile();

-- Create function to check if show is locked
CREATE OR REPLACE FUNCTION is_show_locked(p_show_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.shows
    WHERE id = p_show_id
    AND actual_audience IS NOT NULL
  );
END;
$$ LANGUAGE plpgsql;

-- Create function to validate prediction
CREATE OR REPLACE FUNCTION validate_prediction(
  p_show_id uuid,
  p_prediction integer
)
RETURNS boolean AS $$
BEGIN
  -- Check if prediction is positive
  IF p_prediction <= 0 THEN
    RAISE EXCEPTION 'La prédiction doit être un nombre positif';
  END IF;

  -- Check if show exists
  IF NOT EXISTS (SELECT 1 FROM public.shows WHERE id = p_show_id) THEN
    RAISE EXCEPTION 'Programme non trouvé';
  END IF;

  -- Check if show is locked
  IF public.is_show_locked(p_show_id) THEN
    RAISE EXCEPTION 'Ce programme est verrouillé, vous ne pouvez plus modifier votre pronostic';
  END IF;

  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Create function to create or update prediction with validation
CREATE OR REPLACE FUNCTION create_or_update_prediction(
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
    RAISE EXCEPTION 'Vous devez être connecté pour faire une prédiction';
  END IF;

  -- Ensure user profile exists
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = v_user_id) THEN
    INSERT INTO public.users (
      id,
      username,
      email,
      avatar,
      score,
      accuracy,
      predictions_count,
      is_online
    )
    SELECT
      v_user_id,
      split_part(auth.email(), '@', 1),
      auth.email(),
      'https://api.dicebear.com/7.x/initials/svg?seed=' || split_part(auth.email(), '@', 1),
      0,
      0,
      0,
      true;
  END IF;

  -- Validate prediction
  PERFORM validate_prediction(p_show_id, p_prediction);

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

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own predictions" ON public.predictions;
DROP POLICY IF EXISTS "Users can create their own predictions" ON public.predictions;
DROP POLICY IF EXISTS "Users can update their own predictions" ON public.predictions;

-- Create new policies
CREATE POLICY "Users can view their own predictions"
ON public.predictions FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own predictions"
ON public.predictions FOR INSERT
WITH CHECK (
  auth.uid() = user_id AND
  NOT public.is_show_locked(show_id)
);

CREATE POLICY "Users can update their own predictions"
ON public.predictions FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (
  auth.uid() = user_id AND
  NOT public.is_show_locked(show_id)
);

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.is_show_locked TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_prediction TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_or_update_prediction TO authenticated;