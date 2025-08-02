import 'package:flutter/material.dart';

class CustomerDetailPage extends StatelessWidget {
  final int customerId;
  
  const CustomerDetailPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Customer')),
      body: Center(child: Text('Customer Detail: $customerId')),
    );
  }
}