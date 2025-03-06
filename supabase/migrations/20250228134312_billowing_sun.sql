/*
  # Add email column to users table

  1. Changes
    - Add email column to users table if it doesn't exist
    - Update user profile retrieval to handle email properly
*/

-- Add email column to users table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public'
    AND table_name = 'users' 
    AND column_name = 'email'
  ) THEN
    ALTER TABLE public.users ADD COLUMN email text;
  END IF;
END $$;

-- Create index on email column
CREATE INDEX IF NOT EXISTS users_email_idx ON public.users(email);
