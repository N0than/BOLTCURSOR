/*
  # Fix authentication and database structure

  1. Changes
    - Create predictions table with correct structure
    - Add necessary indexes and constraints
    - Update RLS policies
    - Add user statistics functions and triggers

  2. Security
    - Enable RLS
    - Add appropriate policies for predictions
*/

-- Create predictions table if not exists
CREATE TABLE IF NOT EXISTS public.predictions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  show_id uuid REFERENCES public.shows(id) ON DELETE CASCADE NOT NULL,
  prediction integer NOT NULL,
  actual_audience integer,
  accuracy float,
  created_at timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT prediction_positive CHECK (prediction >= 0),
  CONSTRAINT unique_user_show_prediction UNIQUE (user_id, show_id)
);

-- Enable RLS
ALTER TABLE public.predictions ENABLE ROW LEVEL SECURITY;

-- Create or replace prediction policies
DROP POLICY IF EXISTS "Users can view their own predictions" ON public.predictions;
DROP POLICY IF EXISTS "Users can create their own predictions" ON public.predictions;
DROP POLICY IF EXISTS "Users can update their own predictions" ON public.predictions;

CREATE POLICY "Users can view their own predictions"
ON public.predictions FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own predictions"
ON public.predictions FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own predictions"
ON public.predictions FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Create or replace function to update user statistics
CREATE OR REPLACE FUNCTION update_user_statistics()
RETURNS TRIGGER AS $$
BEGIN
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
      SELECT SUM(FLOOR(accuracy))
      FROM public.predictions
      WHERE user_id = NEW.user_id
      AND accuracy IS NOT NULL
    )
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

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS predictions_user_id_idx ON public.predictions(user_id);
CREATE INDEX IF NOT EXISTS predictions_show_id_idx ON public.predictions(show_id);
CREATE INDEX IF NOT EXISTS users_username_idx ON public.users(username);
CREATE INDEX IF NOT EXISTS users_score_idx ON public.users(score DESC);
CREATE INDEX IF NOT EXISTS users_accuracy_idx ON public.users(accuracy DESC);
CREATE INDEX IF NOT EXISTS users_predictions_count_idx ON public.users(predictions_count DESC);
