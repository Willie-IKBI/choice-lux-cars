import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:choice_lux_cars/core/supabase/supabase_client_provider.dart';
import 'package:choice_lux_cars/features/clients/models/agent.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/types/result.dart';
import 'package:choice_lux_cars/core/errors/app_exception.dart';

/// Repository for agent-related data operations
///
/// Encapsulates all Supabase queries and returns domain models.
/// This layer separates data access from business logic.
class AgentsRepository {
  final SupabaseClient _supabase;

  AgentsRepository(this._supabase);

  /// Fetch agents for a specific client
  Future<Result<List<Agent>>> fetchAgentsByClient(String clientId) async {
    try {
      Log.d('Fetching agents for client: $clientId');

      final response = await _supabase
          .from('agents')
          .select()
          .eq('client_key', clientId)
          .order('agent_name', ascending: true);

      Log.d('Fetched ${response.length} agents for client: $clientId');

      final agents = response.map((json) => Agent.fromJson(json)).toList();
      return Result.success(agents);
    } catch (error) {
      Log.e('Error fetching agents by client: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Create a new agent
  Future<Result<Map<String, dynamic>>> createAgent(Agent agent) async {
    try {
      Log.d('Creating agent: ${agent.agentName}');

      final agentData = agent.toJson();

      final response = await _supabase
          .from('agents')
          .insert(agentData)
          .select()
          .single();

      Log.d('Agent created successfully with ID: ${response['id']}');
      return Result.success(response);
    } catch (error) {
      Log.e('Error creating agent: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Update an existing agent
  Future<Result<void>> updateAgent(Agent agent) async {
    try {
      Log.d('Updating agent: ${agent.id}');

      if (agent.id == null) {
        return const Result.failure(
          UnknownException('Agent ID is required for update'),
        );
      }

      await _supabase.from('agents').update(agent.toJson()).eq('id', agent.id!);

      Log.d('Agent updated successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error updating agent: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Delete an agent
  Future<Result<void>> deleteAgent(String agentId) async {
    try {
      Log.d('Deleting agent: $agentId');

      await _supabase.from('agents').delete().eq('id', agentId);

      Log.d('Agent deleted successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error deleting agent: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get agent by ID
  Future<Result<Agent?>> getAgentById(String agentId) async {
    try {
      Log.d('Fetching agent by ID: $agentId');

      final response = await _supabase
          .from('agents')
          .select()
          .eq('id', agentId)
          .maybeSingle();

      if (response != null) {
        Log.d('Agent found: ${response['agent_name']}');
        return Result.success(Agent.fromJson(response));
      } else {
        Log.d('Agent not found: $agentId');
        return const Result.success(null);
      }
    } catch (error) {
      Log.e('Error fetching agent by ID: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch agent by ID (alias for getAgentById for consistency)
  Future<Result<Agent?>> fetchAgentById(String agentId) async {
    return getAgentById(agentId);
  }

  /// Search agents by name
  Future<Result<List<Agent>>> searchAgents(String query) async {
    try {
      Log.d('Searching agents with query: $query');

      final response = await _supabase
          .from('agents')
          .select()
          .ilike('agent_name', '%$query%')
          .order('agent_name', ascending: true);

      Log.d('Found ${response.length} agents matching query: $query');

      final agents = response.map((json) => Agent.fromJson(json)).toList();
      return Result.success(agents);
    } catch (error) {
      Log.e('Error searching agents: $error');
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

/// Provider for AgentsRepository
final agentsRepositoryProvider = Provider<AgentsRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AgentsRepository(supabase);
});
