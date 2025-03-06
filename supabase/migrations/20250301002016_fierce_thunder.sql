/*
  # Fix user statistics and admin functions

  1. New Functions
    - Create a secure function to update user statistics
    - Create a secure function for admins to execute SQL

  2. Security
    - Functions are marked as SECURITY DEFINER to run with elevated privileges
    - Admin function checks user role before executing SQL
*/

-- Drop existing function if it exists to avoid conflicts
DROP FUNCTION IF EXISTS public.update_user_statistics(uuid, integer, float, integer);

-- Create a function with a different name to update user statistics
CREATE OR REPLACE FUNCTION public.update_user_stats(
  p_user_id uuid,
  p_score integer,
  p_accuracy float,
  p_predictions_count integer
)
RETURNS json AS $$
DECLARE
  v_result json;
BEGIN
  -- Check if the user is updating their own statistics
  IF auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'You can only update your own statistics';
  END IF;

  -- Update the user's statistics
  UPDATE public.users
  SET 
    score = p_score,
    accuracy = p_accuracy,
    predictions_count = p_predictions_count,
    updated_at = now()
  WHERE id = p_user_id
  RETURNING to_json(users.*) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.update_user_stats TO authenticated;

-- Check if exec_sql function already exists and create it if not
DO $$
DECLARE
  func_exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'exec_sql' 
    AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  ) INTO func_exists;
  
  IF NOT func_exists THEN
    -- Create a function to execute arbitrary SQL (for admin use only)
    EXECUTE 'CREATE OR REPLACE FUNCTION public.exec_sql(sql text)
    RETURNS void AS $func$
    BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM auth.users
        WHERE auth.users.id = auth.uid()
        AND auth.users.role = ''admin''
      ) THEN
        RAISE EXCEPTION ''Only admins can execute arbitrary SQL'';
      END IF;

      EXECUTE sql;
    END;
    $func$ LANGUAGE plpgsql SECURITY DEFINER;';

    -- Grant execute permission on the function to authenticated users
    EXECUTE 'GRANT EXECUTE ON FUNCTION public.exec_sql TO authenticated;';
  END IF;
END $$;
