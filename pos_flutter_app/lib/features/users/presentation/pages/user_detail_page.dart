import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class UserDetailPage extends StatelessWidget {
  final String userId;

  const UserDetailPage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail User'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('User Detail Page - Coming Soon'),
      ),
    );
  }
}