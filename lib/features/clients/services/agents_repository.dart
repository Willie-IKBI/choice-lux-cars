import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/features/clients/models/agent.dart';

final agentsRepositoryProvider = Provider<AgentsRepository>((ref) => AgentsRepository(Supabase.instance.client));

class AgentsRepository {
  AgentsRepository(this._c);
  final SupabaseClient _c;

  Future<List<Agent>> fetchAgentsByClient(String clientId) async {
    final rows = await _c.from('agents').select().eq('client_id', clientId);
    return rows.map<Agent>((r) => Agent.fromJson(r)).toList();
  }

  Future<void> createAgent(Agent agent) async {
    await _c.from('agents').insert(agent.toJson());
  }

  Future<void> updateAgent(Agent agent) async {
    if (agent.id == null) {
      throw ArgumentError('Agent ID cannot be null for update');
    }
    await _c.from('agents').update(agent.toJson()).eq('id', agent.id!);
  }

  Future<void> deleteAgent(String agentId) async {
    await _c.from('agents').delete().eq('id', agentId);
  }
}
