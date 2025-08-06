import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/repair.dart';
import '../../../../core/theme/app_theme.dart';

class RepairDetailDialog extends StatelessWidget {
  final RepairOrder repair;

  const RepairDetailDialog({
    super.key,
    required this.repair,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.assignment,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Assignment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          repair.code,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Information
                    _buildSectionCard(
                      'Informasi Kendaraan',
                      Icons.directions_car,
                      [
                        _buildInfoRow(
                            'Model', repair.vehicle?.displayName ?? '-'),
                        _buildInfoRow(
                            'Plat Nomor', repair.vehicle?.licensePlate ?? '-'),
                        _buildInfoRow(
                            'Tahun', repair.vehicle?.year.toString() ?? '-'),
                        _buildInfoRow('Warna', repair.vehicle?.color ?? '-'),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Assignment Information
                    _buildSectionCard(
                      'Informasi Assignment',
                      Icons.assignment_ind,
                      [
                        _buildInfoRow(
                            'Mechanic', repair.mechanic?.fullName ?? '-'),
                        _buildInfoRow('Assigned By',
                            repair.assignedByUser?.fullName ?? '-'),
                        _buildInfoRow(
                            'Tanggal Assignment',
                            DateFormat('dd MMM yyyy, HH:mm')
                                .format(repair.createdAt)),
                        if (repair.status.toLowerCase() == 'in_progress' &&
                            repair.startedAt != null)
                          _buildInfoRow(
                              'Mulai Dikerjakan',
                              DateFormat('dd MMM yyyy, HH:mm')
                                  .format(repair.startedAt!)),
                        if (repair.status.toLowerCase() == 'completed' &&
                            repair.completedAt != null)
                          _buildInfoRow(
                              'Selesai',
                              DateFormat('dd MMM yyyy, HH:mm')
                                  .format(repair.completedAt!)),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Repair Details
                    _buildSectionCard(
                      'Detail Perbaikan',
                      Icons.build,
                      [
                        _buildInfoRow('Deskripsi', repair.description),
                        _buildInfoRow('Estimasi Biaya',
                            _formatCurrency(repair.estimatedCost)),
                        if (repair.actualCost != null)
                          _buildInfoRow('Biaya Aktual',
                              _formatCurrency(repair.actualCost!)),
                        if (repair.notes?.isNotEmpty ?? false)
                          _buildInfoRow('Catatan', repair.notes!),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Progress Timeline
                    _buildTimelineCard(),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // TODO: Navigate to edit assignment
                      },
                      icon: Icon(Icons.edit),
                      label: Text('Edit Assignment'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: repair.status.toLowerCase() == 'completed'
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              // TODO: Navigate to complete repair
                            },
                      icon: Icon(Icons.check_circle),
                      label: Text('Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    switch (repair.status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      case 'in_progress':
        color = Colors.blue;
        text = 'In Progress';
        break;
      case 'completed':
        color = AppTheme.successColor;
        text = 'Completed';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        text = repair.status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.timeline,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Progress Timeline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Timeline Items
            _buildTimelineItem(
              'Assignment Created',
              DateFormat('dd MMM yyyy, HH:mm').format(repair.createdAt),
              Icons.assignment,
              AppTheme.primaryColor,
              isCompleted: true,
            ),

            if (repair.startedAt != null)
              _buildTimelineItem(
                'Work Started',
                DateFormat('dd MMM yyyy, HH:mm').format(repair.startedAt!),
                Icons.play_arrow,
                Colors.blue,
                isCompleted: true,
              ),

            if (repair.completedAt != null)
              _buildTimelineItem(
                'Work Completed',
                DateFormat('dd MMM yyyy, HH:mm').format(repair.completedAt!),
                Icons.check_circle,
                AppTheme.successColor,
                isCompleted: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String time,
    IconData icon,
    Color color, {
    bool isCompleted = false,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? color : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isCompleted ? Colors.black87 : Colors.grey[600],
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}
