import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';

final canCreateInvoiceProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authProvider).value;
  
  if (user == null) return false;
  
  // For now, allow all authenticated users to create invoices
  // In the future, you can add role-based permissions here
  return true;
});
