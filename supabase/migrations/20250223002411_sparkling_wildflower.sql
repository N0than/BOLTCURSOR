/*
  # Update admin password

  1. Changes
    - Update admin user password to 'admin2025'

  2. Security
    - Use pgcrypto for password hashing
    - Maintain existing admin role
*/

-- Update admin password
UPDATE auth.users
SET encrypted_password = crypt('admin2025', gen_salt('bf'))
WHERE email = 'admin@audiencemasters.com';
