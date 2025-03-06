import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { Check, X } from 'lucide-react';

const AdminAccessPopup = ({ isOpen, onClose }) => {
  const [securityCode, setSecurityCode] = useState('');
  const [shake, setShake] = useState(false);
  const navigate = useNavigate();
  const popupRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (popupRef.current && !popupRef.current.contains(event.target)) onClose();
    };

    if (isOpen) document.addEventListener('mousedown', handleClickOutside);
    else document.removeEventListener('mousedown', handleClickOutside);

    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isOpen, onClose]);

  const handleDigitClick = (digit) => {
    if (securityCode.length < 4) setSecurityCode(securityCode + digit);
  };

  const handleValidate = () => {
    if (securityCode === '1987') {
      navigate('/admin/tv');
      onClose();
    } else {
      setShake(true);
      setTimeout(() => setShake(false), 500);
      setSecurityCode('');
    }
  };

  const handleClear = () => {
    setSecurityCode('');
  };

  const maskedCode = '*'.repeat(securityCode.length) + '•'.repeat(Math.max(0, 4 - securityCode.length));

  return !isOpen ? null : (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div ref={popupRef} className={`bg-gray-800 rounded-xl p-6 w-full max-w-md ${shake ? 'animate-shake' : ''}`}>
        <h3 className="text-xl font-bold text-white mb-4">Accès Administration</h3>
        <div className="text-center text-white text-2xl mb-6 tracking-wider">{maskedCode || '• • • •'}</div>
        <div className="grid grid-cols-3 gap-4 mb-6">
          {[1, 2, 3, 4, 5, 6, 7, 8, 9].map((digit) => (
            <button
              key={digit}
              onClick={() => handleDigitClick(digit.toString())}
              className="py-3 bg-gray-700 text-white rounded-lg hover:bg-gray-600 transition-colors"
            >
              {digit}
            </button>
          ))}
        </div>
        <div className="flex justify-between gap-4">
          <button
            onClick={handleClear}
            className="w-1/2 py-3 bg-gray-600 text-white rounded-lg hover:bg-gray-500 transition-colors"
          >
            Effacer
          </button>
          <button
            onClick={handleValidate}
            className="w-1/2 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
          >
            Valider
          </button>
        </div>
      </div>
    </div>
  );
};

export default AdminAccessPopup;
