import React, { useState, useEffect } from 'react';
import { PageTransition } from '../components/PageTransition';
import { ShowCard } from '../components/ShowCard';
import type { Show } from '../types';
import { getShows, subscribeToShows } from '../lib/supabase';
import toast from 'react-hot-toast';

export function Home() {
  const [shows, setShows] = useState<Show[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadShows();

    // S'abonner aux changements
    const unsubscribe = subscribeToShows((updatedShows) => {
      setShows(updatedShows);
    });

    return () => {
      unsubscribe();
    };
  }, []);

  const loadShows = async () => {
    try {
      setIsLoading(true);
      const data = await getShows();
      setShows(data);
    } catch (error) {
      console.error('Erreur lors du chargement des programmes:', error);
      toast.error('Erreur lors du chargement des programmes');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <PageTransition>
      <div className="space-y-8">
        <h1 className="text-3xl font-bold">Accueil</h1>

        {isLoading ? (
          <div className="flex justify-center items-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-500"></div>
          </div>
        ) : shows.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-gray-400">Aucun programme disponible pour le moment</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6">
            {shows.map((show) => (
              <ShowCard key={show.id} show={show} theme="dark" />
            ))}
          </div>
        )}
      </div>
    </PageTransition>
  );
}
