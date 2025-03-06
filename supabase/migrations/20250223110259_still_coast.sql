/*
  # Add actual_audience column to shows table
  
  1. Changes
    - Add actual_audience column to shows table
    - Add trigger to update prediction accuracy when actual_audience is set
    - Add function to calculate prediction accuracy
  
  2. Security
    - Maintain existing RLS policies
*/

-- Add actual_audience column to shows table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'shows' 
    AND column_name = 'actual_audience'
  ) THEN
    ALTER TABLE public.shows ADD COLUMN actual_audience integer;
  END IF;
END $$;

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
