import React from 'react';
import ReactDOM from 'react-dom/client';
import { ToastProvider } from './components/Toast';
import { AppProvider } from './context/AppContext';
import { App } from './App';
import { startClientKeepAlive } from './services/keepAliveService';
import './index.css';

// Start keep-alive heartbeat loop to prevent Render free-tier sleep mode
startClientKeepAlive();

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ToastProvider>
      <AppProvider>
        <App />
      </AppProvider>
    </ToastProvider>
  </React.StrictMode>
);
