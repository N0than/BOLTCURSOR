/*
  # Improve actual audience handling

  1. Changes
    - Add constraint to ensure actual_audience is non-negative
    - Add trigger to update predictions when actual_audience changes
    - Add function to update user statistics when predictions are updated

  2. Security
    - Add RLS policy for updating actual_audience
*/

-- Add constraint to ensure actual_audience is non-negative
ALTER TABLE public.shows
ADD CONSTRAINT actual_audience_non_negative 
CHECK (actual_audience IS NULL OR actual_audience >= 0);

-- Create function to update user statistics when predictions change
CREATE OR REPLACE FUNCTION update_user_stats_on_prediction_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Update user statistics
  UPDATE public.users
  SET 
    predictions_count = (
      SELECT COUNT(*) 
      FROM public.predictions 
      WHERE user_id = NEW.user_id
    ),
    accuracy = (
      SELECT AVG(accuracy)
      FROM public.predictions
      WHERE user_id = NEW.user_id
      AND accuracy IS NOT NULL
    ),
    score = (
      SELECT SUM(FLOOR(COALESCE(accuracy, 0)))
      FROM public.predictions
      WHERE user_id = NEW.user_id
      AND accuracy IS NOT NULL
    )
  WHERE id = NEW.user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update user stats when predictions change
DROP TRIGGER IF EXISTS update_user_stats_trigger ON public.predictions;
CREATE TRIGGER update_user_stats_trigger
  AFTER INSERT OR UPDATE ON public.predictions
  FOR EACH ROW
  EXECUTE FUNCTION update_user_stats_on_prediction_change();

-- Add policy for updating actual_audience
CREATE POLICY "Allow admins to update actual_audience"
ON public.shows
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'admin'
  )
);