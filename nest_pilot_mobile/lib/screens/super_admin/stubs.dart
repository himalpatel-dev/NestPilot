import 'package:flutter/material.dart';

class BuildingCreateScreen extends StatelessWidget {
  const BuildingCreateScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Building')),
      body: const Center(child: Text('Building Creation Form')),
    );
  }
}

class FlatCreateScreen extends StatelessWidget {
  const FlatCreateScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Flat')),
      body: const Center(child: Text('Flat Creation Form')),
    );
  }
}

class FlatsListScreen extends StatelessWidget {
  const FlatsListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flats List')),
      body: const Center(child: Text('List of Flats')),
    );
  }
}
