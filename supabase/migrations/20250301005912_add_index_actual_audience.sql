-- Add index on actual_audience column
CREATE INDEX IF NOT EXISTS shows_actual_audience_idx ON public.shows (actual_audience);
