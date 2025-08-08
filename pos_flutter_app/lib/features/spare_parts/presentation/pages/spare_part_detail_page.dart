import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/spare_part.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../blocs/spare_part_bloc.dart';

class SparePartDetailPage extends StatefulWidget {
  final int sparePartId;

  const SparePartDetailPage({
    super.key,
    required this.sparePartId,
  });

  @override
  State<SparePartDetailPage> createState() => _SparePartDetailPageState();
}

class _SparePartDetailPageState extends State<SparePartDetailPage> {
  @override
  void initState() {
    super.initState();
    _loadSparePartDetail();
  }

  void _loadSparePartDetail() async {
    final token = await StorageService.getToken();
    if (token != null && mounted) {
      context.read<SparePartBloc>().add(
            LoadSparePartDetail(id: widget.sparePartId),
          );
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Widget _buildInfoCard(String title, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(SparePart sparePart) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!sparePart.isActive) {
      statusColor = Colors.red;
      statusText = 'Tidak Aktif';
      statusIcon = Icons.block;
    } else if (sparePart.stockQuantity <= 0) {
      statusColor = Colors.red;
      statusText = 'Habis';
      statusIcon = Icons.inventory_2_outlined;
    } else if (sparePart.stockQuantity <= sparePart.minimumStock) {
      statusColor = Colors.orange;
      statusText = 'Stok Rendah';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.green;
      statusText = 'Tersedia';
      statusIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Detail Spare Part'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push(
              '/spare-parts/${widget.sparePartId}/edit',
            ),
          ),
        ],
      ),
      body: BlocBuilder<SparePartBloc, SparePartState>(
        builder: (context, state) {
          if (state is SparePartLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SparePartError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadSparePartDetail,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (state is SparePartDetailLoaded) {
            final sparePart = state.sparePart;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with name and status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sparePart.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Kode: ${sparePart.code}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(sparePart),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Info grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                    children: [
                      _buildInfoCard(
                        'Kategori',
                        sparePart.category,
                        icon: Icons.category,
                      ),
                      _buildInfoCard(
                        'Unit',
                        sparePart.unit,
                        icon: Icons.straighten,
                      ),
                      _buildInfoCard(
                        'Stok Saat Ini',
                        '${sparePart.stockQuantity} ${sparePart.unit}',
                        icon: Icons.inventory_2,
                      ),
                      _buildInfoCard(
                        'Stok Minimum',
                        '${sparePart.minimumStock} ${sparePart.unit}',
                        icon: Icons.warning_amber,
                      ),
                      _buildInfoCard(
                        'Harga Beli',
                        _formatCurrency(sparePart.purchasePrice),
                        icon: Icons.shopping_cart,
                      ),
                      _buildInfoCard(
                        'Harga Jual',
                        _formatCurrency(sparePart.sellingPrice),
                        icon: Icons.sell,
                      ),
                    ],
                  ),

                  if (sparePart.description != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.description,
                                  size: 20, color: AppTheme.primaryColor),
                              SizedBox(width: 8),
                              Text(
                                'Deskripsi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            sparePart.description!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return const Center(
            child: Text('Spare part tidak ditemukan'),
          );
        },
      ),
    );
  }
}
