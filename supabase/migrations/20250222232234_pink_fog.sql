/*
  # Add predictions table

  1. New Tables
    - `predictions`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key to auth.users)
      - `show_id` (uuid, foreign key to shows)
      - `prediction` (integer)
      - `created_at` (timestamptz)
      - `actual_audience` (integer, nullable)
      - `accuracy` (float, nullable)

  2. Security
    - Enable RLS on `predictions` table
    - Add policies for authenticated users
*/

CREATE TABLE IF NOT EXISTS public.predictions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  show_id uuid REFERENCES public.shows(id) ON DELETE CASCADE NOT NULL,
  prediction integer NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL,
  actual_audience integer,
  accuracy float,
  CONSTRAINT prediction_positive CHECK (prediction >= 0)
);

-- Enable RLS
ALTER TABLE public.predictions ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own predictions"
ON public.predictions
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own predictions"
ON public.predictions
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Indexes
CREATE INDEX predictions_user_id_idx ON public.predictions(user_id);
CREATE INDEX predictions_show_id_idx ON public.predictions(show_id);
