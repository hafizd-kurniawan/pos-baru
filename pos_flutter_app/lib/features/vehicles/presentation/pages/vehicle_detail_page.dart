import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/vehicle.dart';
import '../../../../core/theme/app_theme.dart';
import '../blocs/vehicle_bloc.dart';

class VehicleDetailPage extends StatefulWidget {
  final int vehicleId;

  const VehicleDetailPage({super.key, required this.vehicleId});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  void _loadVehicle() {
    context
        .read<VehicleBloc>()
        .add(LoadVehicleDetail(vehicleId: widget.vehicleId));
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return 'Tidak diatur';
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _translateConditionStatus(String? status) {
    if (status == null) return 'Tidak diatur';

    switch (status.toLowerCase()) {
      case 'excellent':
        return 'Sangat Baik';
      case 'good':
        return 'Baik';
      case 'fair':
        return 'Cukup';
      case 'poor':
        return 'Buruk';
      case 'needs_repair':
        return 'Perlu Perbaikan';
      default:
        return status;
    }
  }

  String _translateSourceType(String? sourceType) {
    if (sourceType == null) return 'Tidak diatur';

    switch (sourceType.toLowerCase()) {
      case 'customer':
        return 'Pelanggan';
      case 'supplier':
        return 'Pemasok';
      default:
        return sourceType;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Tidak diatur';
    return DateFormat('dd MMMM yyyy').format(date);
  }

  Widget _buildStatusChip(String status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'available':
        statusColor = Colors.green;
        statusText = 'Tersedia';
        statusIcon = Icons.check_circle;
        break;
      case 'sold':
        statusColor = Colors.blue;
        statusText = 'Terjual';
        statusIcon = Icons.sell;
        break;
      case 'in_repair':
        statusColor = Colors.orange;
        statusText = 'Dalam Perbaikan';
        statusIcon = Icons.build;
        break;
      case 'reserved':
        statusColor = Colors.purple;
        statusText = 'Dipesan';
        statusIcon = Icons.bookmark;
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
        statusIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List<Widget> children,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                Icon(icon, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: AppTheme.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
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
        title: const Text('Detail Kendaraan'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          BlocBuilder<VehicleBloc, VehicleState>(
            builder: (context, state) {
              if (state is VehicleDetailLoaded) {
                return Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          context.push('/vehicles/${widget.vehicleId}/edit'),
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit Kendaraan',
                    ),
                    IconButton(
                      onPressed: () => _showDeleteConfirmation(state.vehicle),
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      tooltip: 'Hapus Kendaraan',
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<VehicleBloc, VehicleState>(
        listener: (context, state) {
          if (state is VehicleError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is VehicleOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          }
        },
        builder: (context, state) {
          if (state is VehicleLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            );
          }

          if (state is VehicleDetailLoaded) {
            final vehicle = state.vehicle;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with vehicle image and basic info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Vehicle image placeholder
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.grey.withOpacity(0.1),
                                Colors.grey.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_car,
                                size: 60,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Foto Kendaraan',
                                style: TextStyle(
                                  color: Colors.grey.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Basic info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${vehicle.brand?.name ?? 'Unknown'} ${vehicle.model}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Kode: ${vehicle.code}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            _buildStatusChip(vehicle.status),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Vehicle Specifications
                  _buildDetailSection(
                    title: 'Spesifikasi Kendaraan',
                    icon: Icons.settings,
                    children: [
                      _buildDetailRow('Tahun', vehicle.year.toString()),
                      _buildDetailRow('Warna', vehicle.color ?? 'Tidak diatur'),
                      _buildDetailRow(
                          'Kapasitas Mesin',
                          vehicle.engineCapacity != null
                              ? '${vehicle.engineCapacity} CC'
                              : 'Tidak diatur'),
                      _buildDetailRow('Jenis Bahan Bakar',
                          vehicle.fuelType ?? 'Tidak diatur'),
                      _buildDetailRow('Transmisi',
                          vehicle.transmissionType ?? 'Tidak diatur'),
                      _buildDetailRow('Odometer',
                          '${NumberFormat('#,###').format(vehicle.odometer)} km'),
                    ],
                  ),

                  // Vehicle Identity
                  _buildDetailSection(
                    title: 'Identitas Kendaraan',
                    icon: Icons.assignment,
                    children: [
                      _buildDetailRow('Nomor Polisi',
                          vehicle.licensePlate ?? 'Tidak diatur'),
                      _buildDetailRow('Nomor Rangka',
                          vehicle.chassisNumber ?? 'Tidak diatur'),
                      _buildDetailRow('Nomor Mesin',
                          vehicle.engineNumber ?? 'Tidak diatur'),
                    ],
                  ),

                  // Price Information
                  _buildDetailSection(
                    title: 'Informasi Harga',
                    icon: Icons.attach_money,
                    children: [
                      _buildDetailRow(
                          'Harga Beli', _formatCurrency(vehicle.purchasePrice)),
                      _buildDetailRow('Biaya Perbaikan',
                          _formatCurrency(vehicle.repairCost)),
                      _buildDetailRow('HPP', _formatCurrency(vehicle.hppPrice)),
                      _buildDetailRow(
                          'Harga Jual', _formatCurrency(vehicle.sellingPrice)),
                      if (vehicle.soldPrice != null)
                        _buildDetailRow('Harga Terjual',
                            _formatCurrency(vehicle.soldPrice)),
                      if (vehicle.soldDate != null)
                        _buildDetailRow(
                            'Tanggal Terjual', _formatDate(vehicle.soldDate)),
                    ],
                  ),

                  // Additional Information
                  _buildDetailSection(
                    title: 'Informasi Tambahan',
                    icon: Icons.info_outline,
                    children: [
                      _buildDetailRow('Kondisi',
                          _translateConditionStatus(vehicle.conditionStatus)),
                      _buildDetailRow(
                          'Sumber', _translateSourceType(vehicle.sourceType)),
                      if (vehicle.notes != null && vehicle.notes!.isNotEmpty)
                        _buildDetailRow('Catatan', vehicle.notes!),
                      _buildDetailRow(
                          'Tanggal Dibuat', _formatDate(vehicle.createdAt)),
                      _buildDetailRow('Terakhir Diperbarui',
                          _formatDate(vehicle.updatedAt)),
                    ],
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat detail kendaraan',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadVehicle,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kendaraan'),
        content: Text(
          'Apakah Anda yakin ingin menghapus kendaraan ${vehicle.displayName}?\n\nTindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context
                  .read<VehicleBloc>()
                  .add(DeleteVehicle(vehicleId: vehicle.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
