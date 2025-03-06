import React, { useState, useEffect } from 'react';
import { PageTransition } from '../components/PageTransition';
import { History, Target, TrendingUp } from 'lucide-react';
import { getUserPredictions, subscribeToPredictions } from '../lib/supabase';
import type { Prediction, Show } from '../types';
import toast from 'react-hot-toast';

export function Predictions() {
  const [predictions, setPredictions] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [stats, setStats] = useState({
    accuracy: 0,
    total: 0,
    points: 0
  });

  useEffect(() => {
    loadPredictions();

    const unsubscribe = subscribeToPredictions((updatedPredictions) => {
      setPredictions(updatedPredictions);
      updateStats(updatedPredictions);
    });

    return () => {
      unsubscribe();
    };
  }, []);

  const loadPredictions = async () => {
    try {
      setIsLoading(true);
      const data = await getUserPredictions();
      setPredictions(data);
      updateStats(data);
    } catch (error) {
      console.error('Erreur lors du chargement des pronostics:', error);
      toast.error('Erreur lors du chargement des pronostics');
      // Set empty array to avoid breaking the UI
      setPredictions([]);
      updateStats([]);
    } finally {
      setIsLoading(false);
    }
  };

  const updateStats = (predictions) => {
    const total = predictions.length;
    const accuracySum = predictions.reduce((sum, p) => sum + (p.accuracy || 0), 0);
    const averageAccuracy = total > 0 ? accuracySum / total : 0;
    const points = predictions.reduce((sum, p) => sum + (p.accuracy ? Math.floor(p.accuracy) : 0), 0);

    setStats({
      accuracy: averageAccuracy,
      total,
      points
    });
  };

  return (
    <PageTransition>
      <div className="space-y-8">
        <h1 className="text-3xl font-bold">Mes Pronostics</h1>

        <div className="grid grid-cols-3 gap-6">
          <div className="bg-gray-800 p-6 rounded-xl">
            <div className="flex items-center gap-4 mb-4">
              <Target className="w-8 h-8 text-purple-500" />
              <h3 className="text-lg font-medium">Précision moyenne</h3>
            </div>
            <p className="text-3xl font-bold">{stats.accuracy.toFixed(1)}%</p>
          </div>
          
          <div className="bg-gray-800 p-6 rounded-xl">
            <div className="flex items-center gap-4 mb-4">
              <History className="w-8 h-8 text-purple-500" />
              <h3 className="text-lg font-medium">Total pronostics</h3>
            </div>
            <p className="text-3xl font-bold">{stats.total}</p>
          </div>
          
          <div className="bg-gray-800 p-6 rounded-xl">
            <div className="flex items-center gap-4 mb-4">
              <TrendingUp className="w-8 h-8 text-purple-500" />
              <h3 className="text-lg font-medium">Points gagnés</h3>
            </div>
            <p className="text-3xl font-bold">{stats.points}</p>
          </div>
        </div>

        <div className="bg-gray-800 rounded-xl p-6">
          <h2 className="text-xl font-bold mb-6">Historique des pronostics</h2>
          {isLoading ? (
            <div className="flex justify-center items-center h-32">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-500"></div>
            </div>
          ) : predictions.length === 0 ? (
            <p className="text-center text-gray-400 py-8">Aucun pronostic pour le moment</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-700">
                    <th className="text-left py-4 px-6">Émission</th>
                    <th className="text-left py-4 px-6">Chaîne</th>
                    <th className="text-left py-4 px-6">Date</th>
                    <th className="text-right py-4 px-6">Pronostic</th>
                    <th className="text-right py-4 px-6">Réel</th>
                    <th className="text-right py-4 px-6">Précision</th>
                  </tr>
                </thead>
                <tbody>
                  {predictions.map((prediction) => (
                    <tr key={prediction.id} className="border-b border-gray-700">
                      <td className="py-4 px-6">{prediction.show.title}</td>
                      <td className="py-4 px-6">{prediction.show.channel}</td>
                      <td className="py-4 px-6">
                        {new Date(prediction.show.datetime).toLocaleDateString('fr-FR')}
                      </td>
                      <td className="text-right py-4 px-6">
                        {(prediction.prediction / 1000000).toFixed(1)}M
                      </td>
                      <td className="text-right py-4 px-6">
                        {prediction.actual_audience
                          ? `${(prediction.actual_audience / 1000000).toFixed(1)}M`
                          : '-'}
                      </td>
                      <td className="text-right py-4 px-6">
                        {prediction.accuracy ? (
                          <span className={prediction.accuracy >= 95 ? 'text-green-400' : 'text-yellow-400'}>
                            {prediction.accuracy.toFixed(1)}%
                          </span>
                        ) : (
                          '-'
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </PageTransition>
  );
}
