/*
  # Add exec_sql function for migrations

  1. New Functions
    - `exec_sql`: Allows admins to execute SQL statements
      - Requires admin role
      - Security definer for proper permissions

  2. Security
    - Function is only accessible to authenticated users
    - Checks for admin role before executing
*/

-- Create a function to execute SQL (for admin use only)
CREATE OR REPLACE FUNCTION public.exec_sql(sql text)
RETURNS void AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admins can execute arbitrary SQL';
  END IF;

  EXECUTE sql;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.exec_sql TO authenticated;