/*
  # Mise à jour des politiques de sécurité pour la table shows

  1. Modifications
    - Suppression des anciennes politiques
    - Création de nouvelles politiques permettant l'accès aux utilisateurs authentifiés
    
  2. Sécurité
    - Lecture pour tous
    - Création/Modification/Suppression pour les utilisateurs authentifiés
*/

-- Suppression des anciennes politiques
DROP POLICY IF EXISTS "Shows are viewable by everyone" ON public.shows;
DROP POLICY IF EXISTS "Shows can be created by administrators" ON public.shows;
DROP POLICY IF EXISTS "Shows can be updated by administrators" ON public.shows;
DROP POLICY IF EXISTS "Shows can be deleted by administrators" ON public.shows;

-- Nouvelles politiques

-- Lecture pour tous
CREATE POLICY "Shows are viewable by everyone"
ON public.shows
FOR SELECT
USING (true);

-- Création pour les utilisateurs authentifiés
CREATE POLICY "Shows can be created by authenticated users"
ON public.shows
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Modification pour les utilisateurs authentifiés
CREATE POLICY "Shows can be updated by authenticated users"
ON public.shows
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Suppression pour les utilisateurs authentifiés
CREATE POLICY "Shows can be deleted by authenticated users"
ON public.shows
FOR DELETE
TO authenticated
USING (true);
