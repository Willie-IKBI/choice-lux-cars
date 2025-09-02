import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/app/app.dart';
import 'package:choice_lux_cars/core/services/firebase_service.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    Log.d('Initializing Choice Lux Cars app...');
    
    // Initialize Supabase
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    Log.d('Supabase initialized successfully');
    
    // Initialize Firebase (optional, won't crash if fails)
    try {
      await FirebaseService.initialize();
      Log.d('Firebase initialized successfully');
    } catch (error) {
      Log.e('Firebase initialization failed: $error');
      Log.d('Continuing without Firebase...');
    }
    
    Log.d('App initialization completed successfully');
    
    runApp(
      const ProviderScope(
        child: ChoiceLuxCarsApp(),
      ),
    );
  } catch (error) {
    Log.e('Failed to initialize app: $error');
    // Show error screen or fallback
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Failed to initialize app: $error'),
          ),
        ),
      ),
    );
  }
}
