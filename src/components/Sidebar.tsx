import React from 'react';
import { Link } from 'react-router-dom';
import { Home, TrendingUp, Users, Trophy, Settings, HelpCircle, Shield, Key } from 'lucide-react';

const menuItems = [
  { icon: Home, label: 'Accueil', path: '/' },
  { icon: TrendingUp, label: 'Mes Pronostics', path: '/predictions' },
  { icon: Trophy, label: 'Classement Joueurs', path: '/leaderboard' },
  { icon: Settings, label: 'Paramètres', path: '/settings' },
  { icon: HelpCircle, label: 'Aide', path: '/help' },
];

export function Sidebar() {
  return (
    <aside className="fixed left-0 top-0 h-full w-64 bg-gray-800 text-white p-4 dark:bg-gray-900">
      <div className="flex items-center justify-center mb-8">
        <Link to="/">
          <img
            src="https://i.ibb.co/LXvXDJX1/logo.png"
            alt="Audience Masters"
            style={{ width: '150px', height: '150px', objectFit: 'contain' }}
          />
        </Link>
      </div>
      
      <nav className="space-y-2">
        {menuItems.map((item) => (
          <Link
            key={item.path}
            to={item.path}
            className="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-gray-700 transition-colors text-white"
          >
            <item.icon className="w-5 h-5 text-white" />
            <span>{item.label}</span>
          </Link>
        ))}
      </nav>
    </aside>
  );
}
