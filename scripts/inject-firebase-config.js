const fs = require('fs');
const path = require('path');

// Target dir: web/ for dev (flutter run), build/web for production build (keeps source clean)
const targetDir = process.env.INJECT_TARGET_DIR || process.argv.find(a => a.startsWith('--target-dir='))?.split('=')[1] || path.resolve(__dirname, '../web');

try {
  const serviceWorkerPath = path.join(targetDir, 'firebase-messaging-sw.js');
  const indexPath = path.join(targetDir, 'index.html');

  if (!fs.existsSync(serviceWorkerPath)) {
    console.error('Error: firebase-messaging-sw.js not found at', serviceWorkerPath);
    console.error('Set INJECT_TARGET_DIR or use --target-dir=build/web for production build');
    process.exit(1);
  }

  // Config from env vars - support both FIREBASE_* and NEXT_PUBLIC_* (Vercel convention)
  const config = {
    firebaseApiKey: process.env.FIREBASE_API_KEY || process.env.NEXT_PUBLIC_FIREBASE_API_KEY || '',
    firebaseAuthDomain: process.env.FIREBASE_AUTH_DOMAIN || 'choice-lux-cars-8d510.firebaseapp.com',
    firebaseProjectId: process.env.FIREBASE_PROJECT_ID || 'choice-lux-cars-8d510',
    firebaseStorageBucket: process.env.FIREBASE_STORAGE_BUCKET || 'choice-lux-cars-8d510.appspot.com',
    firebaseSenderId: process.env.FIREBASE_SENDER_ID || process.env.FIREBASE_MESSAGING_SENDER_ID || '522491134348',
    firebaseAppId: process.env.FIREBASE_APP_ID || '1:522491134348:web:3ac424d68338b3ddb7d6a9',
    googleMapsApiKey: process.env.GOOGLE_MAPS_API_KEY || '',
    supabaseUrl: process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL || '',
    supabaseAnonKey: process.env.SUPABASE_ANON_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
  };

  if (!config.firebaseApiKey) {
    console.warn('Warning: FIREBASE_API_KEY not set - web push notifications may not work');
  }
  if (!config.googleMapsApiKey) {
    console.warn('Warning: GOOGLE_MAPS_API_KEY not set - maps will not work on web');
  }

  // Inject into firebase-messaging-sw.js
  let swContent = fs.readFileSync(serviceWorkerPath, 'utf8');
  swContent = swContent.replace('__FIREBASE_API_KEY__', config.firebaseApiKey);
  swContent = swContent.replace('__FIREBASE_AUTH_DOMAIN__', config.firebaseAuthDomain);
  swContent = swContent.replace('__FIREBASE_PROJECT_ID__', config.firebaseProjectId);
  swContent = swContent.replace('__FIREBASE_STORAGE_BUCKET__', config.firebaseStorageBucket);
  swContent = swContent.replace('__FIREBASE_SENDER_ID__', config.firebaseSenderId);
  swContent = swContent.replace('__FIREBASE_APP_ID__', config.firebaseAppId);
  fs.writeFileSync(serviceWorkerPath, swContent, 'utf8');

  // Inject into index.html (Google Maps + Supabase runtime config)
  if (fs.existsSync(indexPath)) {
    let indexContent = fs.readFileSync(indexPath, 'utf8');
    indexContent = indexContent.replace(/__GOOGLE_MAPS_API_KEY__/g, config.googleMapsApiKey);
    indexContent = indexContent.replace(/__SUPABASE_URL__/g, config.supabaseUrl);
    indexContent = indexContent.replace(/__SUPABASE_ANON_KEY__/g, config.supabaseAnonKey);
    fs.writeFileSync(indexPath, indexContent, 'utf8');
  }

  console.log('✅ Config injected into service worker and index.html');
} catch (err) {
  console.error('Error running inject-firebase-config.js:', err.message);
  process.exit(1);
}
