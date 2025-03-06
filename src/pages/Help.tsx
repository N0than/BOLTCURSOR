import React from 'react';
import { PageTransition } from '../components/PageTransition';
import { HelpCircle } from 'lucide-react';

export function Help() {
  return (
    <PageTransition>
      <div className="space-y-8">
        <h1 className="text-3xl font-bold">Aide</h1>

        <div className="bg-gray-800 rounded-xl p-6">
          <h2 className="text-xl font-bold mb-4">Comment fonctionne Audience Masters ?</h2>
          <p className="text-sm text-gray-300">
            Audience Masters est une plateforme où vous pouvez pronostiquer l'audience des programmes TV. Vous pouvez consulter les classements, voir les prédictions des autres utilisateurs et même participer à des concours pour gagner des prix.
          </p>
        </div>

        <div className="bg-gray-800 rounded-xl p-6">
          <h2 className="text-xl font-bold mb-4">Comment faire un pronostic ?</h2>
          <p className="text-sm text-gray-300">
            Pour faire un pronostic, allez sur la page des programmes TV et cliquez sur le bouton "Pronostiquer". Entrez votre estimation de l'audience et soumettez-la.
          </p>
        </div>

        <div className="bg-gray-800 rounded-xl p-6">
          <h2 className="text-xl font-bold mb-4">Comment consulter les classements ?</h2>
          <p className="text-sm text-gray-300">
            Vous pouvez consulter les classements en cliquant sur l'onglet "Classements" dans la barre latérale. Vous verrez les classements par chaîne, par utilisateur et par précision.
          </p>
        </div>

        <div className="bg-gray-800 rounded-xl p-6">
          <h2 className="text-xl font-bold mb-4">Contactez-nous</h2>
          <p className="text-sm text-gray-300">
            Si vous avez des questions ou des problèmes, n'hésitez pas à nous contacter par email à <a href="mailto:support@audiencemasters.com" className="text-purple-400 hover:text-purple-300">support@audiencemasters.com</a>.
          </p>
        </div>
      </div>
    </PageTransition>
  );
}
