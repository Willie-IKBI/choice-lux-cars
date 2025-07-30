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
      print('Agents loaded: ${agents.map((a) => '${a.agentName} (ID: ${a.id})').join(', ')}');
      state = AsyncValue.data(agents);
    } catch (error, stackTrace) {
      print('Error loading agents: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addAgent(Agent agent) async {
    try {
      print('addAgent called with agent: ${agent.agentName}, id: ${agent.id}');
      final createdAgentData = await _supabaseService.createAgent(agent.toJson());
      print('addAgent - created agent data: $createdAgentData');
      
      // Create a new agent object with the database-assigned ID
      final createdAgent = Agent.fromJson(createdAgentData);
      print('addAgent - created agent object: ${createdAgent.agentName}, id: ${createdAgent.id}');
      
      // Update the current state to include the new agent
      final currentAgents = state.value ?? [];
      final updatedAgents = [createdAgent, ...currentAgents];
      state = AsyncValue.data(updatedAgents);
    } catch (error, stackTrace) {
      print('addAgent error: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateAgent(Agent agent) async {
    try {
      print('updateAgent called with agent: ${agent.agentName}, id: ${agent.id}');
      final updatedAgentData = await _supabaseService.updateAgent(
        agentId: agent.id.toString(),
        data: agent.toJson(),
      );
      print('updateAgent - updated agent data: $updatedAgentData');
      
      // Create an updated agent object
      final updatedAgent = Agent.fromJson(updatedAgentData);
      print('updateAgent - updated agent object: ${updatedAgent.agentName}, id: ${updatedAgent.id}');
      
      // Update the current state to replace the old agent with the updated one
      final currentAgents = state.value ?? [];
      final updatedAgents = currentAgents.map((a) => a.id == agent.id ? updatedAgent : a).toList();
      state = AsyncValue.data(updatedAgents);
    } catch (error, stackTrace) {
      print('updateAgent error: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteAgent(String agentId) async {
    try {
      print('deleteAgent called with agentId: $agentId');
      await _supabaseService.deleteAgent(agentId);
      
      // Update the current state to remove the soft-deleted agent
      final currentAgents = state.value ?? [];
      final updatedAgents = currentAgents.where((a) => a.id.toString() != agentId).toList();
      print('deleteAgent - updated agents list: ${updatedAgents.map((a) => '${a.agentName} (ID: ${a.id})').join(', ')}');
      state = AsyncValue.data(updatedAgents);
    } catch (error, stackTrace) {
      print('deleteAgent error: $error');
      // Don't update the state on error - keep the current agent list
      // The error will be handled by the UI layer (e.g., showing a snackbar)
      rethrow; // Re-throw the error so the UI can handle it
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