import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

// Transactions Pages
class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _buildFeaturePage(
        context,
        title: 'Manajemen Transaksi',
        icon: Icons.receipt_long_outline,
        description: 'Fitur transaksi sedang dalam pengembangan',
        buttonText: 'Tambah Transaksi',
        onPressed: () {},
      ),
    );
  }
}

class AddTransactionPage extends StatelessWidget {
  const AddTransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: const Center(child: Text('Add Transaction Form')),
    );
  }
}

// Spare Parts Pages
class SparePartsPage extends StatelessWidget {
  const SparePartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _buildFeaturePage(
        context,
        title: 'Manajemen Spare Parts',
        icon: Icons.inventory_2_outline,
        description: 'Fitur spare parts sedang dalam pengembangan',
        buttonText: 'Tambah Spare Part',
        onPressed: () {},
      ),
    );
  }
}

class SparePartDetailPage extends StatelessWidget {
  final int sparePartId;
  
  const SparePartDetailPage({super.key, required this.sparePartId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Spare Part')),
      body: Center(child: Text('Spare Part Detail: $sparePartId')),
    );
  }
}

class AddSparePartPage extends StatelessWidget {
  const AddSparePartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Spare Part')),
      body: const Center(child: Text('Add Spare Part Form')),
    );
  }
}

// Repairs Pages
class RepairsPage extends StatelessWidget {
  const RepairsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _buildFeaturePage(
        context,
        title: 'Manajemen Perbaikan',
        icon: Icons.build_outline,
        description: 'Fitur perbaikan sedang dalam pengembangan',
        buttonText: 'Tambah Perbaikan',
        onPressed: () {},
      ),
    );
  }
}

class RepairDetailPage extends StatelessWidget {
  final int repairId;
  
  const RepairDetailPage({super.key, required this.repairId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Perbaikan')),
      body: Center(child: Text('Repair Detail: $repairId')),
    );
  }
}

class AddRepairPage extends StatelessWidget {
  const AddRepairPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Perbaikan')),
      body: const Center(child: Text('Add Repair Form')),
    );
  }
}

// Suppliers Pages
class SuppliersPage extends StatelessWidget {
  const SuppliersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _buildFeaturePage(
        context,
        title: 'Manajemen Supplier',
        icon: Icons.business_outline,
        description: 'Fitur supplier sedang dalam pengembangan',
        buttonText: 'Tambah Supplier',
        onPressed: () {},
      ),
    );
  }
}

class SupplierDetailPage extends StatelessWidget {
  final int supplierId;
  
  const SupplierDetailPage({super.key, required this.supplierId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Supplier')),
      body: Center(child: Text('Supplier Detail: $supplierId')),
    );
  }
}

class AddSupplierPage extends StatelessWidget {
  const AddSupplierPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Supplier')),
      body: const Center(child: Text('Add Supplier Form')),
    );
  }
}

// Users Pages
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _buildFeaturePage(
        context,
        title: 'Manajemen Pengguna',
        icon: Icons.admin_panel_settings_outline,
        description: 'Fitur pengguna sedang dalam pengembangan',
        buttonText: 'Tambah Pengguna',
        onPressed: () {},
      ),
    );
  }
}

class UserDetailPage extends StatelessWidget {
  final int userId;
  
  const UserDetailPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengguna')),
      body: Center(child: Text('User Detail: $userId')),
    );
  }
}

class AddUserPage extends StatelessWidget {
  const AddUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Pengguna')),
      body: const Center(child: Text('Add User Form')),
    );
  }
}

// Common Feature Page Template
Widget _buildFeaturePage(
  BuildContext context, {
  required String title,
  required IconData icon,
  required String description,
  required String buttonText,
  required VoidCallback onPressed,
}) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(buttonText),
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
                  icon,
                  size: 64,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  title.replaceAll('Manajemen ', ''),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
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
  );
}