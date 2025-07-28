import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:choice_lux_cars/features/clients/models/agent.dart';
import 'package:choice_lux_cars/features/clients/providers/clients_provider.dart';

// Provider for agents by client
final agentsByClientProvider = FutureProvider.family<List<Agent>, String>((ref, clientId) async {
  final supabaseService = ref.read(supabaseServiceProvider);
  final agentsData = await supabaseService.getAgentsByClient(clientId);
  return agentsData.map((json) => Agent.fromJson(json)).toList();
});

// Provider for single agent
final agentProvider = FutureProvider.family<Agent?, String>((ref, agentId) async {
  final supabaseService = ref.read(supabaseServiceProvider);
  final agentData = await supabaseService.getAgent(agentId);
  return agentData != null ? Agent.fromJson(agentData) : null;
});

// Notifier for agent operations
class AgentsNotifier extends StateNotifier<AsyncValue<List<Agent>>> {
  final SupabaseService _supabaseService;
  final String _clientId;

  AgentsNotifier(this._supabaseService, this._clientId) : super(const AsyncValue.loading()) {
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    try {
      state = const AsyncValue.loading();
      final agentsData = await _supabaseService.getAgentsByClient(_clientId);
      final agents = agentsData.map((json) => Agent.fromJson(json)).toList();
      state = AsyncValue.data(agents);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addAgent(Agent agent) async {
    try {
      await _supabaseService.createAgent(agent.toJson());
      await _loadAgents(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateAgent(Agent agent) async {
    try {
      await _supabaseService.updateAgent(
        agentId: agent.id.toString(),
        data: agent.toJson(),
      );
      await _loadAgents(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteAgent(String agentId) async {
    try {
      await _supabaseService.deleteAgent(agentId);
      await _loadAgents(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadAgents();
  }
}

// Provider for agents notifier
final agentsNotifierProvider = StateNotifierProvider.family<AgentsNotifier, AsyncValue<List<Agent>>, String>((ref, clientId) {
  final supabaseService = ref.read(supabaseServiceProvider);
  return AgentsNotifier(supabaseService, clientId);
}); 