import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import 'package:choice_lux_cars/app/app.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:choice_lux_cars/core/services/firebase_service.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up comprehensive global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log error without showing red screen
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };
  
  // Handle errors that occur during async operations
  PlatformDispatcher.instance.onError = (error, stack) {
    // Log error without showing red screen
    debugPrint('Platform Error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };
  
  try {
    // Initialize Supabase
    await SupabaseService.initialize();
    debugPrint('Supabase initialized successfully');
  } catch (error) {
    debugPrint('Error initializing Supabase: $error');
    debugPrint('Continuing with app initialization...');
    // Continue with app initialization even if Supabase fails
  }

  bool firebaseInitialized = false;
  try {
    // Initialize Firebase
    await FirebaseService.initialize();
    debugPrint('Firebase initialized successfully');
    firebaseInitialized = true;
  } catch (error) {
    debugPrint('Error initializing Firebase: $error');
    debugPrint('Continuing with app initialization without Firebase...');
    // Continue with app initialization even if Firebase fails
  }

  // Only set up Firebase messaging if Firebase was successfully initialized
  if (firebaseInitialized) {
    try {
      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(FirebaseService.firebaseMessagingBackgroundHandler);
      
      // Set up Firebase service listeners
      FirebaseService.instance.setupTokenRefreshListener();
      FirebaseService.instance.setupForegroundMessageHandler();
    } catch (error) {
      debugPrint('Error setting up Firebase messaging: $error');
      debugPrint('Continuing without Firebase messaging...');
    }
  }
  
  runApp(
    const ProviderScope(
      child: ChoiceLuxCarsApp(),
    ),
  );
}
