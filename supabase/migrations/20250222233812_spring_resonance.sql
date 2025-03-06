/*
  # Add update policy for predictions

  1. Changes
    - Add RLS policy to allow users to update their own predictions
  
  2. Security
    - Users can only update their own predictions
    - Enforced by checking user_id matches authenticated user
*/

-- Add policy for updating predictions
CREATE POLICY "Users can update their own predictions"
ON public.predictions
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
