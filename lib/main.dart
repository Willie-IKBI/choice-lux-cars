import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/app/app.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:choice_lux_cars/core/services/firebase_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Supabase
    await SupabaseService.initialize();
    print('Supabase initialized successfully');
  } catch (error) {
    print('Error initializing Supabase: $error');
    print('Continuing with app initialization...');
    // Continue with app initialization even if Supabase fails
  }

  try {
    // Initialize Firebase
    await FirebaseService.initialize();
    print('Firebase initialized successfully');
    
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(FirebaseService.firebaseMessagingBackgroundHandler);
    
    // Set up Firebase service listeners
    FirebaseService.instance.setupTokenRefreshListener();
    FirebaseService.instance.setupForegroundMessageHandler();
    
  } catch (error) {
    print('Error initializing Firebase: $error');
    print('Continuing with app initialization without Firebase...');
    // Continue with app initialization even if Firebase fails
  }
  
  runApp(
    const ProviderScope(
      child: ChoiceLuxCarsApp(),
    ),
  );
}
