/*
  # Create shows table with proper RLS policies

  1. New Tables
    - `shows` table with all necessary columns and constraints
      - `id` (uuid, primary key)
      - `title` (text, not null)
      - `channel` (text, not null)
      - `datetime` (timestamptz, not null)
      - `description` (text, not null)
      - `isNew` (boolean, not null, default true)
      - `genre` (text, not null)
      - `imageUrl` (text, not null)
      - `expectedAudience` (integer)
      - `createdAt` (timestamptz, not null, default now())
      - `updatedAt` (timestamptz, not null, default now())

  2. Security
    - Enable RLS
    - Create policies for authenticated users
    - Add indexes for performance
*/

-- Drop existing table and policies if they exist
DROP TABLE IF EXISTS public.shows CASCADE;

-- Create the shows table
CREATE TABLE public.shows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  channel text NOT NULL,
  datetime timestamptz NOT NULL,
  description text NOT NULL,
  "isNew" boolean NOT NULL DEFAULT true,
  genre text NOT NULL,
  "imageUrl" text NOT NULL,
  "expectedAudience" integer,
  "createdAt" timestamptz NOT NULL DEFAULT now(),
  "updatedAt" timestamptz NOT NULL DEFAULT now(),
  CHECK (char_length(title) > 0),
  CHECK (char_length(channel) > 0),
  CHECK (char_length(description) > 0),
  CHECK (char_length(genre) > 0),
  CHECK (char_length("imageUrl") > 0)
);

-- Enable RLS
ALTER TABLE public.shows ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW."updatedAt" = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for automatic updatedAt
CREATE TRIGGER update_shows_updated_at
  BEFORE UPDATE ON public.shows
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create RLS policies
CREATE POLICY "Shows are viewable by everyone"
ON public.shows
FOR SELECT
USING (true);

CREATE POLICY "Shows can be created by authenticated users"
ON public.shows
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Shows can be updated by authenticated users"
ON public.shows
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Shows can be deleted by authenticated users"
ON public.shows
FOR DELETE
TO authenticated
USING (true);

-- Create indexes
CREATE INDEX shows_datetime_idx ON public.shows (datetime);
CREATE INDEX shows_channel_idx ON public.shows (channel);
CREATE INDEX shows_genre_idx ON public.shows (genre);
