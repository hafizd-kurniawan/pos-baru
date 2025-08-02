import 'package:flutter/material.dart';

class VehicleDetailPage extends StatelessWidget {
  final int vehicleId;
  
  const VehicleDetailPage({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Kendaraan')),
      body: Center(child: Text('Vehicle Detail: $vehicleId')),
    );
  }
}

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