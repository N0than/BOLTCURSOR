import React, { useState, useEffect } from 'react';
import { PageTransition } from '../components/PageTransition';
import { Lock, UserIcon, Edit2, Save } from 'lucide-react';
import { getCurrentUser, updateUserProfile, updateUserEmail, updateUserPassword } from '../lib/supabase';
import type { User } from '../types';
import toast from 'react-hot-toast';

export function Settings() {
  const [user, setUser] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isUpdating, setIsUpdating] = useState(false);
  const [lastUpdateAttempt, setLastUpdateAttempt] = useState(0);
  const [editableFields, setEditableFields] = useState({
    username: false,
    email: false,
    password: false,
    avatar: false,
  });

  const [formData, setFormData] = useState({
    username: '',
    email: '',
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
    avatar: '',
  });

  useEffect(() => {
    loadUserProfile();
  }, []);

  const loadUserProfile = async () => {
    try {
      setIsLoading(true);
      const userData = await getCurrentUser();
      setUser(userData);
      if (userData) {
        setFormData(prev => ({
          ...prev,
          username: userData.username || '',
          email: userData.email || '',
          avatar: userData.avatar || '',
        }));
      }
    } catch (error) {
      console.error('Error loading user profile:', error);
      toast.error('Erreur lors du chargement du profil');
    } finally {
      setIsLoading(false);
    }
  };

  const handleUpdateField = async (field) => {
    if (!user) return;

    const COOLDOWN_PERIOD = 60000;

    try {
      setIsLoading(true);
      setIsUpdating(true);

      switch (field) {
        case 'username':
          if (formData.username !== user.username) {
            await updateUserProfile(user.id, { username: formData.username });
          }
          break;
        case 'email':
          if (formData.email && formData.email !== user.email) {
            const now = Date.now();
            const timeElapsed = now - lastUpdateAttempt;

            if (timeElapsed < COOLDOWN_PERIOD) {
              const remainingTime = Math.ceil((COOLDOWN_PERIOD - timeElapsed) / 1000);
              toast.error(`Veuillez patienter ${remainingTime} secondes avant de réessayer`);
              return;
            }

            setLastUpdateAttempt(now);

            try {
              await updateUserEmail(formData.email);
            } catch (error) {
              if (error.message.includes('patienter')) {
                toast.error(error.message);
                return;
              }
              throw error;
            }
          }
          break;
        case 'password':
          if (formData.newPassword) {
            if (formData.newPassword !== formData.confirmPassword) {
              toast.error('Les mots de passe ne correspondent pas');
              return;
            }
            await updateUserPassword(formData.newPassword);
            setFormData(prev => ({
              ...prev,
              currentPassword: '',
              newPassword: '',
              confirmPassword: '',
            }));
          }
          break;
        case 'avatar':
          if (formData.avatar !== user.avatar) {
            await updateUserProfile(user.id, { avatar: formData.avatar });
          }
          break;
      }

      setEditableFields(prev => ({ ...prev, [field]: false }));
      toast.success('Mise à jour réussie !');
      loadUserProfile();
    } catch (error) {
      console.error('Error updating profile:', error);
      const errorMessage = error.message === 'over_email_send_rate_limit' 
        ? 'Veuillez patienter 60 secondes avant de réessayer'
        : error.message || 'Erreur lors de la mise à jour';
      toast.error(errorMessage);
    } finally {
      setIsLoading(false);
      setIsUpdating(false);
    }
  };

  if (isLoading) {
    return (
      <PageTransition>
        <div className="flex justify-center items-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-500"></div>
        </div>
      </PageTransition>
    );
  }

  return (
    <PageTransition>
      <div className="space-y-8">
        <h1 className="text-3xl font-bold">Paramètres</h1>

        <div className="grid grid-cols-1 gap-8">
          <section className="bg-gray-800 rounded-xl p-6">
            <div className="flex items-center gap-4 mb-6">
              <UserIcon className="w-6 h-6 text-purple-500" />
              <h2 className="text-xl font-bold">Profil</h2>
            </div>
            
            <div className="space-y-6">
              <div className="flex items-center justify-between mb-4">
                <label className="block text-sm font-medium text-gray-300">
                  Photo de profil
                </label>
                <button
                  onClick={() => setEditableFields(prev => ({ ...prev, avatar: !prev.avatar }))}
                  className="text-purple-500 hover:text-purple-400"
                >
                  {editableFields.avatar ? (
                    <Save className="w-4 h-4" />
                  ) : (
                    <Edit2 className="w-4 h-4" />
                  )}
                </button>
              </div>
              <div className="flex gap-4 items-center">
                <img
                  src={formData.avatar || `https://api.dicebear.com/7.x/initials/svg?seed=${user?.username}`}
                  alt="Profile"
                  className="w-16 h-16 rounded-full object-cover"
                />
                {editableFields.avatar && (
                  <>
                    <input
                      type="url"
                      placeholder="URL de l'image"
                      value={formData.avatar}
                      onChange={(e) => setFormData(prev => ({ ...prev, avatar: e.target.value }))}
                      className="px-4 py-2 bg-gray-700 text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                    />
                    <button
                      onClick={() => handleUpdateField('avatar')}
                      className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
                    >
                      Enregistrer
                    </button>
                  </>
                )}
              </div>

              {/* Username */}
              <SettingRow
                label="Nom d'utilisateur"
                field="username"
                value={formData.username}
                onChange={(e) => setFormData(prev => ({ ...prev, username: e.target.value }))}
                editableFields={editableFields}
                setEditableFields={setEditableFields}
                handleUpdateField={handleUpdateField}
              />

              {/* Email */}
              <SettingRow
                label="Email"
                field="email"
                value={formData.email}
                onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
                editableFields={editableFields}
                setEditableFields={setEditableFields}
                handleUpdateField={handleUpdateField}
              />

              {/* Password */}
              <SettingRow
                label="Mot de passe"
                field="password"
                value="••••••••••••"
                isPassword={true}
                editableFields={editableFields}
                setEditableFields={setEditableFields}
                handleUpdateField={handleUpdateField}
                newPassword={formData.newPassword}
                confirmPassword={formData.confirmPassword}
                setFormData={setFormData}
              />
            </div>
          </section>

          <section className="bg-gray-800 rounded-xl p-6">
            <div className="flex items-center gap-4 mb-6">
              <Lock className="w-6 h-6 text-purple-500" />
              <h2 className="text-xl font-bold">Confidentialité</h2>
            </div>
            
          </section>
        </div>
      </div>
    </PageTransition>
  );
}

