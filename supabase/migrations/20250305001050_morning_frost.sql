/*
  # Add actual audience persistence

  1. Changes
    - Add trigger to update predictions accuracy when actual_audience is set
    - Add function to calculate prediction accuracy
    - Add validation for actual_audience values

  2. Security
    - All functions are SECURITY DEFINER
    - Input validation for actual_audience
*/

-- Create function to calculate prediction accuracy
CREATE OR REPLACE FUNCTION calculate_prediction_accuracy(prediction integer, actual integer)
RETURNS float AS $$
BEGIN
  IF actual IS NULL OR prediction IS NULL OR actual = 0 THEN
    RETURN NULL;
  END IF;
  
  -- Calculate percentage difference and convert to accuracy
  RETURN GREATEST(0, 100 - ABS((prediction::float - actual::float) / actual::float * 100));
END;
$$ LANGUAGE plpgsql;

-- Create function to update predictions accuracy when actual_audience is set
CREATE OR REPLACE FUNCTION update_predictions_accuracy()
RETURNS TRIGGER AS $$
BEGIN
  -- Only proceed if actual_audience has changed
  IF NEW.actual_audience IS DISTINCT FROM OLD.actual_audience THEN
    -- Update accuracy for all predictions for this show
    UPDATE public.predictions
    SET 
      actual_audience = NEW.actual_audience,
      accuracy = calculate_prediction_accuracy(prediction, NEW.actual_audience)
    WHERE show_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update predictions accuracy
DROP TRIGGER IF EXISTS update_predictions_accuracy_trigger ON public.shows;
CREATE TRIGGER update_predictions_accuracy_trigger
  AFTER UPDATE OF actual_audience ON public.shows
  FOR EACH ROW
  EXECUTE FUNCTION update_predictions_accuracy();

-- Create function to validate actual audience
CREATE OR REPLACE FUNCTION validate_actual_audience()
RETURNS TRIGGER AS $$
BEGIN
  -- Convert empty string to null
  IF NEW.actual_audience = 0 OR NEW.actual_audience IS NULL THEN
    NEW.actual_audience := NULL;
  END IF;

  -- Ensure actual_audience is positive when set
  IF NEW.actual_audience IS NOT NULL AND NEW.actual_audience < 0 THEN
    RAISE EXCEPTION 'L''audience réelle doit être un nombre positif';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to validate actual audience
DROP TRIGGER IF EXISTS validate_actual_audience_trigger ON public.shows;
CREATE TRIGGER validate_actual_audience_trigger
  BEFORE INSERT OR UPDATE ON public.shows
  FOR EACH ROW
  EXECUTE FUNCTION validate_actual_audience();