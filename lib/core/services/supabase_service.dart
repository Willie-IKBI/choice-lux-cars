import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/core/constants.dart';
import '../../features/vehicles/models/vehicle.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static final supabase = Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );
      print('Supabase client initialized with URL: ${AppConstants.supabaseUrl}');
    } catch (error) {
      print('Failed to initialize Supabase: $error');
      rethrow;
    }
  }

  // Authentication methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    try {
      return await supabase.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
    } catch (error) {
      print('Supabase signUp error: $error');
      // Return the error as a string instead of re-throwing
      throw error.toString();
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (error) {
      print('Supabase signIn error: $error');
      // Return the error as a string instead of re-throwing
      throw error.toString();
    }
  }

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (error) {
      print('Supabase signOut error: $error');
      throw error.toString();
    }
  }

  // Forgot password methods
  Future<void> resetPassword({required String email}) async {
    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://choice-lux-cars-8d510.web.app/reset-password', // Firebase deployed URL
      );
    } catch (error) {
      print('Supabase resetPassword error: $error');
      throw error.toString();
    }
  }

  Future<void> updatePassword({required String newPassword}) async {
    try {
      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (error) {
      print('Supabase updatePassword error: $error');
      throw error.toString();
    }
  }

  User? get currentUser => supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  // Profile methods
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await supabase
          .from('profiles')
          .update(data)
          .eq('id', userId);
    } catch (error) {
      print('Supabase updateProfile error: $error');
      throw error.toString();
    }
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (error) {
      print('Supabase getProfile error: $error');
      throw error.toString();
    }
  }

  Future<void> updateUser({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await supabase
        .from('profiles')
        .update(data)
        .eq('id', userId);
  }

  Future<void> deactivateUser(String userId) async {
    print('SupabaseService.deactivateUser called for userId: $userId');
    try {
      await supabase
          .from('profiles')
          .update({'status': 'deactivated'})
          .eq('id', userId);
      print('Supabase deactivateUser query completed successfully');
    } catch (error) {
      print('Error in SupabaseService.deactivateUser: $error');
      rethrow;
    }
  }

  Future<void> reactivateUser(String userId) async {
    await supabase
        .from('profiles')
        .update({'status': 'active'})
        .eq('id', userId);
  }

  // User management methods
  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await supabase
        .from('profiles')
        .select()
        .order('display_name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // Client methods
  Future<List<Map<String, dynamic>>> getClients() async {
    final response = await supabase
        .from('clients')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getClient(String clientId) async {
    final response = await supabase
        .from('clients')
        .select()
        .eq('id', clientId)
        .single();
    return response;
  }

  Future<void> createClient(Map<String, dynamic> clientData) async {
    await supabase
        .from('clients')
        .insert(clientData);
  }

  Future<void> updateClient({
    required String clientId,
    required Map<String, dynamic> data,
  }) async {
    await supabase
        .from('clients')
        .update(data)
        .eq('id', clientId);
  }

  Future<void> deleteClient(String clientId) async {
    // Soft delete: Update status to inactive instead of hard delete
    await supabase
        .from('clients')
        .update({'status': 'inactive', 'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', clientId);
  }

  // New method to permanently delete (use with caution)
  Future<void> permanentlyDeleteClient(String clientId) async {
    await supabase
        .from('clients')
        .delete()
        .eq('id', clientId);
  }

  // Get only active clients
  Future<List<Map<String, dynamic>>> getActiveClients() async {
    final response = await supabase
        .from('clients')
        .select()
        .neq('status', 'inactive')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get inactive clients
  Future<List<Map<String, dynamic>>> getInactiveClients() async {
    final response = await supabase
        .from('clients')
        .select()
        .eq('status', 'inactive')
        .order('deleted_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Restore inactive client
  Future<void> restoreClient(String clientId) async {
    await supabase
        .from('clients')
        .update({'status': 'active', 'deleted_at': null})
        .eq('id', clientId);
  }

  // Agent methods
  Future<List<Map<String, dynamic>>> getAgentsByClient(String clientId) async {
    final response = await supabase
        .from('agents')
        .select()
        .eq('client_key', clientId)
        .eq('is_deleted', false) // Only get non-deleted agents
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getAgent(String agentId) async {
    try {
      final response = await supabase
          .from('agents')
          .select()
          .eq('id', int.parse(agentId))
          .eq('is_deleted', false) // Only get non-deleted agents
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createAgent(Map<String, dynamic> agentData) async {
    try {
      final response = await supabase
          .from('agents')
          .insert(agentData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('createAgent error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateAgent({
    required String agentId,
    required Map<String, dynamic> data,
  }) async {
    final response = await supabase
        .from('agents')
        .update(data)
        .eq('id', int.parse(agentId))
        .select()
        .single();
    return response;
  }

  Future<void> deleteAgent(String agentId) async {
    // Soft delete: mark as deleted instead of actually deleting
    await supabase
        .from('agents')
        .update({'is_deleted': true})
        .eq('id', int.parse(agentId));
  }

  // Enhanced client methods
  Future<Map<String, dynamic>?> getClientWithAgents(String clientId) async {
    final response = await supabase
        .from('clients')
        .select('*, agents(*)')
        .eq('id', clientId)
        .single();
    return response;
  }

  Future<List<Map<String, dynamic>>> searchClients(String query) async {
    final response = await supabase
        .from('clients')
        .select()
        .or('company_name.ilike.%$query%,contact_person.ilike.%$query%')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Quote methods
  Future<List<Map<String, dynamic>>> getQuotes() async {
    final response = await supabase
        .from('quotes')
        .select('*, clients(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get quotes by client
  Future<List<Map<String, dynamic>>> getQuotesByClient(String clientId) async {
    final response = await supabase
        .from('quotes')
        .select('*, clients(*)')
        .eq('client_id', int.parse(clientId))
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getQuote(String quoteId) async {
    final response = await supabase
        .from('quotes')
        .select('*, clients(*)')
        .eq('id', quoteId)
        .single();
    return response;
  }

  Future<Map<String, dynamic>> createQuote(Map<String, dynamic> quoteData) async {
    final response = await supabase
        .from('quotes')
        .insert(quoteData)
        .select()
        .single();
    return response;
  }

  Future<void> updateQuote({
    required String quoteId,
    required Map<String, dynamic> data,
  }) async {
    await supabase
        .from('quotes')
        .update(data)
        .eq('id', quoteId);
  }

  Future<void> deleteQuote(String quoteId) async {
    await supabase
        .from('quotes')
        .delete()
        .eq('id', quoteId);
  }

  Future<List<Map<String, dynamic>>> getQuotesByUser(String userId) async {
    final response = await supabase
        .from('quotes')
        .select('*, clients(*)')
        .eq('created_by', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Quote transport detail methods
  Future<List<Map<String, dynamic>>> getQuoteTransportDetails(String quoteId) async {
    final response = await supabase
        .from('quotes_transport_details')
        .select('*')
        .eq('quote_id', quoteId)
        .order('pickup_date', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createQuoteTransportDetail(Map<String, dynamic> transportData) async {
    await supabase
        .from('quotes_transport_details')
        .insert(transportData);
  }

  Future<void> updateQuoteTransportDetail({
    required String transportDetailId,
    required Map<String, dynamic> data,
  }) async {
    await supabase
        .from('quotes_transport_details')
        .update(data)
        .eq('id', transportDetailId);
  }

  Future<void> deleteQuoteTransportDetail(String transportDetailId) async {
    await supabase
        .from('quotes_transport_details')
        .delete()
        .eq('id', transportDetailId);
  }

  // Job methods
  Future<List<Map<String, dynamic>>> getJobs() async {
    final response = await supabase
        .from('jobs')
        .select('*')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get jobs by client
  Future<List<Map<String, dynamic>>> getJobsByClient(String clientId) async {
    final response = await supabase
        .from('jobs')
        .select('*')
        .eq('client_id', int.parse(clientId))
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get completed jobs by client
  Future<List<Map<String, dynamic>>> getCompletedJobsByClient(String clientId) async {
    final response = await supabase
        .from('jobs')
        .select('*')
        .eq('client_id', int.parse(clientId))
        .eq('job_status', 'completed')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get completed jobs revenue by client
  Future<double> getCompletedJobsRevenueByClient(String clientId) async {
    final response = await supabase
        .from('jobs')
        .select('amount')
        .eq('client_id', int.parse(clientId))
        .eq('job_status', 'completed');
    
    if (response == null || response.isEmpty) return 0.0;
    
    double totalRevenue = 0.0;
    for (final job in response) {
      final amount = job['amount'];
      if (amount != null) {
        totalRevenue += (amount is int) ? amount.toDouble() : amount;
      }
    }
    return totalRevenue;
  }

  Future<List<Map<String, dynamic>>> getJobsByDriver(String driverId) async {
    final response = await supabase
        .from('jobs')
        .select('*')
        .eq('driver_id', driverId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getJobsByDriverManager(String driverManagerId) async {
    final response = await supabase
        .from('jobs')
        .select('*')
        .or('created_by.eq.$driverManagerId,driver_id.eq.$driverManagerId')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getJob(String jobId) async {
    final response = await supabase
        .from('jobs')
        .select('*')
        .eq('id', jobId)
        .single();
    return response;
  }

  Future<Map<String, dynamic>> createJob(Map<String, dynamic> jobData) async {
    final response = await supabase
        .from('jobs')
        .insert(jobData)
        .select()
        .single();
    return response;
  }

  Future<void> updateJob({
    required String jobId,
    required Map<String, dynamic> data,
  }) async {
    await supabase
        .from('jobs')
        .update(data)
        .eq('id', jobId);
  }

  Future<void> deleteJob(String jobId) async {
    await supabase
        .from('jobs')
        .delete()
        .eq('id', jobId);
  }

  // Trip methods (using transport table)
  Future<List<Map<String, dynamic>>> getTripsByJob(String jobId) async {
    final response = await supabase
        .from('transport')
        .select('*')
        .eq('job_id', jobId)
        .order('pickup_date', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getTrip(String tripId) async {
    final response = await supabase
        .from('transport')
        .select('*')
        .eq('id', tripId)
        .single();
    return response;
  }

  Future<void> createTrip(Map<String, dynamic> tripData) async {
    await supabase
        .from('transport')
        .insert(tripData);
  }

  Future<void> updateTrip({
    required String tripId,
    required Map<String, dynamic> data,
  }) async {
    await supabase
        .from('transport')
        .update(data)
        .eq('id', tripId);
  }

  Future<void> deleteTrip(String tripId) async {
    await supabase
        .from('transport')
        .delete()
        .eq('id', tripId);
  }

  // Vehicle CRUD operations
  static Future<List<Vehicle>> getVehicles() async {
    try {
      final response = await supabase
          .from('vehicles')
          .select()
          .order('created_at', ascending: false);
      
      final vehicles = (response as List).map((json) => Vehicle.fromJson(json)).toList();
      
      return vehicles;
    } catch (e) {
      throw Exception('Failed to fetch vehicles: $e');
    }
  }

  static Future<Vehicle> createVehicle(Vehicle vehicle) async {
    try {
      final response = await supabase
          .from('vehicles')
          .insert(vehicle.toJson())
          .select()
          .single();
      
      return Vehicle.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create vehicle: $e');
    }
  }

  static Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    try {
      final response = await supabase
          .from('vehicles')
          .update(vehicle.toJson())
          .eq('id', vehicle.id ?? 0)
          .select()
          .single();
      
      return Vehicle.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update vehicle: $e');
    }
  }

  Future<Map<String, dynamic>?> getVehicle(String vehicleId) async {
    try {
      final response = await supabase
          .from('vehicles')
          .select('*')
          .eq('id', vehicleId)
          .single();
      return response;
    } catch (e) {
      print('Error getting vehicle: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Invoice methods
  Future<List<Map<String, dynamic>>> getInvoices() async {
    final response = await supabase
        .from('invoices')
        .select('*, jobs(*), clients(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getInvoice(String invoiceId) async {
    final response = await supabase
        .from('invoices')
        .select('*, jobs(*), clients(*)')
        .eq('id', invoiceId)
        .single();
    return response;
  }

  Future<void> createInvoice(Map<String, dynamic> invoiceData) async {
    await supabase
        .from('invoices')
        .insert(invoiceData);
  }

  Future<void> updateInvoice({
    required String invoiceId,
    required Map<String, dynamic> data,
  }) async {
    await supabase
        .from('invoices')
        .update(data)
        .eq('id', invoiceId);
  }

  // Storage methods
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    await supabase.storage
        .from(bucket)
        .uploadBinary(path, bytes, fileOptions: FileOptions(
          contentType: contentType,
        ));

    return supabase.storage
        .from(bucket)
        .getPublicUrl(path);
  }

  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    await supabase.storage
        .from(bucket)
        .remove([path]);
  }

  Future<List<FileObject>> listFiles({
    required String bucket,
    String? folder,
  }) async {
    return await supabase.storage
        .from(bucket)
        .list(path: folder ?? '');
  }

  // Real-time subscriptions (to be implemented)
  // RealtimeChannel subscribeToTable({
  //   required String table,
  //   required String event,
  //   required Function(Map<String, dynamic>) callback,
  // }) {
  //   // TODO: Implement real-time subscriptions
  //   throw UnimplementedError('Real-time subscriptions not yet implemented');
  // }
} 