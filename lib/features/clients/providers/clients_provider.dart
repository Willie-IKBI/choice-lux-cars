import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:choice_lux_cars/features/clients/models/client.dart';

// Provider for SupabaseService
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService.instance;
});

// Provider for clients list (active only)
final clientsProvider = FutureProvider<List<Client>>((ref) async {
  final supabaseService = ref.read(supabaseServiceProvider);
  final clientsData = await supabaseService.getActiveClients();
  return clientsData.map((json) => Client.fromJson(json)).toList();
});

// Provider for inactive clients
final inactiveClientsProvider = FutureProvider<List<Client>>((ref) async {
  final supabaseService = ref.read(supabaseServiceProvider);
  final clientsData = await supabaseService.getInactiveClients();
  return clientsData.map((json) => Client.fromJson(json)).toList();
});

// Provider for client search (active only)
final clientSearchProvider = FutureProvider.family<List<Client>, String>((ref, query) async {
  if (query.isEmpty) {
    return ref.read(clientsProvider).value ?? [];
  }
  final supabaseService = ref.read(supabaseServiceProvider);
  final clientsData = await supabaseService.searchClients(query);
  // Filter out inactive clients from search results
  final activeClients = clientsData
      .where((json) => json['status'] != 'inactive')
      .map((json) => Client.fromJson(json))
      .toList();
  return activeClients;
});

// Provider for single client
final clientProvider = FutureProvider.family<Client?, String>((ref, clientId) async {
  final supabaseService = ref.read(supabaseServiceProvider);
  final clientData = await supabaseService.getClient(clientId);
  return clientData != null ? Client.fromJson(clientData) : null;
});

// Provider for client with agents
final clientWithAgentsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, clientId) async {
  final supabaseService = ref.read(supabaseServiceProvider);
  return await supabaseService.getClientWithAgents(clientId);
});

// Notifier for client operations
class ClientsNotifier extends StateNotifier<AsyncValue<List<Client>>> {
  final SupabaseService _supabaseService;

  ClientsNotifier(this._supabaseService) : super(const AsyncValue.loading()) {
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      state = const AsyncValue.loading();
      final clientsData = await _supabaseService.getActiveClients();
      final clients = clientsData.map((json) => Client.fromJson(json)).toList();
      state = AsyncValue.data(clients);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addClient(Client client) async {
    try {
      await _supabaseService.createClient(client.toJson());
      await _loadClients(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateClient(Client client) async {
    try {
      await _supabaseService.updateClient(
        clientId: client.id.toString(),
        data: client.toJson(),
      );
      await _loadClients(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Soft delete: Move client to inactive status
  Future<void> deleteClient(String clientId) async {
    try {
      await _supabaseService.deleteClient(clientId); // This now does soft delete
      await _loadClients(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Restore inactive client
  Future<void> restoreClient(String clientId) async {
    try {
      await _supabaseService.restoreClient(clientId);
      await _loadClients(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Permanently delete (use with extreme caution)
  Future<void> permanentlyDeleteClient(String clientId) async {
    try {
      await _supabaseService.permanentlyDeleteClient(clientId);
      await _loadClients(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadClients();
  }
}

// Provider for clients notifier
final clientsNotifierProvider = StateNotifierProvider<ClientsNotifier, AsyncValue<List<Client>>>((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  return ClientsNotifier(supabaseService);
}); 