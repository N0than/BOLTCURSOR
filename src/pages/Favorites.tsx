import React from 'react';
import { PageTransition } from '../components/PageTransition';
import { Heart } from 'lucide-react';
import { ShowCard } from '../components/ShowCard';
import type { Show } from '../types';

export function Favorites() {
  const favoriteShows: Show[] = [
    {
      id: '1',
      title: 'The Voice - La finale',
      channel: 'TF1',
      datetime: '2025-03-15T20:50:00',
      description: 'La grande finale de The Voice 2025 !',
      host: 'Nikos Aliagas',
      genre: 'Divertissement',
      imageUrl: 'https://images.unsplash.com/photo-1516280440614-37939bbacd81'
    },
    {
      id: '2',
      title: 'Koh-Lanta',
      channel: 'TF1',
      datetime: '2025-03-14T21:00:00',
      description: 'La nouvelle saison de Koh-Lanta débute !',
      host: 'Stéphane Bern',
      genre: 'Survie',
      imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e'
    },
    {
      id: '3',
      title: 'Les Feux de l\'Amour',
      channel: 'France 2',
      datetime: '2025-03-15T20:00:00',
      description: 'Drame romantique sur France 2',
      host: 'N/A',
      genre: 'Drame',
      imageUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80'
    },
  ];

  return (
    <PageTransition>
      <div className="space-y-8">
        <h1 className="text-3xl font-bold">Mes Favoris</h1>

        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6">
          {favoriteShows.map((show) => (
            <ShowCard key={show.id} show={show} />
          ))}
        </div>
      </div>
    </PageTransition>
  );
}
