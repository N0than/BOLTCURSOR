import React, { useState, useEffect } from 'react';
import { PageTransition } from '../components/PageTransition';
import { Trophy, Target, Medal, Users, RefreshCw } from 'lucide-react';
import { getUsers, subscribeToUsers } from '../lib/supabase';
import type { User } from '../types';
import toast from 'react-hot-toast';

export function Leaderboard() {
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [topStats, setTopStats] = useState({
    bestScore: { score: 0, username: '' },
    bestAccuracy: { accuracy: 0, username: '' },
    mostPredictions: { count: 0, username: '' }
  });

  useEffect(() => {
    loadUsers();
    
    // Subscribe to changes in the users table for real-time updates
    const unsubscribe = subscribeToUsers((updatedUsers) => {
      if (updatedUsers && updatedUsers.length > 0) {
        // Sort users by score in descending order
        const sortedUsers = [...updatedUsers].sort((a, b) => b.score - a.score);
        setUsers(sortedUsers);
        updateTopStats(sortedUsers);
      }
    });
    
    return () => {
      unsubscribe();
    };
  }, []);

  const updateTopStats = (sortedUsers: User[]) => {
    if (sortedUsers.length > 0) {
      const bestScore = {
        score: sortedUsers[0]?.score || 0,
        username: sortedUsers[0]?.username || '-'
      };
      
      const bestAccuracy = sortedUsers.reduce((prev, curr) => 
        ((curr?.accuracy || 0) > (prev?.accuracy || 0)) ? curr : prev
      , { accuracy: 0, username: '-' });
      
      const mostPredictions = sortedUsers.reduce((prev, curr) => {
        const prevCount = prev?.predictions_count || prev?.predictions || 0;
        const currCount = curr?.predictions_count || curr?.predictions || 0;
        return currCount > prevCount ? curr : prev;
      }, { predictions_count: 0, predictions: 0, username: '-' });

      setTopStats({
        bestScore: { score: bestScore.score, username: bestScore.username },
        bestAccuracy: { 
          accuracy: bestAccuracy?.accuracy || 0, 
          username: bestAccuracy?.username || '-' 
        },
        mostPredictions: { 
          count: mostPredictions.predictions_count || mostPredictions.predictions || 0, 
          username: mostPredictions?.username || '-'
        }
      });
    }
  };

  const loadUsers = async () => {
    try {
      setIsLoading(true);
      const data = await getUsers();
      
      if (data && data.length > 0) {
        // Sort users by score in descending order
        const sortedUsers = [...data].sort((a, b) => b.score - a.score);
        setUsers(sortedUsers);
        updateTopStats(sortedUsers);
      } else {
        setUsers([]);
        console.log("Aucun utilisateur trouvé dans la base de données");
      }
    } catch (error) {
      console.error('Erreur lors du chargement des utilisateurs:', error);
      toast.error('Erreur lors du chargement du classement');
    } finally {
      setIsLoading(false);
    }
  };

  const handleRefresh = async () => {
    try {
      setIsRefreshing(true);
      await loadUsers();
      toast.success('Classement actualisé !');
    } catch (error) {
      console.error('Erreur lors de l\'actualisation:', error);
      toast.error('Erreur lors de l\'actualisation du classement');
    } finally {
      setIsRefreshing(false);
    }
  };

  return (
    <PageTransition>
      <div className="space-y-8">
        <h1 className="text-3xl font-bold">Classement des joueurs</h1>

        <div className="grid grid-cols-3 gap-6">
          <div className="bg-gray-800 p-6 rounded-xl">
            <div className="flex items-center gap-4 mb-4">
              <Trophy className="w-8 h-8 text-yellow-500" />
              <h3 className="text-lg font-medium">Meilleur score</h3>
            </div>
            <p className="text-3xl font-bold">{topStats.bestScore.score.toLocaleString()}</p>
            <p className="text-sm text-gray-400 mt-2">{topStats.bestScore.username}</p>
          </div>
          
          <div className="bg-gray-800 p-6 rounded-xl">
            <div className="flex items-center gap-4 mb-4">
              <Target className="w-8 h-8 text-purple-500" />
              <h3 className="text-lg font-medium">Meilleure précision</h3>
            </div>
            <p className="text-3xl font-bold">{topStats.bestAccuracy.accuracy.toFixed(1)}%</p>
            <p className="text-sm text-gray-400 mt-2">{topStats.bestAccuracy.username}</p>
          </div>
          
          <div className="bg-gray-800 p-6 rounded-xl">
            <div className="flex items-center gap-4 mb-4">
              <Medal className="w-8 h-8 text-purple-500" />
              <h3 className="text-lg font-medium">Plus de pronostics</h3>
            </div>
            <p className="text-3xl font-bold">{topStats.mostPredictions.count}</p>
            <p className="text-sm text-gray-400 mt-2">{topStats.mostPredictions.username}</p>
          </div>
        </div>

        <div className="bg-gray-800 rounded-xl p-6">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-xl font-bold">Top joueurs</h2>
            <button 
              onClick={handleRefresh}
              disabled={isRefreshing}
              className="flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors disabled:bg-purple-400 disabled:cursor-not-allowed"
            >
              {isRefreshing ? (
                <>
                  <RefreshCw className="w-4 h-4 animate-spin" />
                  Actualisation...
                </>
              ) : (
                <>
                  <RefreshCw className="w-4 h-4" />
                  Actualiser
                </>
              )}
            </button>
          </div>
          
          {isLoading ? (
            <div className="flex justify-center items-center h-32">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-500"></div>
            </div>
          ) : users.length === 0 ? (
            <p className="text-center text-gray-400 py-8">Aucun joueur pour le moment</p>
          ) : (
            <div className="space-y-4">
              {users.map((user, index) => (
                <div
                  key={user.id}
                  className="flex items-center justify-between p-4 bg-gray-700/50 rounded-lg"
                >
                  <div className="flex items-center gap-4">
                    <span className={`text-xl font-bold ${
                      index === 0 ? 'text-yellow-500' :
                      index === 1 ? 'text-gray-400' :
                      index === 2 ? 'text-amber-600' :
                      'text-gray-500'
                    }`}>
                      #{index + 1}
                    </span>
                    <img
                      src={user.avatar || `https://api.dicebear.com/7.x/initials/svg?seed=${user.username}`}
                      alt={user.username}
                      className="w-10 h-10 rounded-full object-cover"
                    />
                    <div>
                      <span className="font-medium">{user.username}</span>
                      {user.is_online && (
                        <span className="ml-2 text-xs text-green-400">En ligne</span>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center gap-8">
                    <div className="text-right">
                      <p className="font-bold">{(user?.score || 0).toLocaleString()}</p>
                      <p className="text-sm text-gray-400">points</p>
                    </div>
                    <div className="text-right">
                      <p className="font-bold">{(user?.accuracy || 0).toFixed(1)}%</p>
                      <p className="text-sm text-gray-400">précision</p>
                    </div>
                    <div className="text-right">
                      <p className="font-bold">{user?.predictions_count || user?.predictions || 0}</p>
                      <p className="text-sm text-gray-400">pronostics</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </PageTransition>
  );
}
