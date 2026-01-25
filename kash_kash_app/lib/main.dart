import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: KashKashApp(),
    ),
  );
}

class KashKashApp extends StatelessWidget {
  const KashKashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kash-Kash',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PlaceholderScreen(),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Kash-Kash'),
      ),
      body: const Center(
        child: Text('Welcome to Kash-Kash!'),
      ),
    );
  }
}
