// Firebase Messaging Service Worker for PWA push notifications
// NOTE: Config values are injected at build time via build script

/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

// Initialize Firebase app in the Service Worker scope
// Placeholders are replaced by scripts/inject-firebase-config.js at build time
firebase.initializeApp({
  apiKey: 'AIzaSyDAJrWkn7DEUp8boXK9LEL7v-tIHhvV0Ac',
  authDomain: 'choice-lux-cars-8d510.firebaseapp.com',
  projectId: 'choice-lux-cars-8d510',
  storageBucket: 'choice-lux-cars-8d510.appspot.com',
  messagingSenderId: '522491134348',
  appId: '1:522491134348:web:3ac424d68338b3ddb7d6a9',
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  const title = payload?.notification?.title || 'Choice Lux Cars';
  const body = payload?.notification?.body || '';
  const data = payload?.data || {};

  const options = {
    body,
    icon: '/favicon.png',
    badge: '/icons/Icon-192.png',
    tag: data.notification_type || 'choice_lux_cars',
    data,
  };

  self.registration.showNotification(title, options);
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const route = event.notification?.data?.route || '/';

  event.waitUntil(
    (async () => {
      const allClients = await clients.matchAll({ type: 'window', includeUncontrolled: true });
      for (const client of allClients) {
        // Focus existing tab if same origin
        if (client.url && client.url.startsWith(self.location.origin)) {
          client.focus();
          try { client.postMessage({ type: 'notification-click', data: event.notification?.data || {} }); } catch (_) {}
          return;
        }
      }
      // Otherwise, open a new tab
      await clients.openWindow(route);
    })()
  );
});


