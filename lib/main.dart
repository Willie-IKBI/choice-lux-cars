import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:async';
import 'package:choice_lux_cars/app/app.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:choice_lux_cars/core/services/firebase_service.dart';
import 'package:choice_lux_cars/core/services/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up comprehensive global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
    // Don't show red screen, just log the error
  };
  
  // Handle errors that occur during async operations
  PlatformDispatcher.instance.onError = (error, stack) {
    print('Platform Error: $error');
    print('Stack trace: $stack');
    // Don't show red screen, just log the error
    return true;
  };
  
  try {
    // Initialize Supabase
    await SupabaseService.initialize();
    print('Supabase initialized successfully');
  } catch (error) {
    print('Error initializing Supabase: $error');
    print('Continuing with app initialization...');
    // Continue with app initialization even if Supabase fails
  }

  bool firebaseInitialized = false;
  try {
    // Initialize Firebase
    await FirebaseService.initialize();
    print('Firebase initialized successfully');
    firebaseInitialized = true;
  } catch (error) {
    print('Error initializing Firebase: $error');
    print('Continuing with app initialization without Firebase...');
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
      print('Error setting up Firebase messaging: $error');
      print('Continuing without Firebase messaging...');
    }
  }
  
  runApp(
    const ProviderScope(
      child: ChoiceLuxCarsApp(),
    ),
  );
}
