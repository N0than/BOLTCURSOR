-- Create a table to track email update attempts
CREATE TABLE IF NOT EXISTS public.email_update_attempts (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id),
  last_attempt timestamptz NOT NULL DEFAULT now(),
  attempts_count integer NOT NULL DEFAULT 1
);

-- Enable RLS
ALTER TABLE public.email_update_attempts ENABLE ROW LEVEL SECURITY;

-- Create policies for email_update_attempts
CREATE POLICY "Users can view their own attempts"
ON public.email_update_attempts FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own attempts"
ON public.email_update_attempts FOR ALL
USING (auth.uid() = user_id);

-- Create function to check rate limit
CREATE OR REPLACE FUNCTION public.check_email_update_rate_limit(p_user_id uuid)
RETURNS boolean AS $$
DECLARE
  v_last_attempt timestamptz;
  v_attempts_count integer;
  v_cooldown_period interval := interval '60 seconds';
BEGIN
  -- Get the last attempt info
  SELECT last_attempt, attempts_count 
  INTO v_last_attempt, v_attempts_count
  FROM public.email_update_attempts
  WHERE user_id = p_user_id;
  
  -- If no previous attempts, allow it
  IF v_last_attempt IS NULL THEN
    INSERT INTO public.email_update_attempts (user_id)
    VALUES (p_user_id);
    RETURN true;
  END IF;
  
  -- Check if enough time has passed
  IF now() - v_last_attempt < v_cooldown_period THEN
    RETURN false;
  END IF;
  
  -- Update the attempt count and timestamp
  UPDATE public.email_update_attempts
  SET 
    last_attempt = now(),
    attempts_count = attempts_count + 1
  WHERE user_id = p_user_id;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.check_email_update_rate_limit TO authenticated;