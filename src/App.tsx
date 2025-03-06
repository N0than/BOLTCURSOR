import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, useLocation } from 'react-router-dom';
import { AnimatePresence } from 'framer-motion';
import { Sidebar } from './components/Sidebar';
import { SearchBar } from './components/SearchBar';
import { AdminDashboard } from './components/AdminDashboard';
import { AdminTvManagement } from './components/AdminTvManagement';
import { UserAuth } from './components/UserAuth';
import { LogOut, Key } from 'lucide-react';
import { Home } from './pages/Home';
import { Predictions } from './pages/Predictions';
import { Community } from './pages/Community';
import { Leaderboard } from './pages/Leaderboard';
import { Settings } from './pages/Settings';
import { Help } from './pages/Help';
import { Sun, Moon } from 'lucide-react';
import { signIn, signUp, signOut, supabase } from './lib/supabase';
import toast from 'react-hot-toast';
import AdminAccessPopup from './components/AdminAccessPopup';

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [currentUser, setCurrentUser] = useState(null);
  const [authError, setAuthError] = useState();
  const [theme, setTheme] = useState('dark');
  const [isAdminAccessPopupOpen, setIsAdminAccessPopupOpen] = useState(false);

  useEffect(() => {
    checkSession();

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setIsAuthenticated(!!session);
      setCurrentUser(session?.user ? { email: session.user.email, username: session.user.user_metadata.username || session.user.email.split('@')[0] } : null);
    });

    return () => subscription.unsubscribe();
  }, []);

  const checkSession = async () => {
    const { data: { session } } = await supabase.auth.getSession();
    setIsAuthenticated(!!session);
    setCurrentUser(session?.user ? { email: session.user.email, username: session.user.user_metadata.username || session.user.email.split('@')[0] } : null);
  };

  const handleUserLogin = async (email, password) => {
    try {
      await signIn(email, password);
      setAuthError(undefined);
      toast.success('Connexion réussie !');
    } catch (error) {
      setAuthError(error.message);
      toast.error('Erreur de connexion');
    }
  };

  const handleUserRegister = async (email, password, username) => {
    try {
      await signUp(email, password);
      setAuthError(undefined);
      toast.success('Inscription réussie ! Veuillez vérifier votre email.');
    } catch (error) {
      setAuthError(error.message);
      toast.error('Erreur lors de l\'inscription');
    }
  };

  const handleLogout = async () => {
    try {
      await signOut();
      toast.success('Déconnexion réussie !');
    } catch (error) {
      toast.error('Erreur lors de la déconnexion');
    }
  };

  const toggleTheme = () => {
    setTheme(prevTheme => (prevTheme === 'dark' ? 'light' : 'dark'));
    document.documentElement.classList.toggle('dark');
    document.documentElement.classList.toggle('light');
  };

  const openAdminAccessPopup = () => {
    setIsAdminAccessPopupOpen(true);
  };

  const closeAdminAccessPopup = () => {
    setIsAdminAccessPopupOpen(false);
  };

  return (
    <Router>
      <div className={theme === 'dark' ? 'dark' : 'light'}>
        <Routes>
          <Route
            path="/*"
            element={
              isAuthenticated ? (
                <MainApp
                  isAuthenticated={isAuthenticated}
                  currentUser={currentUser}
                  authError={authError}
                  theme={theme}
                  handleLogout={handleLogout}
                  toggleTheme={toggleTheme}
                  openAdminAccessPopup={openAdminAccessPopup}
                />
              ) : (
                <UserAuth
                  onLogin={handleUserLogin}
                  onRegister={handleUserRegister}
                  error={authError}
                />
              )
            }
          />
          <Route path="/admin" element={<AdminDashboard />} />
          <Route path="/admin/programs" element={<AdminDashboard />} />
          <Route path="/admin/tv" element={<AdminTvManagement />} />
        </Routes>
        <AdminAccessPopup isOpen={isAdminAccessPopupOpen} onClose={closeAdminAccessPopup} />
      </div>
    </Router>
  );
}

function MainApp({ isAuthenticated, currentUser, authError, theme, handleLogout, toggleTheme, openAdminAccessPopup }) {
  const location = useLocation();

  return (
    <div className={`min-h-screen ${theme === 'dark' ? 'bg-gray-900 text-gray-100' : 'bg-gray-100 text-gray-900'}`}>
      <Sidebar />

      <main className="ml-64 p-8">
        <div className="max-w-7xl mx-auto">
          <div className="flex justify-between items-center mb-8">
            <SearchBar theme={theme} />
            <div className="flex items-center gap-4">
              <button
                onClick={openAdminAccessPopup}
                className="p-2 hover:bg-gray-800 dark:hover:bg-gray-200 light-hover:bg-gray-300 rounded-lg transition-colors"
              >
                <Key className="w-5 h-5 text-white" />
              </button>
              <button
                onClick={handleLogout}
                className="p-2 hover:bg-gray-800 dark:hover:bg-gray-200 light-hover:bg-gray-300 rounded-lg transition-colors"
              >
                <LogOut className="w-5 h-5 text-white" />
              </button>
              <button
                onClick={toggleTheme}
                className="p-2 hover:bg-gray-800 dark:hover:bg-gray-200 light-hover:bg-gray-300 rounded-lg transition-colors"
              >
                {theme === 'dark' ? (
                  <Sun className="w-5 h-5 text-white" />
                ) : (
                  <Moon className="w-5 h-5 text-white" />
                )}
              </button>
            </div>
          </div>

          <AnimatePresence mode="wait">
            <Routes location={location} key={location.pathname}>
              <Route path="/" element={<Home />} />
              <Route path="/predictions" element={<Predictions />} />
              <Route path="/community" element={<Community />} />
              <Route path="/leaderboard" element={<Leaderboard />} />
              <Route path="/settings" element={<Settings />} />
              <Route path="/help" element={<Help />} />
              <Route path="/admin/tv" element={<AdminTvManagement />} />
            </Routes>
          </AnimatePresence>
        </div>
      </main>
    </div>
  );
}

export default App;
