/*
  # Complete Database Reset and Setup

  1. Tables
    - shows: TV show information with audience tracking
    - users: User profiles with statistics
    - predictions: User predictions for shows
  
  2. Functions
    - Admin role check
    - User profile management
    - Prediction validation and management
    - Statistics calculation
  
  3. Policies
    - Shows: Public read, admin write
    - Users: Public read, self-manage
    - Predictions: Self-manage with locking
*/

-- Drop existing tables if they exist
DROP TABLE IF EXISTS public.predictions CASCADE;
DROP TABLE IF EXISTS public.shows CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- Create shows table
CREATE TABLE public.shows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  channel text NOT NULL,
  datetime timestamptz NOT NULL,
  description text NOT NULL,
  "isNew" boolean NOT NULL DEFAULT true,
  genre text NOT NULL,
  "imageUrl" text NOT NULL,
  actual_audience integer,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT actual_audience_non_negative CHECK (actual_audience IS NULL OR actual_audience >= 0),
  CONSTRAINT title_not_empty CHECK (char_length(title) > 0),
  CONSTRAINT channel_not_empty CHECK (char_length(channel) > 0),
  CONSTRAINT description_not_empty CHECK (char_length(description) > 0),
  CONSTRAINT genre_not_empty CHECK (char_length(genre) > 0),
  CONSTRAINT image_url_not_empty CHECK (char_length("imageUrl") > 0)
);

-- Create users table
CREATE TABLE public.users (
  id uuid PRIMARY KEY,
  username text UNIQUE NOT NULL,
  email text,
  avatar text,
  score integer DEFAULT 0,
  accuracy float DEFAULT 0,
  predictions_count integer DEFAULT 0,
  is_online boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT username_length CHECK (char_length(username) >= 1)
);

-- Create predictions table
CREATE TABLE public.predictions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  show_id uuid REFERENCES public.shows(id) ON DELETE CASCADE NOT NULL,
  prediction integer NOT NULL,
  actual_audience integer,
  accuracy float,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT prediction_positive CHECK (prediction >= 0),
  CONSTRAINT unique_user_show_prediction UNIQUE (user_id, show_id)
);

-- Enable RLS
ALTER TABLE public.shows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.predictions ENABLE ROW LEVEL SECURITY;

-- Create admin check function
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to ensure user profile exists
CREATE OR REPLACE FUNCTION ensure_user_profile()
RETURNS TRIGGER AS $$
DECLARE
  v_username text;
BEGIN
  -- Get username from metadata or email
  v_username := NEW.raw_user_meta_data->>'username';
  IF v_username IS NULL OR v_username = '' THEN
    v_username := split_part(NEW.email, '@', 1);
  END IF;

  -- Create user profile if it doesn't exist
  INSERT INTO public.users (
    id,
    username,
    email,
    avatar,
    score,
    accuracy,
    predictions_count,
    is_online
  ) VALUES (
    NEW.id,
    v_username,
    NEW.email,
    'https://api.dicebear.com/7.x/initials/svg?seed=' || v_username,
    0,
    0,
    0,
    true
  ) ON CONFLICT (id) DO UPDATE
  SET 
    email = NEW.email,
    updated_at = now();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to ensure user profile exists
DROP TRIGGER IF EXISTS ensure_user_profile_trigger ON auth.users;
CREATE TRIGGER ensure_user_profile_trigger
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION ensure_user_profile();

-- Create function to check if show is locked
CREATE OR REPLACE FUNCTION is_show_locked(p_show_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.shows
    WHERE id = p_show_id
    AND actual_audience IS NOT NULL
  );
END;
$$ LANGUAGE plpgsql;

-- Create function to validate prediction
CREATE OR REPLACE FUNCTION validate_prediction(
  p_show_id uuid,
  p_prediction integer
)
RETURNS boolean AS $$
BEGIN
  -- Check if prediction is positive
  IF p_prediction <= 0 THEN
    RAISE EXCEPTION 'La prédiction doit être un nombre positif';
  END IF;

  -- Check if show exists
  IF NOT EXISTS (SELECT 1 FROM public.shows WHERE id = p_show_id) THEN
    RAISE EXCEPTION 'Programme non trouvé';
  END IF;

  -- Check if show is locked
  IF public.is_show_locked(p_show_id) THEN
    RAISE EXCEPTION 'Ce programme est verrouillé, vous ne pouvez plus modifier votre pronostic';
  END IF;

  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Create function to create or update prediction
CREATE OR REPLACE FUNCTION create_or_update_prediction(
  p_show_id uuid,
  p_prediction integer
)
RETURNS json AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_prediction_id uuid;
  v_result json;
