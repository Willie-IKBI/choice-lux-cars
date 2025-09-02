import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/clients/models/agent.dart';
import 'package:choice_lux_cars/features/clients/services/agents_repository.dart';

class AgentsNotifier extends FamilyAsyncNotifier<List<Agent>, String> {
  late AgentsRepository _repo;

  @override
  Future<List<Agent>> build(String clientId) async {
    _repo = ref.read(agentsRepositoryProvider);
    return _repo.fetchAgentsByClient(clientId);
  }

  Future<void> refresh() async {
    final clientId = arg; // family arg
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.fetchAgentsByClient(clientId));
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
    return repository.fetchAgentsByClient(clientId);
  },
);

/// Compatibility alias for existing call sites
/// @deprecated Use agentsForClientProvider instead
final agentsByClientProvider = agentsForClientProvider;
