import 'package:flutter/material.dart';

class AddCustomerPage extends StatelessWidget {
  const AddCustomerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Customer')),
      body: const Center(child: Text('Add Customer Form')),
    );
  }
}