import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/data/insights_repository.dart';
import 'package:choice_lux_cars/features/insights/models/client_statement_data.dart';
import 'package:choice_lux_cars/core/types/result.dart';

/// Provider for client statement data
final clientStatementProvider = FutureProvider.family<ClientStatementData, ClientStatementParams>(
  (ref, params) async {
    final repository = ref.watch(insightsRepositoryProvider);
    final result = await repository.fetchClientStatement(
      clientId: params.clientId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
    
    if (result.isSuccess) {
      return result.data!;
    } else {
      throw Exception(result.error?.message ?? 'Failed to fetch client statement');
    }
  },
);

/// Parameters for client statement provider
class ClientStatementParams {
  final String clientId;
  final DateTime startDate;
  final DateTime endDate;

  ClientStatementParams({
    required this.clientId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientStatementParams &&
          runtimeType == other.runtimeType &&
          clientId == other.clientId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => clientId.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}

