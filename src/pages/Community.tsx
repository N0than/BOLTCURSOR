import React from 'react';
import { PageTransition } from '../components/PageTransition';
import { Users, MessageCircle } from 'lucide-react';

export function Community() {
  const users = [
    {
      id: '1',
      username: 'Sophie Martin',
      avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
      lastActive: '2025-03-15T18:30:00',
      message: 'Bienvenue à tous !'
    },
    {
      id: '2',
      username: 'Thomas Dubois',
      avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
      lastActive: '2025-03-15T19:00:00',
      message: 'J\'ai vu une belle finale de The Voice !'
    },
    {
      id: '3',
      username: 'Marie Lambert',
      avatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
      lastActive: '2025-03-15T17:45:00',
      message: 'Qui a vu Koh-Lanta ?'
    },
  ];

  return (
    <PageTransition>
      <div className="space-y-8">
        <h1 className="text-3xl font-bold">Communauté</h1>

        <div className="bg-gray-800 rounded-xl p-6">
          <h2 className="text-xl font-bold mb-6">Messages récents</h2>
          <div className="space-y-4">
            {users.map((user) => (
              <div key={user.id} className="flex items-center gap-4 p-4 bg-gray-700/50 rounded-lg">
                <img
                  src={user.avatar}
                  alt={user.username}
                  className="w-10 h-10 rounded-full object-cover"
                />
                <div>
                  <h3 className="text-sm font-medium text-gray-100">{user.username}</h3>
                  <p className="text-xs text-gray-400">
                    {new Date(user.lastActive).toLocaleTimeString('fr-FR', {
                      hour: '2-digit',
                      minute: '2-digit'
                    })}
                  </p>
                  <p className="text-sm text-gray-300 mt-2">{user.message}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-gray-800 rounded-xl p-6">
          <h2 className="text-xl font-bold mb-6">Membres en ligne</h2>
          <div className="space-y-4">
            {users.map((user) => (
              <div key={user.id} className="flex items-center gap-4">
                <img
                  src={user.avatar}
                  alt={user.username}
                  className="w-10 h-10 rounded-full object-cover"
                />
                <div className="flex items-center gap-2">
                  <h3 className="text-sm font-medium text-gray-100">{user.username}</h3>
                  <span className="text-green-500">En ligne</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </PageTransition>
  );
}
