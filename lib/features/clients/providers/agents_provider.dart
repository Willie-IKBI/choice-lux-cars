import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/clients/clients.dart';

class AgentsNotifier extends FamilyAsyncNotifier<List<Agent>, String> {
  late AgentsRepository _repo;

  @override
  Future<List<Agent>> build(String clientId) async {
    _repo = ref.read(agentsRepositoryProvider);
    return _fetchAgentsByClient(clientId);
  }

  /// Fetch agents by client ID from the repository
  Future<List<Agent>> _fetchAgentsByClient(String clientId) async {
    final result = await _repo.fetchAgentsByClient(clientId);
    if (result.isSuccess) {
      return result.data!;
    } else {
      throw Exception(result.error!.message);
    }
  }

  Future<void> refresh() async {
    final clientId = arg; // family arg
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchAgentsByClient(clientId));
  }

  Future<void> addAgent(Agent agent) async {
    await _repo.createAgent(agent);
    await refresh();
  }

  Future<void> updateAgent(Agent agent) async {
    await _repo.updateAgent(agent);
    await refresh();
  }

  Future<void> deleteAgent(String agentId) async {
    await _repo.deleteAgent(agentId);
    await refresh();
  }
}

final agentsNotifierProvider = AsyncNotifierProvider.family<AgentsNotifier, List<Agent>, String>(
  AgentsNotifier.new,
);

/// Canonical provider for fetching agents by client ID
/// Returns AsyncValue&lt;List&lt;Agent&gt;&gt; for a given client
final agentsForClientProvider = FutureProvider.family<List<Agent>, String>(
  (ref, clientId) async {
    final repository = ref.read(agentsRepositoryProvider);
    final result = await repository.fetchAgentsByClient(clientId);
    if (result.isSuccess) {
      return result.data!;
    } else {
      throw Exception(result.error!.message);
    }
  },
);

/// Compatibility alias for existing call sites
/// @deprecated Use agentsForClientProvider instead
final agentsByClientProvider = agentsForClientProvider;
