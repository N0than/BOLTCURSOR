import React, { useState, useEffect } from 'react';
import { PageTransition } from './PageTransition';
import { PlusCircle, Trash2, Edit, Bell, Download, BarChart2, RefreshCw, TrendingUp } from 'lucide-react';
import toast from 'react-hot-toast';
import type { Show } from '../types';
import { Sidebar } from './Sidebar';
import { SearchBar } from './SearchBar';
import { getShows, createShow, updateShow, deleteShow, subscribeToShows, updateActualAudience } from '../lib/supabase';
import { motion, AnimatePresence } from 'framer-motion';

const TV_CHANNELS = [
  'TF1', 'France 2', 'France 3', 'France 4', 'Canal+', 'France 5', 'M6', 'Arte',
  'LCP', 'W9', 'TMC', 'TFX', 'GULLI', 'BFM TV', 'CNews', 'LCI', 'France Info',
  'CStar', 'TF1 Séries Films', 'L\'Équipe', '6ter', 'RMC Découverte', 'RMC Story', 'Chérie 25'
];

export function AdminTvManagement() {
  const [shows, setShows] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [editingShow, setEditingShow] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  const [showAudienceModal, setShowAudienceModal] = useState(false);
  const [selectedShow, setSelectedShow] = useState(null);
  const [actualAudience, setActualAudience] = useState(0);
  const [isModalClosing, setIsModalClosing] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);

  const [newShow, setNewShow] = useState({
    title: '',
    channel: '',
    datetime: '',
    description: '',
    isNew: true,
    genre: '',
    imageUrl: '',
    actual_audience: null,
  });

  useEffect(() => {
    loadShows();
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
      setIsRefreshing(true);
      const data = await getShows();
      setShows(data);
    } catch (error) {
      console.error('Erreur lors du chargement des programmes:', error);
      toast.error('Erreur lors du chargement des programmes');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  const handleAddShow = async () => {
    if (!newShow.title || !newShow.channel || !newShow.datetime || !newShow.description || !newShow.genre || !newShow.imageUrl) {
      toast.error('Tous les champs sont obligatoires');
      return;
    }

    try {
      setIsLoading(true);
      if (editingShow) {
        await updateShow(editingShow.id, newShow);
        toast.success('Programme modifié avec succès !');
      } else {
        await createShow(newShow);
        toast.success('Programme ajouté avec succès !');
      }
      setNewShow({
        title: '',
        channel: '',
        datetime: '',
        description: '',
        isNew: true,
        genre: '',
        imageUrl: '',
        actual_audience: null,
      });
      setShowForm(false);
      setEditingShow(null);
    } catch (error) {
      console.error('Erreur lors de la sauvegarde:', error);
      toast.error(error.message || 'Erreur lors de la sauvegarde du programme');
    } finally {
      setIsLoading(false);
    }
  };

  const handleEditShow = (show) => {
    setEditingShow(show);
    setNewShow({
      title: show.title,
      channel: show.channel,
      datetime: show.datetime,
      description: show.description,
      isNew: show.isNew,
      genre: show.genre,
      imageUrl: show.imageUrl,
      actual_audience: show.actual_audience || null,
    });
    setShowForm(true);
  };

  const handleDeleteShow = async (id) => {
    try {
      setIsLoading(true);
      await deleteShow(id);
      toast.success('Programme supprimé avec succès !');
    } catch (error) {
      console.error('Erreur lors de la suppression:', error);
      toast.error(error.message || 'Erreur lors de la suppression du programme');
    } finally {
      setIsLoading(false);
    }
  };

  const handleOpenAudienceModal = (show) => {
    setSelectedShow(show);
    setActualAudience(show.actual_audience || 0);
    setShowAudienceModal(true);
  };

  const handleUpdateActualAudience = async () => {
    if (!selectedShow) return;

    try {
      setIsLoading(true);
      setIsModalClosing(true); // Start closing animation
      const updatedShow = await updateActualAudience(selectedShow.id, actualAudience);
      if (updatedShow) {
        // Update the show in the local state
        setShows(prevShows => prevShows.map(show => 
          show.id === updatedShow.id ? updatedShow : show
        ));
        toast.success('Audience réelle mise à jour avec succès !');
      } else {
        // Si updateActualAudience retourne null, on recharge tous les shows
        await loadShows();
        toast.success('Audience réelle mise à jour avec succès ! Données rechargées.');
      }
      
      // Wait for the animation to complete before closing the modal
      setTimeout(() => {
        setShowAudienceModal(false);
        setSelectedShow(null);
        setActualAudience(0);
        setIsModalClosing(false); // Reset closing state
      }, 300);
    } catch (error) {
      console.error('Erreur lors de la mise à jour de l\'audience:', error);
      toast.error(error.message || 'Erreur lors de la mise à jour de l\'audience');
      setIsModalClosing(false); // Reset closing state in case of error
    } finally {
      setIsLoading(false);
    }
  };

  const formatDateTime = (dateTimeString) => {
    const date = new Date(dateTimeString);
    return date.toLocaleString('fr-FR', { timeZone: 'Europe/London' });
  };

  const modalVariants = {
    hidden: { opacity: 0, y: 50 },
    visible: { opacity: 1, y: 0 },
    exit: { opacity: 0, y: 50, transition: { duration: 0.3 } }
  };

  const closeModal = () => {
    setShowAudienceModal(false);
    setSelectedShow(null);
    setActualAudience(0);
    setIsModalClosing(false);
  };

  return (
    <div className="min-h-screen bg-gray-900">
      <Sidebar />
      <main className="ml-64 p-8">
        <div className="max-w-7xl mx-auto">
          <div className="flex justify-between items-center mb-8">
            <SearchBar theme="dark" />
            <button
              onClick={() => setShowForm(true)}
              className="flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
              disabled={isLoading}
            >
              <PlusCircle className="w-5 h-5" />
              Ajouter un programme
            </button>
          </div>

          <PageTransition>
            <div className="space-y-8">
              <h1 className="text-3xl font-bold text-white">Administration</h1>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-gray-800 p-6 rounded-xl">
                  <div className="flex items-center gap-4 mb-4">
                    <BarChart2 className="w-8 h-8 text-purple-500" />
                    <h3 className="text-lg font-medium text-white">Total Programmes</h3>
                  </div>
                  <p className="text-3xl font-bold text-white">{shows.length}</p>
                </div>
                
                <div className="bg-gray-800 p-6 rounded-xl">
                  <div className="flex items-center gap-4 mb-4">
                    <Bell className="w-8 h-8 text-purple-500" />
                    <h3 className="text-lg font-medium text-white">Notifications</h3>
                  </div>
                  <button className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors">
                    Envoyer une notification
                  </button>
                </div>
                
                <div className="bg-gray-800 p-6 rounded-xl">
                  <div className="flex items-center gap-4 mb-4">
                    <Download className="w-8 h-8 text-purple-500" />
                    <h3 className="text-lg font-medium text-white">Exporter</h3>
                  </div>
                  <button className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors">
                    Exporter les données
                  </button>
                </div>
              </div>

              {showForm && (
                <div className="bg-gray-800 rounded-xl p-6">
                  <h2 className="text-xl font-bold text-white mb-6">
                    {editingShow ? 'Modifier un programme' : 'Ajouter un nouveau programme'}
                  </h2>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <input
                      type="text"
                      placeholder="Titre"
                      value={newShow.title}
                      onChange={(e) => setNewShow({ ...newShow, title: e.target.value })}
                      className="px-4 py-2 bg-gray-700 text-white rounded-lg"
                    />
                    <select
                      value={newShow.channel}
                      onChange={(e) => setNewShow({ ...newShow, channel: e.target.value })}
                      className="px-4 py-2 bg-gray-700 text-white rounded-lg"
                    >
                      <option value="">Sélectionner une chaîne</option>
                      {TV_CHANNELS.map((channel) => (
                        <option key={channel} value={channel}>
                          {channel}
                        </option>
                      ))}
                    </select>
                    <input
                      type="datetime-local"
                      value={newShow.datetime}
                      onChange={(e) => setNewShow({ ...newShow, datetime: e.target.value })}
                      className="px-4 py-2 bg-gray-700 text-white rounded-lg"
                    />
                    <select
                      value={newShow.genre}
                      onChange={(e) => setNewShow({ ...newShow, genre: e.target.value })}
                      className="px-4 py-2 bg-gray-700 text-white rounded-lg"
                    >
                      <option value="">Sélectionner un genre</option>
                      <option value="Divertissement">Divertissement</option>
                      <option value="Sport">Sport</option>
                      <option value="Talk-show">Talk-show</option>
                      <option value="Série">Série</option>
                      <option value="Film">Film</option>
                      <option value="Documentaire">Documentaire</option>
                    </select>
                    <select
                      value={newShow.isNew ? "true" : "false"}
                      onChange={(e) => setNewShow({ ...newShow, isNew: e.target.value === "true" })}
                      className="px-4 py-2 bg-gray-700 text-white rounded-lg"
                    >
                      <option value="true">Inédit</option>
                      <option value="false">Rediffusion</option>
                    </select>
                    <input
                      type="url"
                      placeholder="URL de l'image"
                      value={newShow.imageUrl}
                      onChange={(e) => setNewShow({ ...newShow, imageUrl: e.target.value })}
                      className="px-4 py-2 bg-gray-700 text-white rounded-lg"
                    />
                    <input
                      type="number"
                      placeholder="Audience Réelle (en millions)"
                      value={newShow.actual_audience === null ? '' : (newShow.actual_audience / 1000000).toFixed(2)}
                      onChange={(e) => setNewShow({ ...newShow, actual_audience: e.target.value === '' ? null : parseFloat(e.target.value) * 1000000 })}
                      className="px-4 py-2 bg-gray-700 text-white rounded-lg"
                    />
                    <textarea
                      placeholder="Description"
                      value={newShow.description}
                      onChange={(e) => setNewShow({ ...newShow, description: e.target.value })}
                      className="px-4 py-2 bg-gray-700 text-white rounded-lg col-span-2"
                      rows={3}
                    />
                  </div>
                  <div className="flex justify-end gap-4 mt-4">
                    <button
                      onClick={() => {
                        setShowForm(false);
                        setEditingShow(null);
                        setNewShow({
                          title: '',
                          channel: '',
                          datetime: '',
                          description: '',
                          isNew: true,
                          genre: '',
                          imageUrl: '',
                          actual_audience: null,
                        });
                      }}
                      className="px-4 py-2 bg-gray-700 text-white rounded-lg hover:bg-gray-600 transition-colors"
                      disabled={isLoading}
                    >
                      Annuler
                    </button>
                    <button
                      onClick={handleAddShow}
                      className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
                      disabled={isLoading}
                    >
                      {isLoading ? 'Chargement...' : editingShow ? 'Modifier' : 'Ajouter'}
                    </button>
                  </div>
                </div>
              )}

              <div className="bg-gray-800 rounded-xl p-6">
                <div className="flex justify-between items-center mb-6">
                  <h2 className="text-xl font-bold text-white">Liste des programmes</h2>
                  <button
                    onClick={loadShows}
                    disabled={isRefreshing}
                    className="flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
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
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead>
                      <tr className="border-b border-gray-700">
                        <th className="text-left py-4 px-6 text-white">Titre</th>
                        <th className="text-left py-4 px-6 text-white">Chaîne</th>
                        <th className="text-left py-4 px-6 text-white">Date</th>
                        <th className="text-left py-4 px-6 text-white">Genre</th>
                        <th className="text-left py-4 px-6 text-white">Audience Réelle</th>
                        <th className="text-right py-4 px-6 text-white">Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {shows.map((show) => (
                        <tr key={show.id} className="border-b border-gray-700">
                          <td className="py-4 px-6 text-white">{show.title}</td>
                          <td className="py-4 px-6 text-white">{show.channel}</td>
                          <td className="py-4 px-6 text-white">
                            {formatDateTime(show.datetime)}
                          </td>
                          <td className="py-4 px-6 text-white">{show.genre}</td>
                          <td className="py-4 px-6">
                            {show.actual_audience !== null && show.actual_audience !== undefined ? (
                              <span className="text-green-400 font-medium">
                                {(show.actual_audience / 1000000).toFixed(2)}M
                              </span>
                            ) : (
                              <button
                                onClick={() => handleOpenAudienceModal(show)}
                                className="flex items-center gap-1 text-purple-400 hover:text-purple-300 transition-colors"
                              >
                                <TrendingUp className="w-4 h-4" />
                                <span>Définir</span>
                              </button>
                            )}
                          </td>
                          <td className="py-4 px-6">
                            <div className="flex justify-end gap-2">
                              <button
                                onClick={() => handleEditShow(show)}
                                className="p-2 hover:bg-gray-700 rounded-lg transition-colors"
                                disabled={isLoading}
                              >
                                <Edit className="w-5 h-5 text-purple-500" />
                              </button>
                              {show.actual_audience !== null && show.actual_audience !== undefined ? (
                                <button
                                  onClick={() => handleOpenAudienceModal(show)}
                                  className="p-2 hover:bg-gray-700 rounded-lg transition-colors"
                                  disabled={isLoading}
                                >
                                  <TrendingUp className="w-5 h-5 text-green-500" />
                                </button>
                              ) : null}
                              <button
                                onClick={() => handleDeleteShow(show.id)}
                                className="p-2 hover:bg-gray-700 rounded-lg transition-colors"
                                disabled={isLoading}
                              >
                                <Trash2 className="w-5 h-5 text-red-500" />
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

      {/* Modal pour l'audience réelle */}
      <AnimatePresence>
        {showAudienceModal && selectedShow && (
          <motion.div
            className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
            variants={modalVariants}
            initial="hidden"
            animate="visible"
            exit="exit"
            key="audienceModal"
          >
            <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md">
              <h3 className="text-xl font-bold text-white mb-4">
                Audience réelle - {selectedShow.title}
              </h3>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">
                    Audience réelle (en millions de téléspectateurs)
                  </label>
                  <input
                    type="number"
                    step="0.1"
                    value={actualAudience / 1000000}
                    onChange={(e) => setActualAudience(parseFloat(e.target.value) * 1000000)}
                    className="w-full px-4 py-2 bg-gray-700 text-white rounded-lg"
                  />
                </div>
                {selectedShow.actual_audience !== null && selectedShow.actual_audience !== undefined && (
                  <div className="p-3 bg-gray-700 rounded-lg">
                    <p className="text-sm text-yellow-300">
                      Ce programme a déjà une audience réelle de {(selectedShow.actual_audience / 1000000).toFixed(2)}M.
                      La modification mettra à jour les pronostics des utilisateurs.
                    </p>
                  </div>
                )}
                <div className="flex justify-end gap-4">
                  <button
                    onClick={closeModal}
                    className="px-4 py-2 bg-gray-700 text-white rounded-lg hover:bg-gray-600 transition-colors"
                  >
                    Annuler
                  </button>
                  <button
                    onClick={handleUpdateActualAudience}
                    className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
                    disabled={isLoading}
                  >
                    {isLoading ? 'Mise à jour...' : 'Valider'}
                  </button>
                </div>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
