import React, { useState } from 'react';
import { Link } from 'react-router-dom';

interface UserAuthProps {
  onLogin: (email: string, password: string) => void;
  onRegister: (email: string, password: string, username: string) => void;
  error?: string;
}

export function UserAuth({ onLogin, onRegister, error }: UserAuthProps) {
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [username, setUsername] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (isLogin) {
      onLogin(email, password);
    } else {
      onRegister(email, password, username || email.split('@')[0]);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-950">
      <div className="bg-gray-800 p-8 rounded-xl shadow-xl w-full max-w-md">
        <div className="flex items-center justify-center mb-8">
          <Link to="/">
            <img
              src="https://i.ibb.co/LXvXDJX1/logo.png"
              alt="Audience Masters"
              style={{ width: '150px', height: '150px', objectFit: 'contain' }}
            />
          </Link>
        </div>
        <h2 className="text-2xl font-bold text-center text-white mb-8">
          {isLogin ? 'Connexion' : "Inscription"}
        </h2>
        
        <form onSubmit={handleSubmit} className="space-y-6">
          {error && (
            <div className="bg-red-500/10 border border-red-500 text-red-500 px-4 py-2 rounded-lg">
              {error}
            </div>
          )}
          
          {!isLogin && (
            <div>
              <label htmlFor="username" className="block text-sm font-medium text-gray-200 mb-2">
                Nom d'utilisateur
              </label>
              <input
                type="text"
                id="username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                className="w-full px-4 py-2 bg-gray-700 text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                required={!isLogin}
                placeholder="Choisissez un nom d'utilisateur"
              />
            </div>
          )}
          
          <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-200 mb-2">
              Email
            </label>
            <input
              type="email"
              id="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
              required
              placeholder="Votre adresse email"
            />
          </div>
          
          <div>
            <label htmlFor="password" className="block text-sm font-medium text-gray-200 mb-2">
              Mot de passe
            </label>
            <input
              type="password"
              id="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-2 bg-gray-700 text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
              required
              placeholder="Votre mot de passe"
            />
          </div>
          
          <button
            type="submit"
            className="w-full py-3 bg-purple-600 text-white rounded-lg font-medium hover:bg-purple-700 transition-colors"
          >
            {isLogin ? 'Se connecter' : "S'inscrire"}
          </button>

          <div className="text-center">
            <button
              type="button"
              onClick={() => setIsLogin(!isLogin)}
              className="text-purple-400 hover:text-purple-300 text-sm"
            >
              {isLogin ? "Pas encore de compte ? S'inscrire" : 'Déjà un compte ? Se connecter'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
