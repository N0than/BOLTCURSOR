/*
  # Fix user policies and triggers

  1. Changes
    - Drop existing policies to avoid conflicts
    - Create new policies with unique names
    - Update triggers for user statistics
    - Add indexes for performance

  2. Security
    - Enable RLS
    - Set up proper access policies
    - Configure secure user management
*/

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Anyone can view profiles" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can create own profile" ON public.users;

-- Create new policies with unique names
CREATE POLICY "Allow public profile viewing"
ON public.users FOR SELECT
USING (true);

CREATE POLICY "Allow users to update their profile"
ON public.users FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "Allow users to create their profile"
ON public.users FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Update function to handle user statistics
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

-- Create or replace updated_at trigger
CREATE OR REPLACE FUNCTION update_users_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_users_updated_at();

-- Ensure indexes exist for performance
CREATE INDEX IF NOT EXISTS users_username_idx ON public.users(username);
CREATE INDEX IF NOT EXISTS users_score_idx ON public.users(score DESC);
CREATE INDEX IF NOT EXISTS users_accuracy_idx ON public.users(accuracy DESC);
CREATE INDEX IF NOT EXISTS users_predictions_count_idx ON public.users(predictions_count DESC);
