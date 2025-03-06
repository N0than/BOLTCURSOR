/*
  # Fix Predictions Table and Add Updated At Column

  1. Changes
    - Add updated_at column to predictions table
    - Add trigger to automatically update updated_at
    - Fix user statistics calculation
    - Add missing indexes

  2. Security
    - Maintain existing RLS policies
*/

-- Add updated_at column to predictions table
ALTER TABLE public.predictions 
ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_prediction_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS update_prediction_timestamp ON public.predictions;
CREATE TRIGGER update_prediction_timestamp
  BEFORE UPDATE ON public.predictions
  FOR EACH ROW
  EXECUTE FUNCTION update_prediction_updated_at();

-- Update user statistics function to handle null values
CREATE OR REPLACE FUNCTION update_user_statistics()
RETURNS TRIGGER AS $$
BEGIN
  -- Update user statistics when a prediction is created/updated
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
    ), 0)
  WHERE id = NEW.user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate trigger for updating user statistics
DROP TRIGGER IF EXISTS update_user_stats_on_prediction ON public.predictions;
CREATE TRIGGER update_user_stats_on_prediction
  AFTER INSERT OR UPDATE ON public.predictions
  FOR EACH ROW
  EXECUTE FUNCTION update_user_statistics();

-- Add missing indexes
CREATE INDEX IF NOT EXISTS idx_predictions_user_id ON public.predictions(user_id);
CREATE INDEX IF NOT EXISTS idx_predictions_show_id ON public.predictions(show_id);
CREATE INDEX IF NOT EXISTS idx_predictions_created_at ON public.predictions(created_at);
CREATE INDEX IF NOT EXISTS idx_predictions_updated_at ON public.predictions(updated_at);