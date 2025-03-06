/*
  # Création de la table shows et configuration de la sécurité

  1. Nouvelle Table
    - `shows`
      - `id` (uuid, clé primaire)
      - `title` (text, non null)
      - `channel` (text, non null)
      - `datetime` (timestamptz, non null)
      - `description` (text, non null)
      - `isNew` (boolean, non null, par défaut true)
      - `genre` (text, non null)
      - `imageUrl` (text, non null)
      - `expectedAudience` (integer)
      - `createdAt` (timestamptz, par défaut now())
      - `updatedAt` (timestamptz, par défaut now())

  2. Sécurité
    - Active RLS sur la table shows
    - Politiques pour permettre :
      - Lecture pour tous les utilisateurs
      - Création/Modification/Suppression pour les administrateurs uniquement

  3. Trigger
    - Mise à jour automatique du champ updatedAt
*/

-- Création de la table shows
CREATE TABLE IF NOT EXISTS public.shows (
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

-- Active Row Level Security
ALTER TABLE public.shows ENABLE ROW LEVEL SECURITY;

-- Fonction pour mettre à jour le champ updatedAt
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW."updatedAt" = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger pour la mise à jour automatique de updatedAt
CREATE TRIGGER update_shows_updated_at
  BEFORE UPDATE ON public.shows
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Politiques de sécurité

-- Lecture pour tous
CREATE POLICY "Shows are viewable by everyone"
ON public.shows
FOR SELECT
USING (true);

-- Création pour les administrateurs
CREATE POLICY "Shows can be created by administrators"
ON public.shows
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'admin'
  )
);

-- Modification pour les administrateurs
CREATE POLICY "Shows can be updated by administrators"
ON public.shows
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'admin'
  )
);

-- Suppression pour les administrateurs
CREATE POLICY "Shows can be deleted by administrators"
ON public.shows
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'admin'
  )
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS shows_datetime_idx ON public.shows (datetime);
CREATE INDEX IF NOT EXISTS shows_channel_idx ON public.shows (channel);
CREATE INDEX IF NOT EXISTS shows_genre_idx ON public.shows (genre);
