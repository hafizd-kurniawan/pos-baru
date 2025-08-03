import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SupplierDetailPage extends StatelessWidget {
  final String supplierId;

  const SupplierDetailPage({
    super.key,
    required this.supplierId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Supplier'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Supplier Detail Page - Coming Soon'),
      ),
    );
  }
}