function SettingRow({ label, field, value, onChange, editableFields, setEditableFields, handleUpdateField, isPassword, newPassword, confirmPassword, setFormData }) {
  const isEditing = editableFields[field] === true;
  return (
    <div>
      <div className="flex justify-between items-center mb-2">
        <label className="block text-sm font-medium text-gray-300">
          {label}
        </label>
        <button
          onClick={() => setEditableFields(prev => ({ ...prev, [field]: !prev[field] }))}
          className="text-purple-500 hover:text-purple-400"
        >
          {isEditing ? (
            <Save className="w-4 h-4" />
          ) : (
            <Edit2 className="w-4 h-4" />
          )}
        </button>
      </div>
      {isEditing ? (
        <>
          {field === 'password' ? (
            <div className="space-y-4">
              <input
                type="password"
                placeholder="Nouveau mot de passe"
                value={newPassword}
                onChange={(e) => setFormData(prev => ({ ...prev, newPassword: e.target.value }))}
                className="w-full px-4 py-2 bg-gray-700 text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
              />
              <input
                type="password"
                placeholder="Confirmer le nouveau mot de passe"
                value={confirmPassword}
                onChange={(e) => setFormData(prev => ({ ...prev, confirmPassword: e.target.value }))}
                className="w-full px-4 py-2 bg-gray-700 text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
              />
            </div>
          ) : (
            <input
              type={field === 'email' ? 'email' : 'text'}
              value={value}
              onChange={onChange}
              className="w-full px-4 py-2 bg-gray-700 text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
            />
          )}
          <button
            onClick={() => handleUpdateField(field)}
            className="w-full px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors mt-2"
          >
            Enregistrer
          </button>
        </>
      ) : (
        <div className="px-4 py-2 bg-gray-700 text-white rounded-lg opacity-75">
          {value}
        </div>
      )}
    </div>
  );
}
