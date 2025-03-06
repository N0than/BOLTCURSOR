import React from 'react';
import { PageTransition } from '../components/PageTransition';
import { Download } from 'lucide-react';

export function Downloads() {
  const downloads = [
    {
      id: '1',
      title: 'The Voice - La finale',
      channel: 'TF1',
      datetime: '2025-03-15T20:50:00',
      description: 'La grande finale de The Voice 2025 !',
      host: 'Nikos Aliagas',
      genre: 'Divertissement',
      imageUrl: 'https://images.unsplash.com/photo-1516280440614-37939bbacd81',
      fileSize: '1.2GB',
      downloadUrl: 'https://example.com/downloads/the-voice-finale.mp4'
    },
    {
      id: '2',
      title: 'Koh-Lanta',
      channel: 'TF1',
      datetime: '2025-03-14T21:00:00',
      description: 'La nouvelle saison de Koh-Lanta débute !',
      host: 'Stéphane Bern',
      genre: 'Survie',
      imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
      fileSize: '900MB',
      downloadUrl: 'https://example.com/downloads/koh-lanta.mp4'
    },
    {
      id: '3',
      title: 'Les Feux de l\'Amour',
      channel: 'France 2',
      datetime: '2025-03-15T20:00:00',
      description: 'Drame romantique sur France 2',
      host: 'N/A',
      genre: 'Drame',
      imageUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
      fileSize: '800MB',
      downloadUrl: 'https://example.com/downloads/les-feux-de-l-amour.mp4'
    },
  ];

  return (
    <PageTransition>
      <div className="space-y-8">
        <h1 className="text-3xl font-bold">Téléchargements</h1>

        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6">
          {downloads.map((download) => (
            <div key={download.id} className="bg-gray-800 rounded-xl p-4 overflow-hidden">
              <img
                src={download.imageUrl}
                alt={download.title}
                className="w-full h-48 object-cover"
              />
              <div className="p-4">
                <h3 className="text-lg font-semibold text-gray-100 mb-2">{download.title}</h3>
                <p className="text-sm text-gray-400 mb-4">{download.description}</p>
                <div className="flex items-center justify-between mb-4">
                  <span className="text-sm font-medium text-purple-400">{download.channel}</span>
                  <span className="text-sm text-gray-400">
                    {new Date(download.datetime).toLocaleDateString('fr-FR')}
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center text-gray-400 text-sm">
                    <Download className="w-4 h-4 mr-1" />
                    <span>{download.fileSize}</span>
                  </div>
                  <a
                    href={download.downloadUrl}
                    download
                    className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
                  >
                    Télécharger
                  </a>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </PageTransition>
  );
}
