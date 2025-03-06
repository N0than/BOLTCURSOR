/*
  # Update user policies and triggers

  1. Changes
    - Drop existing policies
    - Create new policies with unique names
    - Update triggers for user statistics
    - Add indexes for performance

  2. Security
    - Enable RLS
    - Add policies for read/write access
*/

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users are viewable by everyone" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can create their own profile" ON public.users;

-- Create new policies with unique names
CREATE POLICY "Enable public profile viewing"
ON public.users FOR SELECT
USING (true);

CREATE POLICY "Enable user profile updates"
ON public.users FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "Enable user profile creation"
ON public.users FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Create updated_at trigger if not exists
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

-- Create indexes if not exists
CREATE INDEX IF NOT EXISTS users_username_idx ON public.users(username);
CREATE INDEX IF NOT EXISTS users_score_idx ON public.users(score DESC);
CREATE INDEX IF NOT EXISTS users_accuracy_idx ON public.users(accuracy DESC);
CREATE INDEX IF NOT EXISTS users_predictions_count_idx ON public.users(predictions_count DESC);
