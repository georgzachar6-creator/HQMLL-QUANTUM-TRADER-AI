// HQMLL — Service Worker Registration
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker
      .register('/sw.js', { scope: '/' })
      .then((reg) => {
        console.log('[HQMLL SW] Registered, scope:', reg.scope);
        reg.addEventListener('updatefound', () => {
          const worker = reg.installing;
          worker?.addEventListener('statechange', () => {
            if (worker.state === 'installed' && navigator.serviceWorker.controller) {
              console.log('[HQMLL SW] Update available');
            }
          });
        });
      })
      .catch((err) => console.warn('[HQMLL SW] Registration failed:', err));
  });
}
