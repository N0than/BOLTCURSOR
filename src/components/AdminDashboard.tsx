import React, { useState } from 'react';
import { PageTransition } from './PageTransition';
import { PlusCircle, Trash2, Edit, BarChart2, Users, Download, AlertTriangle } from 'lucide-react';
import type { Show, AdminStats } from '../types';
import toast from 'react-hot-toast';
import { Sidebar } from './Sidebar';
import { SearchBar } from './SearchBar';

const mockStats: AdminStats = {
  totalUsers: 1250,
  totalPredictions: 45678,
  averageAccuracy: 0.76,
  activePredictions: 890
};

const mockShows: Show[] = [
  {
    id: '1',
    title: 'The Voice - La finale',
    channel: 'TF1',
    datetime: '2025-03-15T20:50:00',
    description: 'La grande finale de The Voice 2025 !',
    host: 'Nikos Aliagas',
    genre: 'Divertissement',
    imageUrl: 'https://images.unsplash.com/photo-1516280440614-37939bbacd81'
  }
];

export function AdminDashboard() {
  const [shows, setShows] = useState<Show[]>(mockShows);
  const [stats] = useState<AdminStats>(mockStats);
  const [showForm, setShowForm] = useState(false);
  const [isDeleting, setIsDeleting] = useState<string | null>(null);
  const [newShow, setNewShow] = useState<Show>({
    id: '',
    title: '',
    channel: '',
    datetime: '',
    description: '',
    host: '',
    genre: '',
    imageUrl: ''
  });

  const handleAddShow = async () => {
    if (newShow.title && newShow.channel && newShow.datetime && newShow.description && newShow.host && newShow.genre && newShow.imageUrl) {
      try {
        const newId = String(shows.length + 1);
        setShows([...shows, { ...newShow, id: newId }]);
        setNewShow({
          id: '',
          title: '',
          channel: '',
          datetime: '',
          description: '',
          host: '',
          genre: '',
          imageUrl: ''
        });
        setShowForm(false);
        toast.success('Programme ajouté avec succès !');
      } catch (error) {
        toast.error('Erreur lors de l\'ajout du programme');
      }
    } else {
      toast.error('Veuillez remplir tous les champs', {
        icon: <AlertTriangle className="w-5 h-5 text-yellow-500" />
      });
    }
  };

  const handleDeleteShow = async (id: string) => {
    try {
      setIsDeleting(id);
      await new Promise(resolve => setTimeout(resolve, 1000)); // Simulate API call
      setShows(shows.filter(show => show.id !== id));
      toast.success('Programme supprimé avec succès !');
    } catch (error) {
      toast.error('Erreur lors de la suppression du programme');
    } finally {
      setIsDeleting(null);
    }
  };

  const handleDownload = () => {
    const data = JSON.stringify({ stats, shows }, null, 2);
    const blob = new Blob([data], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'audiencemasters-data.json';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    toast.success('Données exportées avec succès !');
  };

  return (
    <div className="min-h-screen bg-gray-900">
      <Sidebar />
      <main className="ml-64 p-8">
        <div className="max-w-7xl mx-auto">
          <div className="flex justify-between items-center mb-8">
            <SearchBar theme="dark" />
            <button
              onClick={handleDownload}
              className="flex items-center gap-2 px-4 py-2 bg-gray-800 text-white rounded-lg hover:bg-gray-700 transition-colors"
            >
              <Download className="w-5 h-5" />
              Exporter les données
            </button>
          </div>

          <PageTransition>
            <div className="space-y-8">
              <h1 className="text-3xl font-bold text-white">Dashboard Administrateur</h1>

              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                <div className="bg-gray-800 p-6 rounded-xl">
                  <div className="flex items-center gap-4 mb-4">
                    <Users className="w-8 h-8 text-purple-500" />
                    <h3 className="text-lg font-medium text-white">Utilisateurs</h3>
                  </div>
                  <p className="text-3xl font-bold text-white">{stats.totalUsers}</p>
                </div>
                
                <div className="bg-gray-800 p-6 rounded-xl">
                  <div className="flex items-center gap-4 mb-4">
                    <BarChart2 className="w-8 h-8 text-purple-500" />
                    <h3 className="text-lg font-medium text-white">Prédictions</h3>
                  </div>
                  <p className="text-3xl font-bold text-white">{stats.totalPredictions}</p>
                </div>
                
                <div className="bg-gray-800 p-6 rounded-xl">
                  <div className="flex items-center gap-4 mb-4">
                    <BarChart2 className="w-8 h-8 text-green-500" />
                    <h3 className="text-lg font-medium text-white">Précision moyenne</h3>
                  </div>
                  <p className="text-3xl font-bold text-white">{(stats.averageAccuracy * 100).toFixed(1)}%</p>
                </div>
                
                <div className="bg-gray-800 p-6 rounded-xl">
                  <div className="flex items-center gap-4 mb-4">
                    <BarChart2 className="w-8 h-8 text-blue-500" />
                    <h3 className="text-lg font-medium text-white">Prédictions actives</h3>
                  </div>
                  <p className="text-3xl font-bold text-white">{stats.activePredictions}</p>
                </div>
              </div>

              <div className="bg-gray-800 rounded-xl p-6">
                <div className="flex justify-between items-center mb-6">
                  <h2 className="text-xl font-bold text-white">Programmes TV</h2>
                  <button
                    onClick={() => setShowForm(true)}
                    className="flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
                  >
                    <PlusCircle className="w-5 h-5" />
                    Ajouter un programme
                  </button>
                </div>

                {showForm && (
                  <div className="mb-8 bg-gray-700 p-6 rounded-lg">
                    <h3 className="text-lg font-bold text-white mb-4">Nouveau programme</h3>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <input
                        type="text"
                        placeholder="Titre"
                        value={newShow.title}
                        onChange={(e) => setNewShow({ ...newShow, title: e.target.value })}
                        className="px-4 py-2 bg-gray-600 text-white rounded-lg"
                      />
                      <input
                        type="text"
                        placeholder="Chaîne"
                        value={newShow.channel}
                        onChange={(e) => setNewShow({ ...newShow, channel: e.target.value })}
                        className="px-4 py-2 bg-gray-600 text-white rounded-lg"
                      />
                      <input
                        type="datetime-local"
                        value={newShow.datetime}
                        onChange={(e) => setNewShow({ ...newShow, datetime: e.target.value })}
                        className="px-4 py-2 bg-gray-600 text-white rounded-lg"
                      />
                      <input
                        type="text"
                        placeholder="Genre"
                        value={newShow.genre}
                        onChange={(e) => setNewShow({ ...newShow, genre: e.target.value })}
                        className="px-4 py-2 bg-gray-600 text-white rounded-lg"
                      />
                      <input
                        type="text"
                        placeholder="Présentateur"
                        value={newShow.host}
                        onChange={(e) => setNewShow({ ...newShow, host: e.target.value })}
                        className="px-4 py-2 bg-gray-600 text-white rounded-lg"
                      />
                      <input
                        type="url"
                        placeholder="URL de l'image"
                        value={newShow.imageUrl}
                        onChange={(e) => setNewShow({ ...newShow, imageUrl: e.target.value })}
                        className="px-4 py-2 bg-gray-600 text-white rounded-lg"
                      />
                      <textarea
                        placeholder="Description"
                        value={newShow.description}
                        onChange={(e) => setNewShow({ ...newShow, description: e.target.value })}
                        className="px-4 py-2 bg-gray-600 text-white rounded-lg col-span-2"
                        rows={3}
                      />
                    </div>
                    <div className="flex justify-end gap-4 mt-4">
                      <button
                        onClick={() => setShowForm(false)}
                        className="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-500 transition-colors"
                      >
                        Annuler
                      </button>
                      <button
                        onClick={handleAddShow}
                        className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
                      >
                        Ajouter
                      </button>
                    </div>
                  </div>
                )}

                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead>
                      <tr className="border-b border-gray-700">
                        <th className="text-left py-4 px-6 text-white">Titre</th>
                        <th className="text-left py-4 px-6 text-white">Chaîne</th>
                        <th className="text-left py-4 px-6 text-white">Date</th>
                        <th className="text-left py-4 px-6 text-white">Genre</th>
                        <th className="text-right py-4 px-6 text-white">Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {shows.map((show) => (
                        <tr key={show.id} className="border-b border-gray-700">
                          <td className="py-4 px-6 text-white">{show.title}</td>
                          <td className="py-4 px-6 text-white">{show.channel}</td>
                          <td className="py-4 px-6 text-white">
                            {new Date(show.datetime).toLocaleDateString('fr-FR')}
                          </td>
                          <td className="py-4 px-6 text-white">{show.genre}</td>
                          <td className="py-4 px-6">
                            <div className="flex justify-end gap-2">
                              <button className="p-2 hover:bg-gray-700 rounded-lg transition-colors">
                                <Edit className="w-5 h-5 text-purple-500" />
                              </button>
                              <button
                                onClick={() => handleDeleteShow(show.id)}
                                disabled={isDeleting === show.id}
                                className="p-2 hover:bg-gray-700 rounded-lg transition-colors"
                              >
                                {isDeleting === show.id ? (
                                  <svg className="animate-spin h-5 w-5 text-red-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                  </svg>
                                ) : (
                                  <Trash2 className="w-5 h-5 text-red-500" />
                                )}
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </PageTransition>
        </div>
      </main>
    </div>
  );
}