BEGIN
  -- Check if user is authenticated
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Vous devez être connecté pour faire une prédiction';
  END IF;

  -- Ensure user profile exists
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = v_user_id) THEN
    INSERT INTO public.users (
      id,
      username,
      email,
      avatar,
      score,
      accuracy,
      predictions_count,
      is_online
    )
    SELECT
      v_user_id,
      split_part(auth.email(), '@', 1),
      auth.email(),
      'https://api.dicebear.com/7.x/initials/svg?seed=' || split_part(auth.email(), '@', 1),
      0,
      0,
      0,
      true;
  END IF;

  -- Validate prediction
  PERFORM validate_prediction(p_show_id, p_prediction);

  -- Check if prediction already exists
  SELECT id INTO v_prediction_id
  FROM public.predictions
  WHERE user_id = v_user_id AND show_id = p_show_id;

  IF v_prediction_id IS NOT NULL THEN
    -- Update existing prediction
    UPDATE public.predictions
    SET 
      prediction = p_prediction,
      updated_at = now()
    WHERE id = v_prediction_id
    RETURNING to_json(predictions.*) INTO v_result;
  ELSE
    -- Create new prediction
    INSERT INTO public.predictions (
      user_id,
      show_id,
      prediction
    )
    VALUES (
      v_user_id,
      p_show_id,
      p_prediction
    )
    RETURNING to_json(predictions.*) INTO v_result;
  END IF;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to calculate prediction accuracy
CREATE OR REPLACE FUNCTION calculate_prediction_accuracy(prediction integer, actual integer)
RETURNS float AS $$
BEGIN
  IF actual IS NULL OR prediction IS NULL OR actual = 0 THEN
    RETURN NULL;
  END IF;
  
  RETURN GREATEST(0, 100 - ABS((prediction::float - actual::float) / actual::float * 100));
END;
$$ LANGUAGE plpgsql;

-- Create function to update predictions accuracy
CREATE OR REPLACE FUNCTION update_predictions_accuracy()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.actual_audience IS DISTINCT FROM OLD.actual_audience THEN
    UPDATE public.predictions
    SET 
      actual_audience = NEW.actual_audience,
      accuracy = calculate_prediction_accuracy(prediction, NEW.actual_audience)
    WHERE show_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for predictions accuracy
CREATE TRIGGER update_predictions_accuracy_trigger
  AFTER UPDATE OF actual_audience ON public.shows
  FOR EACH ROW
  EXECUTE FUNCTION update_predictions_accuracy();

-- Create function to update user statistics
CREATE OR REPLACE FUNCTION update_user_statistics()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.users
  SET 
    predictions_count = COALESCE((
      SELECT COUNT(*) 
      FROM public.predictions 
      WHERE user_id = NEW.user_id
    ), 0),
    accuracy = COALESCE((
      SELECT AVG(accuracy)
      FROM public.predictions
      WHERE user_id = NEW.user_id
      AND accuracy IS NOT NULL
    ), 0),
    score = COALESCE((
      SELECT SUM(FLOOR(COALESCE(accuracy, 0)))
      FROM public.predictions
      WHERE user_id = NEW.user_id
      AND accuracy IS NOT NULL
    ), 0)
  WHERE id = NEW.user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for user statistics
CREATE TRIGGER update_user_stats_trigger
  AFTER INSERT OR UPDATE ON public.predictions
  FOR EACH ROW
  EXECUTE FUNCTION update_user_statistics();

-- Create RLS policies for shows
CREATE POLICY "Shows viewable by everyone"
ON public.shows FOR SELECT
USING (true);

CREATE POLICY "Shows manageable by admins"
ON public.shows
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Create RLS policies for users
CREATE POLICY "Users viewable by everyone"
ON public.users FOR SELECT
USING (true);

CREATE POLICY "Users can manage their own profile"
ON public.users
FOR ALL
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Create RLS policies for predictions
CREATE POLICY "Users can view their own predictions"
ON public.predictions FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own predictions"
ON public.predictions FOR INSERT
WITH CHECK (
  auth.uid() = user_id AND
  NOT public.is_show_locked(show_id)
);

CREATE POLICY "Users can update their own predictions"
ON public.predictions FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (
  auth.uid() = user_id AND
  NOT public.is_show_locked(show_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS shows_datetime_idx ON public.shows(datetime);
CREATE INDEX IF NOT EXISTS shows_channel_idx ON public.shows(channel);
CREATE INDEX IF NOT EXISTS shows_genre_idx ON public.shows(genre);
CREATE INDEX IF NOT EXISTS shows_actual_audience_idx ON public.shows(actual_audience);

CREATE INDEX IF NOT EXISTS users_username_idx ON public.users(username);
CREATE INDEX IF NOT EXISTS users_email_idx ON public.users(email);
CREATE INDEX IF NOT EXISTS users_score_idx ON public.users(score DESC);
CREATE INDEX IF NOT EXISTS users_accuracy_idx ON public.users(accuracy DESC);
CREATE INDEX IF NOT EXISTS users_predictions_count_idx ON public.users(predictions_count DESC);

CREATE INDEX IF NOT EXISTS predictions_user_id_idx ON public.predictions(user_id);
CREATE INDEX IF NOT EXISTS predictions_show_id_idx ON public.predictions(show_id);
CREATE INDEX IF NOT EXISTS predictions_created_at_idx ON public.predictions(created_at);
CREATE INDEX IF NOT EXISTS predictions_updated_at_idx ON public.predictions(updated_at);

-- Grant necessary permissions
GRANT ALL ON public.shows TO authenticated;
GRANT ALL ON public.users TO authenticated;
GRANT ALL ON public.predictions TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_show_locked TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_prediction TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_or_update_prediction TO authenticated;