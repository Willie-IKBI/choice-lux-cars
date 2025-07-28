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
    return await supabase.auth.signUp(
      email: email,
      password: password,
      data: userData,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  // Profile methods
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await supabase
        .from('profiles')
        .update(data)
        .eq('id', userId);
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return response;
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
    await supabase
        .from('profiles')
        .update({'status': 'deactivated', 'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', userId);
  }

  Future<void> reactivateUser(String userId) async {
    await supabase
        .from('profiles')
        .update({'status': 'active', 'deleted_at': null})
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
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getAgent(String agentId) async {
    final response = await supabase
        .from('agents')
        .select()
        .eq('id', agentId)
        .single();
    return response;
  }

  Future<void> createAgent(Map<String, dynamic> agentData) async {
    await supabase
        .from('agents')
        .insert(agentData);
  }

  Future<void> updateAgent({
    required String agentId,
    required Map<String, dynamic> data,
  }) async {
    await supabase
        .from('agents')
        .update(data)
        .eq('id', agentId);
  }

  Future<void> deleteAgent(String agentId) async {
    await supabase
        .from('agents')
        .delete()
        .eq('id', agentId);
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

  Future<Map<String, dynamic>?> getQuote(String quoteId) async {
    final response = await supabase
        .from('quotes')
        .select('*, clients(*), quote_details(*)')
        .eq('id', quoteId)
        .single();
    return response;
  }

  Future<void> createQuote(Map<String, dynamic> quoteData) async {
    await supabase
        .from('quotes')
        .insert(quoteData);
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

  // Job methods
  Future<List<Map<String, dynamic>>> getJobs() async {
    final response = await supabase
        .from('jobs')
        .select('*, quotes(*), clients(*), vehicles(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getJob(String jobId) async {
    final response = await supabase
        .from('jobs')
        .select('*, quotes(*), clients(*), vehicles(*)')
        .eq('id', jobId)
        .single();
    return response;
  }

  Future<void> createJob(Map<String, dynamic> jobData) async {
    await supabase
        .from('jobs')
        .insert(jobData);
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

  // Vehicle CRUD operations
  static Future<List<Vehicle>> getVehicles() async {
    try {
      final response = await supabase
          .from('vehicles')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => Vehicle.fromJson(json)).toList();
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