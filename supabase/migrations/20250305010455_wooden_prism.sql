-- Cette migration ajoute une fonction RPC pour mettre à jour les prédictions avec l'audience réelle
-- et calculer la précision de chaque prédiction

-- Fonction pour mettre à jour les prédictions avec l'audience réelle
CREATE OR REPLACE FUNCTION update_predictions_with_actual_audience(
  p_show_id UUID,
  p_actual_audience NUMERIC
)
RETURNS VOID AS $$
BEGIN
  -- Mettre à jour toutes les prédictions pour ce show avec l'audience réelle
  -- et calculer la précision de chaque prédiction
  UPDATE predictions
  SET 
    actual_audience = p_actual_audience,
    accuracy = CASE 
      WHEN p_actual_audience > 0 THEN
        -- Calculer la précision en pourcentage (0-100)
        -- Plus la différence est petite, plus la précision est élevée
        -- Formule: 100 - (|prédiction - réalité| / réalité) * 100
        -- Limité à 0 minimum (pas de précision négative)
        GREATEST(0, 100 - (ABS(prediction - p_actual_audience) / p_actual_audience) * 100)
      ELSE 0
    END
  WHERE show_id = p_show_id;

  -- Mettre à jour les statistiques des utilisateurs qui ont fait des prédictions pour ce show
  -- Cette partie est optionnelle et peut être étendue selon vos besoins
  WITH user_predictions AS (
    SELECT 
      user_id,
      AVG(accuracy) as avg_accuracy,
      COUNT(*) as predictions_count
    FROM predictions
    WHERE actual_audience IS NOT NULL
    GROUP BY user_id
  )
  UPDATE users u
  SET 
    accuracy = up.avg_accuracy,
    predictions_count = up.predictions_count
  FROM user_predictions up
  WHERE u.id = up.user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Accorder les permissions nécessaires
GRANT EXECUTE ON FUNCTION update_predictions_with_actual_audience(UUID, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION update_predictions_with_actual_audience(UUID, NUMERIC) TO service_role; 