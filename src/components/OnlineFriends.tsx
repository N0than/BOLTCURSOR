import React from 'react';
import type { User } from '../types';

const mockFriends: User[] = [
  {
    id: '1',
    username: 'Sophie Martin',
    avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
    score: 1250,
    predictions: 45,
    accuracy: 0.82,
    isOnline: true,
    currentPrediction: {
      showId: '1',
      prediction: 2500000
    }
  },
  {
    id: '2',
    username: 'Thomas Dubois',
    avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
    score: 980,
    predictions: 32,
    accuracy: 0.75,
    isOnline: true
  }
];

export function OnlineFriends() {
  return (
    <div className="bg-gray-800 rounded-xl p-4">
      <h2 className="text-lg font-semibold text-gray-100 mb-4">Amis en ligne</h2>
      <div className="space-y-4">
        {mockFriends.map((friend) => (
          <div key={friend.id} className="flex items-center gap-3">
            <div className="relative">
              <img
                src={friend.avatar}
                alt={friend.username}
                className="w-10 h-10 rounded-full object-cover"
              />
              <span className="absolute bottom-0 right-0 w-3 h-3 bg-green-500 rounded-full border-2 border-gray-800"></span>
            </div>
            <div>
              <h3 className="text-sm font-medium text-gray-100">{friend.username}</h3>
              {friend.currentPrediction ? (
                <p className="text-xs text-purple-400">En train de pronostiquer</p>
              ) : (
                <p className="text-xs text-gray-400">En ligne</p>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
