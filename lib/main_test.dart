import 'package:flutter/material.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Choice Lux Cars Test',
      theme: ThemeData.dark(),
      home: const Scaffold(
        body: Center(
          child: Text(
            'Choice Lux Cars Test App\nIf you see this, the basic app works!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
