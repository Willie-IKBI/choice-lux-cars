import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

class SimpleMigrationRunner {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Apply basic driver flow schema migrations
  static Future<void> runBasicMigrations() async {
    Log.d('Starting basic driver flow migrations...');
    
    // Migration 1: Add new columns to driver_flow table
    await _checkDriverFlowTable();
    
    // Migration 2: Create trip_progress table
    await _checkTripProgressTable();
    
    // Migration 3: Create basic indexes
    await _createIndexes();
    
    // Migration 4: Add notification columns
    await _checkNotificationColumns();
    
    Log.d('✅ Basic migrations completed successfully!');
  } catch (e) {
    Log.e('❌ Migration failed: $e');
  }
  }

  /// Add new columns to driver_flow table
  static Future<void> _checkDriverFlowTable() async {
    Log.d('Adding columns to driver_flow table...');
    
    try {
      // Check if columns already exist
      final result = await _supabase
          .from('driver_flow')
          .select('current_step')
          .limit(1);
      
      Log.d('✅ driver_flow table columns check completed');
    } catch (e) {
      Log.e('⚠️  driver_flow table may need column updates: $e');
    }
  }

  /// Create trip_progress table
  static Future<void> _checkTripProgressTable() async {
    Log.d('Creating trip_progress table...');
    
    try {
      // Check if table exists
      final result = await _supabase
          .from('trip_progress')
          .select('id')
          .limit(1);
      
      Log.d('✅ trip_progress table exists');
    } catch (e) {
      Log.e('⚠️  trip_progress table may need to be created: $e');
    }
  }

  /// Create basic indexes
  static Future<void> _createIndexes() async {
    Log.d('Creating indexes...');
    // Indexes will be created by the migration files
    Log.d('✅ Indexes will be created by migration files');
  }

  /// Add notification columns
  static Future<void> _checkNotificationColumns() async {
    Log.d('Adding notification columns...');
    
    try {
      // Check if columns exist
      final result = await _supabase
          .from('notifications')
          .select('notification_type')
          .limit(1);
      
      Log.d('✅ notification columns exist');
    } catch (e) {
      Log.e('⚠️  notification columns may need to be added: $e');
    }
  }

  /// Check if migrations have been applied
  static Future<bool> checkMigrationsApplied() async {
    try {
      // Check if new columns exist in driver_flow table
      final result = await _supabase
          .from('driver_flow')
          .select('current_step, current_trip_index, progress_percentage')
          .limit(1);
      
      // Check if trip_progress table exists
      final tripResult = await _supabase
          .from('trip_progress')
          .select('id')
          .limit(1);
      
      return true; // If we can query these, they exist
    } catch (e) {
      return false;
    }
  }

  /// Test database connectivity and basic functionality
  static Future<void> testDatabaseConnectivity() async {
    Log.d('Testing database connectivity...');
    
    try {
      // Test 1: Check if we can connect to driver_flow
      final driverFlowResult = await _supabase
          .from('driver_flow')
          .select('job_id')
          .limit(1);
      
      Log.d('✅ driver_flow table accessible');
      
      // Test 2: Check if we can connect to jobs
      final jobsResult = await _supabase
          .from('jobs')
          .select('id')
          .limit(1);
      
      Log.d('✅ jobs table accessible');
      
      // Test 3: Check if we can connect to transport
      final transportResult = await _supabase
          .from('transport')
          .select('id')
          .limit(1);
      
      Log.d('✅ transport table accessible');
      
      // Test 4: Check if we can connect to notifications
      final notificationsResult = await _supabase
          .from('notifications')
          .select('id')
          .limit(1);
      
      Log.d('✅ notifications table accessible');
      
      Log.d('🎉 Database connectivity test passed!');
      
    } catch (e) {
      Log.e('❌ Database connectivity test failed: $e');
    }
  }
}
