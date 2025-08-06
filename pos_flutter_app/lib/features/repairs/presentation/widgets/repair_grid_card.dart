import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/repair.dart';
import '../../../../core/theme/app_theme.dart';

class RepairGridCard extends StatelessWidget {
  final RepairOrder repair;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onViewSpareParts;
  final VoidCallback? onViewDetail;

  const RepairGridCard({
    super.key,
    required this.repair,
    this.onTap,
    this.onComplete,
    this.onViewSpareParts,
    this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final vehicle = repair.vehicle;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Status and Code
              Row(
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(repair.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(repair.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    repair.code,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Main Content Grid (4-5 columns layout)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Column 1: Vehicle Image Placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: _buildVehicleIcon(),
                  ),

                  const SizedBox(width: 16),

                  // Column 2: Vehicle Details
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle?.displayName ?? 'Unknown Vehicle',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (vehicle?.licensePlate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Text(
                              vehicle!.licensePlate!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        _buildVehicleDetail(
                          Icons.calendar_today_outlined,
                          'Tahun',
                          vehicle?.year.toString() ?? '-',
                        ),
                        _buildVehicleDetail(
                          Icons.palette_outlined,
                          'Warna',
                          vehicle?.color ?? '-',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Column 3: Repair Details
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deskripsi Perbaikan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          repair.description,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.person_outline,
                          'Mekanik',
                          repair.mechanic?.name ?? 'Belum ditugaskan',
                        ),
                        _buildInfoRow(
                          Icons.access_time,
                          'Dibuat',
                          DateFormat('dd/MM/yyyy').format(repair.createdAt),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Column 4: Cost & Progress
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimasi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Rp ${NumberFormat('#,###').format(repair.estimatedCost)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (repair.actualCost != null) ...[
                          Text(
                            'Aktual',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Rp ${NumberFormat('#,###').format(repair.actualCost!)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Column 5: Actions
                  Column(
                    children: [
                      // View History Parts Button (Detail)
                      SizedBox(
                        width: 100,
                        child: ElevatedButton.icon(
                          onPressed: onViewDetail,
                          icon: const Icon(Icons.history, size: 16),
                          label: const Text(
                            'History',
                            style: TextStyle(fontSize: 9),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Assign Spare Parts Button (Parts)
                      SizedBox(
                        width: 100,
                        child: ElevatedButton.icon(
                          onPressed: onViewSpareParts,
                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                          label: const Text(
                            'Parts',
                            style: TextStyle(fontSize: 9),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Complete Button (only if status is not completed)
                      if (repair.status.toLowerCase() != 'completed' &&
                          repair.status.toLowerCase() != 'cancelled')
                        SizedBox(
                          width: 100,
                          child: ElevatedButton.icon(
                            onPressed: onComplete,
                            icon: const Icon(Icons.check_circle, size: 16),
                            label: const Text(
                              'Selesai',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleIcon() {
    return Icon(
      Icons.directions_car,
      size: 40,
      color: AppTheme.primaryColor,
    );
  }

  Widget _buildVehicleDetail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'in_progress':
        return 'Dikerjakan';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}
