import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/clients/data/agents_repository.dart';
import 'package:choice_lux_cars/features/clients/models/agent.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

/// Notifier for managing agents by client using FamilyAsyncNotifier
class AgentsByClientNotifier extends FamilyAsyncNotifier<List<Agent>, String> {
  late final AgentsRepository _agentsRepository;
  late final String clientId;

  @override
  Future<List<Agent>> build(String clientId) async {
    _agentsRepository = ref.watch(agentsRepositoryProvider);
    this.clientId = clientId;
    return _fetchAgentsByClient();
  }

  /// Fetch agents by client from the repository
  Future<List<Agent>> _fetchAgentsByClient() async {
    try {
      Log.d('Fetching agents for client: $clientId');
      
      final result = await _agentsRepository.fetchAgentsByClient(clientId);
      
      if (result.isSuccess) {
        final agents = result.data!;
        Log.d('Fetched ${agents.length} agents for client: $clientId');
        return agents;
      } else {
        Log.e('Error fetching agents by client: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error fetching agents by client: $error');
      rethrow;
    }
  }

  /// Add a new agent
  Future<void> addAgent(Agent agent) async {
    try {
      Log.d('addAgent called with agent: ${agent.agentName}, id: ${agent.id}');
      
      final result = await _agentsRepository.createAgent(agent);
      
      if (result.isSuccess) {
        final createdAgentData = result.data!;
        final createdAgent = Agent.fromJson(createdAgentData);
        Log.d('addAgent - created agent object: ${createdAgent.agentName}, id: ${createdAgent.id}');
        
        // Update the current state to include the new agent
        final currentAgents = state.value ?? [];
        final updatedAgents = [createdAgent, ...currentAgents];
        state = AsyncValue.data(updatedAgents);
      } else {
        Log.e('addAgent error: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('addAgent error: $error');
      rethrow;
    }
  }

  /// Update an existing agent
  Future<void> updateAgent(Agent agent) async {
    try {
      Log.d('updateAgent called with agent: ${agent.agentName}, id: ${agent.id}');
      
      final result = await _agentsRepository.updateAgent(agent);
      
      if (result.isSuccess) {
        Log.d('updateAgent - agent updated successfully: ${agent.agentName}, id: ${agent.id}');
        
        // Update the current state to replace the old agent with the updated one
        final currentAgents = state.value ?? [];
        final updatedAgents = currentAgents.map((a) => a.id == agent.id ? agent : a).toList();
        state = AsyncValue.data(updatedAgents);
      } else {
        Log.e('updateAgent error: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('updateAgent error: $error');
      rethrow;
    }
  }

  /// Delete an agent
  Future<void> deleteAgent(String agentId) async {
    try {
      Log.d('deleteAgent called with agentId: $agentId');
      
      final result = await _agentsRepository.deleteAgent(agentId);
      
      if (result.isSuccess) {
        // Update the current state to remove the soft-deleted agent
        final currentAgents = state.value ?? [];
        final updatedAgents = currentAgents.where((a) => a.id.toString() != agentId).toList();
        Log.d('deleteAgent - updated agents list: ${updatedAgents.map((a) => '${a.agentName} (ID: ${a.id})').join(', ')}');
        state = AsyncValue.data(updatedAgents);
      } else {
        Log.e('deleteAgent error: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('deleteAgent error: $error');
      // Don't update the state on error - keep the current agent list
      // The error will be handled by the UI layer (e.g., showing a snackbar)
      rethrow; // Re-throw the error so the UI can handle it
    }
  }

  /// Refresh agents data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Notifier for managing single agent using FamilyAsyncNotifier
class SingleAgentNotifier extends FamilyAsyncNotifier<Agent?, String> {
  late final AgentsRepository _agentsRepository;
  late final String agentId;

  @override
  Future<Agent?> build(String agentId) async {
    _agentsRepository = ref.watch(agentsRepositoryProvider);
    this.agentId = agentId;
    return _fetchAgentById();
  }

  /// Fetch agent by ID
  Future<Agent?> _fetchAgentById() async {
    try {
      Log.d('Fetching agent by ID: $agentId');
      
      final result = await _agentsRepository.fetchAgentById(agentId);
      
      if (result.isSuccess) {
        Log.d('Fetched agent successfully: ${result.data?.agentName}');
        return result.data;
      } else {
        Log.e('Error fetching agent by ID: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error fetching agent by ID: $error');
      rethrow;
    }
  }

  /// Refresh agent data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provider for agents by client using AsyncNotifierProvider.family
final agentsByClientProvider = AsyncNotifierProvider.family<AgentsByClientNotifier, List<Agent>, String>(AgentsByClientNotifier.new);

/// Provider for single agent using AsyncNotifierProvider.family
final agentProvider = AsyncNotifierProvider.family<SingleAgentNotifier, Agent?, String>(SingleAgentNotifier.new); 