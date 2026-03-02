// Individual insight providers live in their own files:
// - jobs_insights_provider.dart
// - driver_insights_provider.dart
// - vehicle_insights_provider.dart
// - financial_insights_provider.dart
// - client_insights_provider.dart
//
// The former aggregate providers were removed because they called the
// broken fetchInsights() method and were never referenced by any screen.

export 'package:choice_lux_cars/features/insights/data/insights_repository.dart'
    show insightsRepositoryProvider;
