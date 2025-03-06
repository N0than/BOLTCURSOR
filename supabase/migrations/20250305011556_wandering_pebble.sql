/*
  # Update Predictions System

  1. Changes
    - Allow users to create and update predictions
    - Allow setting actual audience values
    - Automatic statistics calculation
    - Prediction locking when actual audience is set
  
  2. Security
    - Keep RLS enabled
    - Maintain data validation
    - Automatic accuracy calculation
*/

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

-- Create function to calculate prediction accuracy
CREATE OR REPLACE FUNCTION calculate_prediction_accuracy(prediction integer, actual integer)
RETURNS float AS $$
BEGIN
  IF actual IS NULL OR prediction IS NULL OR actual = 0 THEN
    RETURN NULL;
  END IF;
  
  RETURN GREATEST(0, 100 - ABS((prediction::float - actual::float) / actual::float * 100));
END;
$$ LANGUAGE plpgsql;

-- Create function to update predictions accuracy
CREATE OR REPLACE FUNCTION update_predictions_accuracy()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.actual_audience IS DISTINCT FROM OLD.actual_audience THEN
    UPDATE public.predictions
    SET 
      actual_audience = NEW.actual_audience,
      accuracy = calculate_prediction_accuracy(prediction, NEW.actual_audience),
      updated_at = now()
    WHERE show_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for predictions accuracy
DROP TRIGGER IF EXISTS update_predictions_accuracy_trigger ON public.shows;
CREATE TRIGGER update_predictions_accuracy_trigger
  AFTER UPDATE OF actual_audience ON public.shows
  FOR EACH ROW
  EXECUTE FUNCTION update_predictions_accuracy();

-- Create function to update user statistics
CREATE OR REPLACE FUNCTION update_user_statistics()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.users
  SET 
    predictions_count = COALESCE((
      SELECT COUNT(*) 
      FROM public.predictions 
      WHERE user_id = NEW.user_id
    ), 0),
    accuracy = COALESCE((
      SELECT AVG(accuracy)
      FROM public.predictions
      WHERE user_id = NEW.user_id
      AND accuracy IS NOT NULL
    ), 0),
    score = COALESCE((
      SELECT SUM(FLOOR(COALESCE(accuracy, 0)))
      FROM public.predictions
      WHERE user_id = NEW.user_id
      AND accuracy IS NOT NULL
    ), 0),
    updated_at = now()
  WHERE id = NEW.user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for user statistics
DROP TRIGGER IF EXISTS update_user_stats_trigger ON public.predictions;
CREATE TRIGGER update_user_stats_trigger
  AFTER INSERT OR UPDATE ON public.predictions
  FOR EACH ROW
  EXECUTE FUNCTION update_user_statistics();

-- Create function to create or update prediction
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