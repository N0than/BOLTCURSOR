/*
  # Add admin access to predictions and ensure constraints
  
  1. Changes
    - Create policy for admins to view all predictions
    - Ensure unique constraint exists for user_id and show_id in predictions table
*/

-- Drop the policy if it exists to avoid errors
DO $$ 
BEGIN
  BEGIN
    DROP POLICY IF EXISTS "Admins can view all predictions" ON public.predictions;
  EXCEPTION
    WHEN undefined_object THEN
      NULL;
  END;
END $$;

-- Create policy for admins to view all predictions
CREATE POLICY "Admins can view all predictions"
ON public.predictions
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'admin'
  )
);

-- Ensure the unique constraint exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'unique_user_show_prediction'
  ) THEN
    ALTER TABLE public.predictions
    ADD CONSTRAINT unique_user_show_prediction UNIQUE (user_id, show_id);
  END IF;
END $$;
