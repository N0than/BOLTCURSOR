/*
  # Fix user statistics consistency

  1. New Functions
    - `sync_user_stats` - Updates user statistics in the users table
    - `update_all_users_stats` - Updates statistics for all users
  
  2. Triggers
    - Add trigger to automatically update user stats when predictions change
*/

-- Create a function to sync user statistics to the users table
CREATE OR REPLACE FUNCTION public.sync_user_stats(p_user_id uuid)
RETURNS void AS $$
DECLARE
  v_stats json;
BEGIN
  -- Get the calculated statistics
  SELECT public.calculate_user_stats(p_user_id) INTO v_stats;
  
  -- Update the user record with the calculated statistics
  UPDATE public.users
  SET 
    score = (v_stats->>'score')::integer,
    accuracy = (v_stats->>'accuracy')::float,
    predictions_count = (v_stats->>'predictions_count')::integer,
    updated_at = now()
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.sync_user_stats TO authenticated;

-- Create a function to update all users' statistics
CREATE OR REPLACE FUNCTION public.update_all_users_stats()
RETURNS void AS $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT id FROM public.users
  LOOP
    PERFORM public.sync_user_stats(r.id);
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.update_all_users_stats TO authenticated;

-- Create a trigger function to automatically update user stats when predictions change
CREATE OR REPLACE FUNCTION public.trigger_sync_user_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- For inserts and updates, sync the user's stats
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    PERFORM public.sync_user_stats(NEW.user_id);
  -- For deletes, sync the user's stats
  ELSIF TG_OP = 'DELETE' THEN
    PERFORM public.sync_user_stats(OLD.user_id);
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger on the predictions table
DROP TRIGGER IF EXISTS sync_user_stats_trigger ON public.predictions;
CREATE TRIGGER sync_user_stats_trigger
  AFTER INSERT OR UPDATE OR DELETE ON public.predictions
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_sync_user_stats();

-- Update all users' statistics to ensure consistency
SELECT public.update_all_users_stats();
