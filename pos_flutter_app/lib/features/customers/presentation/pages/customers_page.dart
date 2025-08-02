import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manajemen Customer',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Customer'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Halaman Customer',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fitur customer sedang dalam pengembangan',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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