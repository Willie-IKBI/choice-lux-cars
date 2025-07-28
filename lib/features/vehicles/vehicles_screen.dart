import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../vehicles/providers/vehicles_provider.dart';
import '../vehicles/widgets/vehicle_card.dart';
import 'package:go_router/go_router.dart';

class VehicleListScreen extends ConsumerStatefulWidget {
  const VehicleListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends ConsumerState<VehicleListScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(vehiclesProvider.notifier).fetchVehicles());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehiclesProvider);
    final vehicles = state.vehicles.where((v) => v.make.toLowerCase().contains(_search.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicles'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search by make',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
            const SizedBox(height: 16),
            if (state.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator())),
            if (state.error != null)
              Expanded(child: Center(child: Text(state.error!, style: const TextStyle(color: Colors.red)))),
            if (!state.isLoading && state.error == null)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 1;
                    if (constraints.maxWidth > 1200) {
                      crossAxisCount = 4;
                    } else if (constraints.maxWidth > 900) {
                      crossAxisCount = 3;
                    } else if (constraints.maxWidth > 600) {
                      crossAxisCount = 2;
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85, // Increased from 0.75 to reduce card height
                      ),
                      itemCount: vehicles.length,
                      itemBuilder: (context, i) => VehicleCard(
                        vehicle: vehicles[i],
                        onTap: () {
                          context.push('/vehicles/edit', extra: vehicles[i]);
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: true // TODO: Replace with actual permission check
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
              onPressed: () {
                context.push('/vehicles/edit');
              },
            )
          : null,
    );
  }
} 