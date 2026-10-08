import { api } from './api';

/**
 * Client Keep-Alive Heartbeat Service
 * Pings the API health check & self server every 10 minutes
 * to prevent Render free-tier sleep mode (15 min inactivity limit)
 */
const PING_INTERVAL_MS = 10 * 60 * 1000; // 10 minutes

export function startClientKeepAlive() {
  const ping = () => {
    // 1. Ping backend health check
    api.get('/v1/health').catch(() => {});

    // 2. Self-ping current window origin
    if (typeof window !== 'undefined' && window.location?.origin) {
      fetch(window.location.origin, { method: 'HEAD', mode: 'no-cors' }).catch(() => {});
    }
  };

  // Initial ping 5 seconds after app load
  setTimeout(ping, 5000);

  // Interval heartbeat loop every 10 minutes
  setInterval(ping, PING_INTERVAL_MS);
}
