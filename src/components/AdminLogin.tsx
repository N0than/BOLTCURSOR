import React, { useState } from 'react';
import { Lock } from 'lucide-react';
import { PageTransition } from './PageTransition';
import { Link } from 'react-router-dom';

interface AdminLoginProps {
  onLogin: (email: string, password: string) => void;
  error?: string;
}

export function AdminLogin({ onLogin, error }: AdminLoginProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onLogin(email, password);
  };

  return (
    <PageTransition>
      <div className="min-h-screen flex items-center justify-center">
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
            Administration
          </h2>
          
          <form onSubmit={handleSubmit} className="space-y-6">
            {error && (
              <div className="bg-red-500/10 border border-red-500 text-red-500 px-4 py-2 rounded-lg">
                {error}
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
              />
            </div>
            
            <button
              type="submit"
              className="w-full py-3 bg-purple-600 text-white rounded-lg font-medium hover:bg-purple-700 transition-colors"
            >
              Se connecter
            </button>
          </form>
        </div>
      </div>
    </PageTransition>
  );
}
