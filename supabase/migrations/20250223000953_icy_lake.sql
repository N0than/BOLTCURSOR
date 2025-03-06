/*
  # Add users table and statistics

  1. New Tables
    - `users`
      - `id` (uuid, primary key) - References auth.users
      - `username` (text, unique)
      - `avatar` (text)
      - `score` (integer)
      - `accuracy` (float)
      - `predictions_count` (integer)
      - `is_online` (boolean)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `users` table
    - Add policies for viewing and updating user data
*/

-- Create users table
CREATE TABLE IF NOT EXISTS public.users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username text UNIQUE NOT NULL,
  avatar text,
  score integer DEFAULT 0,
  accuracy float DEFAULT 0,
  predictions_count integer DEFAULT 0,
  is_online boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_users_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_users_updated_at();

-- Create function to update user statistics
CREATE OR REPLACE FUNCTION update_user_statistics()
RETURNS TRIGGER AS $$
BEGIN
  -- Update user statistics when a prediction is created/updated
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
$$ language 'plpgsql';

-- Create trigger for updating user statistics
CREATE TRIGGER update_user_stats_on_prediction
  AFTER INSERT OR UPDATE ON public.predictions
  FOR EACH ROW
  EXECUTE FUNCTION update_user_statistics();

-- Policies
CREATE POLICY "Users are viewable by everyone"
ON public.users
FOR SELECT
USING (true);

CREATE POLICY "Users can update their own data"
ON public.users
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Indexes
CREATE INDEX users_username_idx ON public.users(username);
CREATE INDEX users_score_idx ON public.users(score DESC);
CREATE INDEX users_accuracy_idx ON public.users(accuracy DESC);
CREATE INDEX users_predictions_count_idx ON public.users(predictions_count DESC);
