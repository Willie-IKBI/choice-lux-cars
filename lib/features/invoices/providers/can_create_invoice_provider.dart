import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final canCreateInvoiceProvider = FutureProvider<bool>((ref) async {
  try {
    final user = ref.watch(authProvider).value;
    if (user == null) return false;

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    final userRole = profile['role'] as String?;
    // Handle role variations (driver_manager/driverManager)
    const allowedRoles = [
      'administrator',
      'super_admin',
      'manager',
      'driver_manager',
    ];
    return allowedRoles.contains(userRole?.toLowerCase());
  } catch (e) {
    return false;
  }
});
