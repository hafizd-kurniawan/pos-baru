import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/repair.dart';
import '../../../../core/theme/app_theme.dart';

class NewRepairCard extends StatelessWidget {
  final RepairOrder repair;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onViewSpareParts;

  const NewRepairCard({
    super.key,
    required this.repair,
    this.onTap,
    this.onComplete,
    this.onViewSpareParts,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          repair.code,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm')
                              .format(repair.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: repair.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: repair.statusColor),
                    ),
                    child: Text(
                      repair.statusText,
                      style: TextStyle(
                        color: repair.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Main Content - 5 Columns
              Row(
                children: [
                  // Column 1: Vehicle Info
                  Expanded(
                    flex: 3,
                    child: _buildInfoColumn(
                      title: 'Kendaraan',
                      items: [
                        '${repair.vehicle?.brand?.name ?? 'N/A'} ${repair.vehicle?.model ?? 'N/A'}',
                        'Tahun: ${repair.vehicle?.year ?? 'N/A'}',
                        'Plat: ${repair.vehicle?.licensePlate ?? 'N/A'}',
                      ],
                    ),
                  ),

                  // Column 2: Mechanic Info
                  Expanded(
                    flex: 2,
                    child: _buildInfoColumn(
                      title: 'Mekanik',
                      items: [
                        repair.mechanic?.name ?? 'N/A',
                        'ID: ${repair.mechanicId}',
                      ],
                    ),
                  ),

                  // Column 3: Description & Progress
                  Expanded(
                    flex: 3,
                    child: _buildInfoColumn(
                      title: 'Deskripsi',
                      items: [
                        repair.description.length > 50
                            ? '${repair.description.substring(0, 50)}...'
                            : repair.description,
                        if (repair.notes != null && repair.notes!.isNotEmpty)
                          'Catatan: ${repair.notes!.length > 30 ? '${repair.notes!.substring(0, 30)}...' : repair.notes!}',
                      ],
                    ),
                  ),

                  // Column 4: Cost Information
                  Expanded(
                    flex: 2,
                    child: _buildInfoColumn(
                      title: 'Biaya',
                      items: [
                        'Estimasi: ${_formatCurrency(repair.estimatedCost)}',
                        if (repair.actualCost != null)
                          'Aktual: ${_formatCurrency(repair.actualCost!)}',
                        'Spare Parts: ${_formatCurrency(repair.totalSparePartsCost)}',
                      ],
                    ),
                  ),

                  // Column 5: Spare Parts & Actions
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spare Parts',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${repair.spareParts?.length ?? 0} item(s)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        if (repair.spareParts != null &&
                            repair.spareParts!.isNotEmpty)
                          InkWell(
                            onTap: onViewSpareParts,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Text(
                                'Lihat History',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Action Buttons Row
              Row(
                children: [
                  // Complete Button (only if status is not completed)
                  if (repair.status.toLowerCase() != 'completed' &&
                      repair.status.toLowerCase() != 'cancelled')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onComplete,
                        icon: Icon(Icons.check_circle, size: 16),
                        label: Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),

                  if (repair.status.toLowerCase() != 'completed' &&
                      repair.status.toLowerCase() != 'cancelled')
                    SizedBox(width: 12),

                  // View Details Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTap,
                      icon: Icon(Icons.info, size: 16),
                      label: Text('Detail'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn({
    required String title,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        ...items
            .map((item) => Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return 'Rp ${NumberFormat('#,##0').format(amount)}';
  }
}
