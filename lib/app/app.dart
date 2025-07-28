import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/app/router.dart';
import 'package:choice_lux_cars/app/theme.dart';

class ChoiceLuxCarsApp extends ConsumerWidget {
  const ChoiceLuxCarsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Choice Lux Cars',
      theme: ChoiceLuxTheme.lightTheme,
      darkTheme: ChoiceLuxTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
} 