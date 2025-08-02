import 'package:flutter/material.dart';

class AddVehiclePage extends StatelessWidget {
  const AddVehiclePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Kendaraan')),
      body: const Center(child: Text('Add Vehicle Form')),
    );
  }
}