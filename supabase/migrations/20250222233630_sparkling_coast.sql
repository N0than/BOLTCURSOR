/*
  # Add unique constraint to predictions table

  1. Changes
    - Add unique constraint on user_id and show_id to ensure only one prediction per user per show
    - Clean up duplicate predictions by keeping only the most recent one
  
  2. Security
    - No changes to RLS policies
*/

-- First, remove duplicates keeping only the most recent prediction for each user/show pair
DELETE FROM public.predictions a
WHERE a.id NOT IN (
  SELECT DISTINCT ON (user_id, show_id) id
  FROM public.predictions
  ORDER BY user_id, show_id, created_at DESC
);

-- Then add the unique constraint
ALTER TABLE public.predictions
ADD CONSTRAINT unique_user_show_prediction UNIQUE (user_id, show_id);
