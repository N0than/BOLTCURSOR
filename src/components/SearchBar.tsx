import React from 'react';
import { Search } from 'lucide-react';

interface SearchBarProps {
  theme: 'dark' | 'light';
}

export function SearchBar({ theme }: SearchBarProps) {
  const bgColor = theme === 'dark' ? 'bg-gray-800' : 'bg-white';
  const textColor = theme === 'dark' ? 'text-white' : 'text-gray-900';
  const placeholderColor = theme === 'dark' ? 'placeholder-gray-400' : 'placeholder-gray-500';
  const iconColor = theme === 'dark' ? 'text-gray-400' : 'text-gray-500';

  return (
    <div className="relative w-full max-w-xl">
      <input
        type="text"
        placeholder="Rechercher une émission, une chaîne ou un utilisateur..."
        className={`w-full pl-12 pr-4 py-3 ${bgColor} ${textColor} ${placeholderColor} rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 transition-colors duration-200`}
      />
      <Search className={`absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 ${iconColor}`} />
    </div>
  );
}
