/*
  # Add audience validation function

  1. Changes
    - Add function to validate and convert actual audience values
    - Add trigger to ensure actual_audience is always a valid number or null
    
  2. Security
    - Function is security definer to ensure consistent behavior
*/

-- Create a function to validate actual audience
CREATE OR REPLACE FUNCTION public.validate_actual_audience()
RETURNS TRIGGER AS $$
BEGIN
  -- Convert empty string to null
  IF NEW.actual_audience = 0 OR NEW.actual_audience IS NULL THEN
    NEW.actual_audience := NULL;
  END IF;

  -- Ensure actual_audience is positive when set
  IF NEW.actual_audience IS NOT NULL AND NEW.actual_audience < 0 THEN
    RAISE EXCEPTION 'L''audience réelle doit être un nombre positif';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to validate actual audience
DROP TRIGGER IF EXISTS validate_actual_audience_trigger ON public.shows;
CREATE TRIGGER validate_actual_audience_trigger
  BEFORE INSERT OR UPDATE ON public.shows
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_actual_audience();