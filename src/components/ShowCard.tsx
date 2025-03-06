import React, { useState, useEffect } from 'react';
import type { Show, Prediction } from '../types';
import { AnimatePresence, motion } from 'framer-motion';
import Slider from 'rc-slider';
import 'rc-slider/assets/index.css';
import toast from 'react-hot-toast';
import { createPrediction, getUserPredictionForShow } from '../lib/supabase';

interface ShowCardProps {
  show: Show;
  theme: 'dark' | 'light';
}

export function ShowCard({ show, theme }: ShowCardProps) {
  const [prediction, setPrediction] = useState(0);
  const [isPredicted, setIsPredicted] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [currentPrediction, setCurrentPrediction] = useState(null);
  const [isLocked, setIsLocked] = useState(false);

  useEffect(() => {
    loadCurrentPrediction();
    // Check if the show has an actual audience (locked)
    if (show.actual_audience) {
      setIsLocked(true);
    }
  }, [show.id, show.actual_audience]);

  const loadCurrentPrediction = async () => {
    try {
      const predictionData = await getUserPredictionForShow(show.id);
      if (predictionData) {
        setCurrentPrediction(predictionData);
        setPrediction(predictionData.prediction);
        setIsPredicted(true);
      }
    } catch (error) {
      console.error('Error loading prediction:', error);
      // Don't show error toast here as it's expected that new users won't have predictions
    }
  };

  const handlePredictionChange = (value) => {
    if (typeof value === 'number') {
      setPrediction(value * 250000);
    }
  };

  const handleValidatePrediction = async () => {
    if (isLocked) {
      toast.error('Ce programme est verrouillé, vous ne pouvez plus modifier votre pronostic', {
        icon: '🔒',
        style: {
          background: '#EF4444',
          color: '#FFFFFF'
        }
      });
      return;
    }
    
    if (prediction <= 0) {
      toast.error('Veuillez sélectionner une audience valide', {
        icon: '❌',
        style: {
          background: '#EF4444',
          color: '#FFFFFF'
        }
      });
      return;
    }
    
    try {
      setIsLoading(true);
      const newPrediction = await createPrediction(show.id, prediction);
      setCurrentPrediction(newPrediction);
      setIsPredicted(true);
      toast.success('Pronostic enregistré avec succès !', {
        icon: '✓',
        style: {
          background: '#10B981',
          color: '#FFFFFF'
        }
      });
    } catch (error) {
      toast.error('Erreur lors de l\'enregistrement du pronostic', {
        icon: '❌',
        style: {
          background: '#EF4444',
          color: '#FFFFFF'
        }
      });
      console.error('Error:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleModifyPrediction = () => {
    if (isLocked) {
      toast.error('Ce programme est verrouillé, vous ne pouvez plus modifier votre pronostic', {
        icon: '🔒',
        style: {
          background: '#EF4444',
          color: '#FFFFFF'
        }
      });
      return;
    }
    setIsPredicted(false);
  };

  const cardBgColor = theme === 'dark' ? 'bg-gray-800' : 'bg-white';
  const textColor = theme === 'dark' ? 'text-white' : 'text-gray-900';
  const sliderTrackColor = theme === 'dark' ? '#4B5563' : '#E5E7EB';
  const sliderHandleColor = theme === 'dark' ? '#8B5CF6' : '#6D28D9';

  const formatDate = (date) => {
    return date.toLocaleDateString('fr-FR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  const getAccuracyColor = (accuracy) => {
    if (!accuracy) return 'text-gray-400';
    if (accuracy >= 95) return 'text-green-400';
    if (accuracy >= 80) return 'text-yellow-400';
    return 'text-orange-400';
  };

  // Afficher l'audience réelle avec une mise en évidence
  const renderActualAudience = () => {
    if (!show.actual_audience) return null;
    
    return (
      <div className="mt-4 p-3 bg-purple-900 bg-opacity-30 rounded-lg">
        <div className="flex items-center justify-between">
          <span className="text-sm font-medium text-purple-300">Audience réelle</span>
          <span className="text-lg font-bold text-white">{(show.actual_audience / 1000000).toFixed(2)}M</span>
        </div>
      </div>
    );
  };

  return (
    <div className={`${cardBgColor} rounded-xl overflow-hidden shadow-lg transition-all duration-200 flex flex-col h-full`}>
      <img
        src={show.imageUrl}
        alt={show.title}
        className="w-full h-48 object-cover"
      />
      <div className="p-6 flex flex-col flex-grow">
        <div className="flex items-center justify-between mb-4">
          <span className="text-sm font-medium text-purple-500">{show.channel}</span>
          <div className="flex items-center text-gray-400 text-sm">
            <span>
              Le {formatDate(new Date(show.datetime))} à{' '}
              {new Date(show.datetime).toLocaleTimeString('fr-FR', {
                hour: '2-digit',
                minute: '2-digit'
              })}
            </span>
          </div>
        </div>
        <h3 className={`text-lg font-semibold ${textColor} mb-3`}>{show.title}</h3>
        <p className="text-sm text-gray-400">{show.description}</p>
        
        {/* Afficher l'audience réelle en haut, avant les prédictions */}
        {renderActualAudience()}

        <div className="mt-auto pt-6 space-y-6">
          <div>
            <div className="flex justify-between mb-2">
              <span className={`text-sm font-medium ${textColor}`}>Audience prédite</span>
              <span className="text-sm text-purple-500 font-medium">
                {(prediction / 1000000).toFixed(2)}M
              </span>
            </div>
            
            <div className="px-2">
              <Slider
                min={0}
                max={40}
                step={0.1}
                value={prediction / 250000}
                onChange={handlePredictionChange}
                disabled={isLoading || isPredicted || isLocked}
                railStyle={{ backgroundColor: sliderTrackColor }}
                trackStyle={{ backgroundColor: sliderHandleColor }}
                handleStyle={{
                  borderColor: sliderHandleColor,
                  backgroundColor: sliderHandleColor
                }}
              />
              
              <div className="flex justify-between mt-2 text-xs text-gray-400">
                <span>0M</span>
                <span>2.5M</span>
                <span>5M</span>
                <span>7.5M</span>
                <span>10M</span>
              </div>
            </div>
          </div>

          {isLocked && currentPrediction ? (
            <div className="w-full py-3 bg-gray-600 text-white rounded-lg font-medium text-center">
              {show.actual_audience ? (
                <div className="flex flex-col items-center">
                  <span>Résultat: {(show.actual_audience / 1000000).toFixed(2)}M</span>
                  <span className={`${getAccuracyColor(currentPrediction.accuracy)} font-bold mt-1`}>
                    Précision: {currentPrediction.accuracy ? currentPrediction.accuracy.toFixed(1) : 0}%
                  </span>
                </div>
              ) : (
                <span>Pronostic verrouillé</span>
              )}
            </div>
          ) : isPredicted ? (
            <motion.button
              onClick={handleModifyPrediction}
              className="w-full py-3 bg-purple-600 text-white rounded-lg font-medium hover:bg-purple-700 transition-all duration-200"
              whileTap={{ scale: 0.95 }}
              disabled={isLocked}
            >
              Modifier mon pronostic
            </motion.button>
          ) : (
            <motion.button
              onClick={handleValidatePrediction}
              disabled={isLoading || isLocked}
              className={`w-full py-3 rounded-lg font-medium transition-all duration-200 ${
                isLoading
                  ? 'bg-purple-400 text-white cursor-wait'
                  : isLocked
                  ? 'bg-gray-600 text-white cursor-not-allowed'
                  : 'bg-purple-600 hover:bg-purple-700 text-white'
              }`}
              whileTap={!isLoading && !isLocked ? { scale: 0.95 } : {}}
            >
              {isLoading ? (
                <span className="flex items-center justify-center">
                  <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Validation en cours...
                </span>
              ) : isLocked ? (
                'Pronostic verrouillé'
              ) : (
                'Valider mon pronostic'
              )}
            </motion.button>
          )}
        </div>
      </div>
    </div>
  );
}
