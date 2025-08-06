import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../blocs/mechanic_repair_bloc.dart';
import '../services/mechanic_repair_service.dart';
import '../widgets/add_spare_part_dialog.dart';
import '../widgets/complete_repair_dialog.dart';
import '../widgets/repair_item_card.dart';

class MechanicRepairDetailPage extends StatefulWidget {
  final int repairId;

  const MechanicRepairDetailPage({
    super.key,
    required this.repairId,
  });

  @override
  State<MechanicRepairDetailPage> createState() =>
      _MechanicRepairDetailPageState();
}

class _MechanicRepairDetailPageState extends State<MechanicRepairDetailPage> {
  @override
  void initState() {
    super.initState();
    _loadRepairDetail();
  }

  Future<void> _loadRepairDetail() async {
    context.read<MechanicRepairBloc>().add(
          LoadRepairDetail(
            repairId: widget.repairId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Detail Perbaikan #${widget.repairId.toString().padLeft(4, '0')}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRepairDetail,
          ),
        ],
      ),
      body: BlocListener<MechanicRepairBloc, MechanicRepairState>(
        listener: (context, state) {
          if (state is MechanicRepairError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is MechanicRepairOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            if (state.repairWithItems != null) {
              // Refresh detail after operation
              _loadRepairDetail();
            }
          }
        },
        child: BlocBuilder<MechanicRepairBloc, MechanicRepairState>(
          builder: (context, state) {
            if (state is MechanicRepairLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is MechanicRepairError) {
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
                      'Terjadi Kesalahan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: TextStyle(
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadRepairDetail,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }

            if (state is RepairDetailLoaded) {
              return _buildRepairDetail(state.repairWithItems);
            }

            if (state is MechanicRepairOperationSuccess &&
                state.repairWithItems != null) {
              return _buildRepairDetail(state.repairWithItems!);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildRepairDetail(RepairWithItems repairWithItems) {
    final repair = repairWithItems.repair;
    final vehicleId = repairWithItems.vehicleId;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header with gradient
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(repair.status),
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusText(repair.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Vehicle Info placeholder - will show vehicle ID for now
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Vehicle ID: $vehicleId',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Deskripsi Masalah',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          repair.description,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Colors.grey[500],
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Mekanik: ${repair.mechanic?.name ?? 'Unknown Mechanic'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.access_time,
                              color: Colors.grey[500],
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy')
                                  .format(repair.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                if (repair.status == 'pending') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startRepair,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Mulai Perbaikan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Spare Parts Section
                Row(
                  children: [
                    Icon(
                      Icons.build,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Spare Parts yang Digunakan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (repair.status == 'in_progress') ...[
                      IconButton(
                        onPressed: _showAddSparePartDialog,
                        icon: Icon(
                          Icons.add_circle,
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // Spare Parts Grid
                if (repairWithItems.items.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum Ada Spare Parts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tambahkan spare parts yang digunakan untuk perbaikan',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (repair.status == 'in_progress') ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showAddSparePartDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Spare Part'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: repairWithItems.items.length,
                    itemBuilder: (context, index) {
                      final item = repairWithItems.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RepairItemCard(
                          repairItem: item,
                          canEdit: repair.status == 'in_progress',
                          onEdit: () => _editRepairItem(item),
                          onDelete: () => _deleteRepairItem(item),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Cost Summary
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Spare Parts:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Rp ${NumberFormat('#,###').format(repairWithItems.totalSparePartsCost)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          if (repairWithItems.totalCost >
                              repairWithItems.totalSparePartsCost) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Biaya Jasa:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Rp ${NumberFormat('#,###').format(repairWithItems.totalCost - repairWithItems.totalSparePartsCost)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Keseluruhan:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Rp ${NumberFormat('#,###').format(repairWithItems.totalCost)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Complete Button
                if (repair.status == 'in_progress') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showCompleteRepairDialog,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Selesaikan Perbaikan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions;
      case 'in_progress':
        return Icons.build;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'in_progress':
        return 'Sedang Dikerjakan';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Future<void> _startRepair() async {
    context.read<MechanicRepairBloc>().add(
          StartRepair(
            repairId: widget.repairId,
          ),
        );
  }

  void _showAddSparePartDialog() {
    showDialog(
      context: context,
      builder: (context) => AddSparePartDialog(
        repairId: widget.repairId,
      ),
    );
  }

  void _editRepairItem(RepairItem item) {
    // TODO: Implement edit repair item dialog
  }

  Future<void> _deleteRepairItem(RepairItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Item'),
        content: Text('Yakin ingin menghapus ${item.sparePartName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<MechanicRepairBloc>().add(
            RemoveRepairItem(
              repairId: widget.repairId,
              itemId: item.id,
            ),
          );
    }
  }

  void _showCompleteRepairDialog() {
    showDialog(
      context: context,
      builder: (context) => CompleteRepairDialog(
        repairId: widget.repairId,
      ),
    );
  }
}
