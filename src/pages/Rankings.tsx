import React from 'react';
import { PageTransition } from '../components/PageTransition';
import { BarChart2, TrendingUp, Users } from 'lucide-react';

export function Rankings() {
  const channels = [
    { name: 'TF1', audience: 5200000, variation: '+12%' },
    { name: 'France 2', audience: 3800000, variation: '-5%' },
    { name: 'M6', audience: 2900000, variation: '+8%' },
    { name: 'France 3', audience: 2100000, variation: '-2%' },
  ];

  return (
    <PageTransition>
      <div className="space-y-8">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold">Classements</h1>
          <div className="flex gap-4">
            <button className="px-4 py-2 bg-gray-800 rounded-lg hover:bg-gray-700 transition-colors">
              Aujourd'hui
            </button>
            <button className="px-4 py-2 bg-gray-800 rounded-lg hover:bg-gray-700 transition-colors">
              Cette semaine
            </button>
            <button className="px-4 py-2 bg-gray-800 rounded-lg hover:bg-gray-700 transition-colors">
              Ce mois
            </button>
          </div>
        </div>

        <div className="grid grid-cols-3 gap-6">
          <div className="bg-gray-800 p-6 rounded-xl">
            <div className="flex items-center gap-4 mb-4">
              <BarChart2 className="w-8 h-8 text-purple-500" />
              <h3 className="text-lg font-medium">Audience Totale</h3>
            </div>
            <p className="text-3xl font-bold">14.2M</p>
            <p className="text-sm text-green-400 mt-2">+8% vs hier</p>
          </div>
          
          <div className="bg-gray-800 p-6 rounded-xl">
            <div className="flex items-center gap-4 mb-4">
              <TrendingUp className="w-8 h-8 text-purple-500" />
              <h3 className="text-lg font-medium">Part d'audience</h3>
            </div>
            <p className="text-3xl font-bold">22.5%</p>
            <p className="text-sm text-red-400 mt-2">-2% vs hier</p>
          </div>
          
          <div className="bg-gray-800 p-6 rounded-xl">
            <div className="flex items-center gap-4 mb-4">
              <Users className="w-8 h-8 text-purple-500" />
              <h3 className="text-lg font-medium">Téléspectateurs</h3>
            </div>
            <p className="text-3xl font-bold">8.7M</p>
            <p className="text-sm text-green-400 mt-2">+5% vs hier</p>
          </div>
        </div>

        <div className="bg-gray-800 rounded-xl p-6">
          <h2 className="text-xl font-bold mb-6">Classement par chaîne</h2>
          <div className="space-y-4">
            {channels.map((channel, index) => (
              <div
                key={channel.name}
                className="flex items-center justify-between p-4 bg-gray-700/50 rounded-lg"
              >
                <div className="flex items-center gap-4">
                  <span className="text-xl font-bold text-gray-400">#{index + 1}</span>
                  <span className="font-medium">{channel.name}</span>
                </div>
                <div className="flex items-center gap-6">
                  <span className="font-bold">{(channel.audience / 1000000).toFixed(1)}M</span>
                  <span className={channel.variation.startsWith('+') ? 'text-green-400' : 'text-red-400'}>
                    {channel.variation}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </PageTransition>
  );
}
