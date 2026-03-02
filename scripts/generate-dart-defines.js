const fs = require('fs');
const path = require('path');

// Support both standard and NEXT_PUBLIC_ prefixed names (Vercel convention)
const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL || '';
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';
const firebaseApiKey = process.env.FIREBASE_API_KEY || process.env.NEXT_PUBLIC_FIREBASE_API_KEY || '';
const firebaseVapidKey = process.env.FIREBASE_VAPID_KEY || process.env.NEXT_PUBLIC_FIREBASE_VAPID_KEY || '';
const firebaseAuthDomain = process.env.FIREBASE_AUTH_DOMAIN || process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || 'choice-lux-cars-8d510.firebaseapp.com';
const firebaseProjectId = process.env.FIREBASE_PROJECT_ID || process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || 'choice-lux-cars-8d510';
const firebaseStorageBucket = process.env.FIREBASE_STORAGE_BUCKET || process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || 'choice-lux-cars-8d510.firebasestorage.app';
const firebaseSenderId = process.env.FIREBASE_SENDER_ID || process.env.NEXT_PUBLIC_FIREBASE_SENDER_ID || '522491134348';
const firebaseAppId = process.env.FIREBASE_APP_ID || process.env.NEXT_PUBLIC_FIREBASE_APP_ID || '1:522491134348:android:297f3966013d3d14b7d6a9';

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('ERROR: SUPABASE_URL or SUPABASE_ANON_KEY is empty. Auth will fail with 405.');
  console.error('  Set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY in Vercel env vars.');
  process.exit(1);
}

console.log('Supabase URL configured: ' + supabaseUrl.substring(0, 30) + '...');

const dartDefines = {
  SUPABASE_URL: supabaseUrl,
  SUPABASE_ANON_KEY: supabaseAnonKey,
  FIREBASE_API_KEY: firebaseApiKey,
  FIREBASE_VAPID_KEY: firebaseVapidKey,
  FIREBASE_AUTH_DOMAIN: firebaseAuthDomain,
  FIREBASE_PROJECT_ID: firebaseProjectId,
  FIREBASE_STORAGE_BUCKET: firebaseStorageBucket,
  FIREBASE_SENDER_ID: firebaseSenderId,
  FIREBASE_APP_ID: firebaseAppId,
};

const outPath = path.resolve(__dirname, '../dart_defines.json');
fs.writeFileSync(outPath, JSON.stringify(dartDefines, null, 0), 'utf8');
console.log('Wrote dart_defines.json');
