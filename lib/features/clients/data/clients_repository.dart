import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:choice_lux_cars/core/supabase/supabase_client_provider.dart';
import 'package:choice_lux_cars/features/clients/models/client.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/types/result.dart';
import 'package:choice_lux_cars/core/errors/app_exception.dart';

/// Repository for client-related data operations
///
/// Encapsulates all Supabase queries and returns domain models.
/// This layer separates data access from business logic.
class ClientsRepository {
  final SupabaseClient _supabase;

  ClientsRepository(this._supabase);

  /// Fetch all clients from the database
  Future<Result<List<Client>>> fetchClients() async {
    try {
      Log.d('Fetching clients from database');

      final response = await _supabase
          .from('clients')
          .select()
          .order('company_name', ascending: true);

      Log.d('Fetched ${response.length} clients from database');

      final clients = response.map((json) => Client.fromJson(json)).toList();
      return Result.success(clients);
    } catch (error) {
      Log.e('Error fetching clients: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch a single client by ID
  Future<Result<Client?>> fetchClientById(String clientId) async {
    try {
      Log.d('Fetching client by ID: $clientId');

      final response = await _supabase
          .from('clients')
          .select()
          .eq('id', clientId)
          .maybeSingle();

      if (response != null) {
        Log.d('Client found: ${response['company_name']}');
        return Result.success(Client.fromJson(response));
      } else {
        Log.d('Client not found');
        return const Result.success(null);
      }
    } catch (error) {
      Log.e('Error fetching client by ID: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Create a new client
  Future<Result<Map<String, dynamic>>> createClient(Client client) async {
    try {
      Log.d('Creating client: ${client.companyName}');

      final clientData = client.toJson();
      // Ensure any nullable fields are properly handled
      if (clientData['status'] == null) {
        clientData['status'] = 'active';
      }


      final response = await _supabase
          .from('clients')
          .insert(clientData)
          .select()
          .single();

      Log.d('Client created successfully with ID: ${response['id']}');
      return Result.success(response);
    } catch (error) {
      Log.e('Error creating client: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Update an existing client
  Future<Result<void>> updateClient(Client client) async {
    try {
      Log.d('Updating client: ${client.id}');

      if (client.id == null) {
        return const Result.failure(
          UnknownException('Client ID is required for update'),
        );
      }

      final clientData = client.toJson();

      await _supabase
          .from('clients')
          .update(clientData)
          .eq('id', client.id!);

      Log.d('Client updated successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error updating client: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Delete a client
  Future<Result<void>> deleteClient(String clientId) async {
    try {
      Log.d('Deleting client: $clientId');

      await _supabase.from('clients').delete().eq('id', clientId);

      Log.d('Client deleted successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error deleting client: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get client by ID
  Future<Result<Client?>> getClientById(String clientId) async {
    try {
      Log.d('Fetching client by ID: $clientId');

      final response = await _supabase
          .from('clients')
          .select()
          .eq('id', clientId)
          .maybeSingle();

      if (response != null) {
        Log.d('Client found: ${response['company_name']}');
        return Result.success(Client.fromJson(response));
      } else {
        Log.d('Client not found: $clientId');
        return const Result.success(null);
      }
    } catch (error) {
      Log.e('Error fetching client by ID: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Search clients by company name, contact person, website, registration number, or VAT number
  Future<Result<List<Client>>> searchClients(String query) async {
    try {
      Log.d('Searching clients with query: $query');

      final response = await _supabase
          .from('clients')
          .select()
          .or('company_name.ilike.%$query%,contact_person.ilike.%$query%,website_address.ilike.%$query%,company_registration_number.ilike.%$query%,vat_number.ilike.%$query%')
          .order('company_name', ascending: true);

      Log.d('Found ${response.length} clients matching query: $query');

      final clients = response.map((json) => Client.fromJson(json)).toList();
      return Result.success(clients);
    } catch (error) {
      Log.e('Error searching clients: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch inactive clients
  Future<Result<List<Client>>> fetchInactiveClients() async {
    try {
      Log.d('Fetching inactive clients');

      final response = await _supabase
          .from('clients')
          .select()
          .eq('status', 'inactive')
          .order('company_name', ascending: true);

      Log.d('Fetched ${response.length} inactive clients');

      final clients = response.map((json) => Client.fromJson(json)).toList();
      return Result.success(clients);
    } catch (error) {
      Log.e('Error fetching inactive clients: $error');
      return _mapSupabaseError(error);
    }
  }


  /// Fetch client with agents
  Future<Result<Map<String, dynamic>?>> fetchClientWithAgents(
    String clientId,
  ) async {
    try {
      Log.d('Fetching client with agents: $clientId');

      final clientResponse = await _supabase
          .from('clients')
          .select()
          .eq('id', clientId)
          .maybeSingle();

      if (clientResponse == null) {
        Log.d('Client not found: $clientId');
        return const Result.success(null);
      }

      final agentsResponse = await _supabase
          .from('agents')
          .select()
          .eq('client_key', clientId)
          .eq('is_deleted', false)
          .order('agent_name', ascending: true);

      final result = {
        'client': Client.fromJson(clientResponse),
        'agents': agentsResponse.map((json) => json).toList(),
      };

      Log.d('Fetched client with ${agentsResponse.length} agents');
      return Result.success(result);
    } catch (error) {
      Log.e('Error fetching client with agents: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Restore inactive client
  Future<Result<void>> restoreClient(String clientId) async {
    try {
      Log.d('Restoring client: $clientId');

      await _supabase
          .from('clients')
          .update({'status': 'active'})
          .eq('id', clientId);

      Log.d('Client restored successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error restoring client: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Permanently delete client
  Future<Result<void>> permanentlyDeleteClient(String clientId) async {
    try {
      Log.d('Permanently deleting client: $clientId');

      await _supabase.from('clients').delete().eq('id', clientId);

      Log.d('Client permanently deleted successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error permanently deleting client: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Map Supabase errors to appropriate AppException types
  Result<T> _mapSupabaseError<T>(dynamic error) {
    if (error is AuthException) {
      return Result.failure(AuthException(error.message));
    } else if (error is PostgrestException) {
      // Check if it's a network-related error
      if (error.message.contains('network') ||
          error.message.contains('timeout') ||
          error.message.contains('connection')) {
        return Result.failure(NetworkException(error.message));
      }
      // Check if it's an auth-related error
      if (error.message.contains('JWT') ||
          error.message.contains('unauthorized') ||
          error.message.contains('forbidden')) {
        return Result.failure(AuthException(error.message));
      }
      return Result.failure(UnknownException(error.message));
    } else if (error is StorageException) {
      if (error.message.contains('network') ||
          error.message.contains('timeout')) {
        return Result.failure(NetworkException(error.message));
      }
      return Result.failure(UnknownException(error.message));
    } else {
      return Result.failure(UnknownException(error.toString()));
    }
  }
}

/// Provider for ClientsRepository
final clientsRepositoryProvider = Provider<ClientsRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ClientsRepository(supabase);
});
