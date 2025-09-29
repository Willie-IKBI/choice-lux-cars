import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/clients/models/client.dart';
import 'package:choice_lux_cars/features/clients/data/clients_repository.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

/// Notifier for managing clients state using AsyncNotifier
class ClientsNotifier extends AsyncNotifier<List<Client>> {
  ClientsRepository get _clientsRepository => ref.watch(clientsRepositoryProvider);

  @override
  Future<List<Client>> build() async {
    return _fetchClients();
  }

  /// Fetch all clients from the repository
  Future<List<Client>> _fetchClients() async {
    try {
      Log.d('Fetching clients...');

      final result = await _clientsRepository.fetchClients();

      if (result.isSuccess) {
        final clients = result.data!;
        Log.d('Fetched ${clients.length} clients successfully');
        return clients;
      } else {
        Log.e('Error fetching clients: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error fetching clients: $error');
      rethrow;
    }
  }

  /// Add a new client
  Future<void> addClient(Client client) async {
    try {
      final result = await _clientsRepository.createClient(client);
      if (result.isSuccess) {
        ref.invalidateSelf(); // Refresh the list
      } else {
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error adding client: $error');
      rethrow;
    }
  }

  /// Update an existing client
  Future<void> updateClient(Client client) async {
    try {
      final result = await _clientsRepository.updateClient(client);
      if (result.isSuccess) {
        ref.invalidateSelf(); // Refresh the list
      } else {
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error updating client: $error');
      rethrow;
    }
  }

  /// Soft delete: Move client to inactive status
  Future<void> deleteClient(String clientId) async {
    try {
      final result = await _clientsRepository.deleteClient(clientId);
      if (result.isSuccess) {
        ref.invalidateSelf(); // Refresh the list
      } else {
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error deleting client: $error');
      rethrow;
    }
  }

  /// Restore inactive client
  Future<void> restoreClient(String clientId) async {
    try {
      final result = await _clientsRepository.restoreClient(clientId);
      if (result.isSuccess) {
        ref.invalidateSelf(); // Refresh the list
      } else {
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error restoring client: $error');
      rethrow;
    }
  }

  /// Permanently delete (use with extreme caution)
  Future<void> permanentlyDeleteClient(String clientId) async {
    try {
      final result = await _clientsRepository.permanentlyDeleteClient(clientId);
      if (result.isSuccess) {
        ref.invalidateSelf(); // Refresh the list
      } else {
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error permanently deleting client: $error');
      rethrow;
    }
  }

  /// Refresh clients data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Notifier for managing inactive clients using AsyncNotifier
class InactiveClientsNotifier extends AsyncNotifier<List<Client>> {
  ClientsRepository get _clientsRepository => ref.watch(clientsRepositoryProvider);

  @override
  Future<List<Client>> build() async {
    return _fetchInactiveClients();
  }

  /// Fetch inactive clients from the repository
  Future<List<Client>> _fetchInactiveClients() async {
    try {
      Log.d('Fetching inactive clients...');

      final result = await _clientsRepository.fetchInactiveClients();

      if (result.isSuccess) {
        final clients = result.data!;
        Log.d('Fetched ${clients.length} inactive clients successfully');
        return clients;
      } else {
        Log.e('Error fetching inactive clients: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error fetching inactive clients: $error');
      rethrow;
    }
  }

  /// Refresh inactive clients data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Notifier for managing client search using FamilyAsyncNotifier
class ClientSearchNotifier extends FamilyAsyncNotifier<List<Client>, String> {
  ClientsRepository get _clientsRepository => ref.watch(clientsRepositoryProvider);

  @override
  Future<List<Client>> build(String query) async {
    if (query.isEmpty) {
      // If query is empty, return all active clients
      final clientsNotifier = ref.read(clientsProvider.notifier);
      return clientsNotifier.state.value ?? [];
    }

    return _searchClients();
  }

  /// Search clients by query
  Future<List<Client>> _searchClients() async {
    try {
      final query = arg;
      Log.d('Searching clients with query: $query');

      final result = await _clientsRepository.searchClients(query);

      if (result.isSuccess) {
        // Filter out inactive clients from search results
        final activeClients = result.data!
            .where((client) => client.status != ClientStatus.inactive)
            .toList();
        Log.d('Found ${activeClients.length} active clients for query: $query');
        return activeClients;
      } else {
        Log.e('Error searching clients: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error searching clients: $error');
      rethrow;
    }
  }

  /// Refresh search results
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Notifier for managing single client using FamilyAsyncNotifier
class SingleClientNotifier extends FamilyAsyncNotifier<Client?, String> {
  ClientsRepository get _clientsRepository => ref.watch(clientsRepositoryProvider);

  @override
  Future<Client?> build(String clientId) async {
    return _fetchClientById(clientId);
  }

  /// Fetch client by ID
  Future<Client?> _fetchClientById(String clientId) async {
    try {
      Log.d('Fetching client by ID: $clientId');

      final result = await _clientsRepository.fetchClientById(clientId);

      if (result.isSuccess) {
        Log.d('Fetched client successfully: ${result.data?.companyName}');
        return result.data;
      } else {
        Log.e('Error fetching client by ID: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error fetching client by ID: $error');
      rethrow;
    }
  }

  /// Refresh client data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Notifier for managing client with agents using FamilyAsyncNotifier
class ClientWithAgentsNotifier
    extends FamilyAsyncNotifier<Map<String, dynamic>?, String> {
  ClientsRepository get _clientsRepository => ref.watch(clientsRepositoryProvider);

  @override
  Future<Map<String, dynamic>?> build(String clientId) async {
    return _fetchClientWithAgents(clientId);
  }

  /// Fetch client with agents
  Future<Map<String, dynamic>?> _fetchClientWithAgents(String clientId) async {
    try {
      Log.d('Fetching client with agents: $clientId');

      final result = await _clientsRepository.fetchClientWithAgents(clientId);

      if (result.isSuccess) {
        Log.d('Fetched client with agents successfully');
        return result.data;
      } else {
        Log.e('Error fetching client with agents: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error fetching client with agents: $error');
      rethrow;
    }
  }

  /// Refresh client with agents data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provider for ClientsNotifier using AsyncNotifierProvider
final clientsProvider = AsyncNotifierProvider<ClientsNotifier, List<Client>>(
  () => ClientsNotifier(),
);

/// Provider for inactive clients using AsyncNotifierProvider
final inactiveClientsProvider =
    AsyncNotifierProvider<InactiveClientsNotifier, List<Client>>(
      () => InactiveClientsNotifier(),
    );

/// Provider for client search using AsyncNotifierProvider.family
final clientSearchProvider =
    AsyncNotifierProvider.family<ClientSearchNotifier, List<Client>, String>(
      ClientSearchNotifier.new,
    );

/// Provider for single client using AsyncNotifierProvider.family
final clientProvider =
    AsyncNotifierProvider.family<SingleClientNotifier, Client?, String>(
      SingleClientNotifier.new,
    );

/// Provider for client with agents using AsyncNotifierProvider.family
final clientWithAgentsProvider =
    AsyncNotifierProvider.family<
      ClientWithAgentsNotifier,
      Map<String, dynamic>?,
      String
    >(ClientWithAgentsNotifier.new);
