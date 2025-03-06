/*
  # Fix permissions and create user predictions function
  
  1. Changes
    - Drop existing function to avoid parameter name conflicts
    - Create a new function with a unique parameter name
    - Fix RLS policies for predictions and users tables
*/

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.get_user_predictions(uuid);

-- Create a new function with a different parameter name to avoid conflicts
CREATE FUNCTION public.get_user_predictions(p_user_id uuid)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  show_id uuid,
  prediction integer,
  actual_audience integer,
  accuracy float,
  created_at timestamptz,
  show_title text,
  show_channel text,
  show_datetime timestamptz,
  show_description text,
  show_genre text,
  show_image_url text
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.user_id,
    p.show_id,
    p.prediction,
    p.actual_audience,
    p.accuracy,
    p.created_at,
    s.title,
    s.channel,
    s.datetime,
    s.description,
    s.genre,
    s."imageUrl"
  FROM 
    public.predictions p
  JOIN 
    public.shows s ON p.show_id = s.id
  WHERE 
    p.user_id = p_user_id
  ORDER BY 
    p.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.get_user_predictions TO authenticated;

-- Drop existing policies to avoid conflicts
DO $$ 
BEGIN
  BEGIN
    DROP POLICY IF EXISTS "Users can view their own predictions" ON public.predictions;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
  
  BEGIN
    DROP POLICY IF EXISTS "Admins can view all predictions" ON public.predictions;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
END $$;

-- Create more permissive policies for predictions
CREATE POLICY "Users can view their own predictions"
ON public.predictions
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all predictions"
ON public.predictions
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'admin'
  )
);

-- Make sure RLS is enabled on the users table
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DO $$ 
BEGIN
  BEGIN
    DROP POLICY IF EXISTS "Anyone can view users" ON public.users;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
  
  BEGIN
    DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
  
  BEGIN
    DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
  EXCEPTION
    WHEN undefined_object THEN NULL;
  END;
END $$;

-- Create new policies with clear names
CREATE POLICY "Anyone can view users"
ON public.users
FOR SELECT
USING (true);

CREATE POLICY "Users can update their own profile"
ON public.users
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
ON public.users
FOR INSERT
WITH CHECK (auth.uid() = id);
