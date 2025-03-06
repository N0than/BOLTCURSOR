/*
  # Update user policies and indexes

  1. Changes
    - Drop existing policies
    - Create new policies with unique names
    - Add necessary indexes for performance

  2. Security
    - Enable RLS
    - Add policies for read/write access
*/

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Enable public profile viewing" ON public.users;
DROP POLICY IF EXISTS "Enable user profile updates" ON public.users;
DROP POLICY IF EXISTS "Enable user profile creation" ON public.users;

-- Create users table if not exists
CREATE TABLE IF NOT EXISTS public.users (
  id uuid PRIMARY KEY,
  username text UNIQUE NOT NULL,
  email text,
  avatar text,
  score integer DEFAULT 0,
  accuracy float DEFAULT 0,
  predictions_count integer DEFAULT 0,
  is_online boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT username_length CHECK (char_length(username) >= 3)
);

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Create RLS policies with new unique names
CREATE POLICY "Allow profile viewing"
ON public.users FOR SELECT
USING (true);

CREATE POLICY "Allow profile updates"
ON public.users FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "Allow profile creation"
ON public.users FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Create indexes
CREATE INDEX IF NOT EXISTS users_username_idx ON public.users(username);
CREATE INDEX IF NOT EXISTS users_score_idx ON public.users(score DESC);
CREATE INDEX IF NOT EXISTS users_accuracy_idx ON public.users(accuracy DESC);
CREATE INDEX IF NOT EXISTS users_predictions_count_idx ON public.users(predictions_count DESC);
