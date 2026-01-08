const fs = require('fs');
const path = require('path');

const serviceWorkerPath = path.join(__dirname, '../web/firebase-messaging-sw.js');

// Read env vars from process.env (set via --dart-define or environment variables)
// Defaults match the current values from env.dart
const config = {
  apiKey: process.env.FIREBASE_API_KEY || 'AIzaSyDAJrWkn7DEUp8boXK9LEL7v-tIHhvV0Ac',
  authDomain: process.env.FIREBASE_AUTH_DOMAIN || 'choice-lux-cars-8d510.firebaseapp.com',
  projectId: process.env.FIREBASE_PROJECT_ID || 'choice-lux-cars-8d510',
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET || 'choice-lux-cars-8d510.appspot.com',
  messagingSenderId: process.env.FIREBASE_SENDER_ID || process.env.FIREBASE_MESSAGING_SENDER_ID || '522491134348',
  appId: process.env.FIREBASE_APP_ID || '1:522491134348:web:3ac424d68338b3ddb7d6a9',
};

let content = fs.readFileSync(serviceWorkerPath, 'utf8');

// Replace placeholders with actual values
content = content.replace('__FIREBASE_API_KEY__', config.apiKey);
content = content.replace('__FIREBASE_AUTH_DOMAIN__', config.authDomain);
content = content.replace('__FIREBASE_PROJECT_ID__', config.projectId);
content = content.replace('__FIREBASE_STORAGE_BUCKET__', config.storageBucket);
content = content.replace('__FIREBASE_SENDER_ID__', config.messagingSenderId);
content = content.replace('__FIREBASE_APP_ID__', config.appId);

fs.writeFileSync(serviceWorkerPath, content, 'utf8');
console.log('✅ Firebase config injected into service worker');
