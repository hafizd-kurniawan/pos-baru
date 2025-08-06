import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/spare_part.dart';
import '../../../../core/theme/app_theme.dart';

class SparePartCard extends StatelessWidget {
  final SparePart sparePart;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onUpdateStock;

  const SparePartCard({
    super.key,
    required this.sparePart,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onUpdateStock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(),
                            size: 12,
                            color: _getStatusColor(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sparePart.stockStatus,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Actions Menu
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit?.call();
                            break;
                          case 'stock':
                            onUpdateStock?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'stock',
                          child: Row(
                            children: [
                              Icon(Icons.inventory_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Update Stok'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outlined,
                                  size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Hapus',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(
                        Icons.more_vert,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Product Info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sparePart.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sparePart.code.isNotEmpty
                                ? 'Code: ${sparePart.code}'
                                : '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (sparePart.description != null &&
                              sparePart.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              sparePart.description!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Stock Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${sparePart.stockQuantity} ${sparePart.unit}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Min: ${sparePart.minimumStock}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price Info
                Row(
                  children: [
                    Expanded(
                      child: _buildPriceInfo(
                        label: 'Harga Beli',
                        price: sparePart.purchasePrice,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPriceInfo(
                        label: 'Harga Jual',
                        price: sparePart.sellingPrice,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPriceInfo(
                        label: 'Keuntungan',
                        price: sparePart.profit,
                        color: sparePart.profit > 0 ? Colors.blue : Colors.red,
                        isProfit: true,
                      ),
                    ),
                  ],
                ),

                // Progress Bar for Stock Level
                if (sparePart.minimumStock > 0) ...[
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Level Stok',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            '${((sparePart.stockQuantity / (sparePart.minimumStock * 2)) * 100).clamp(0, 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (sparePart.stockQuantity /
                                (sparePart.minimumStock * 2))
                            .clamp(0, 1),
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          sparePart.isLowStock ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInfo({
    required String label,
    required double price,
    required Color color,
    bool isProfit = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isProfit && price > 0
              ? '+${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price)}'
              : NumberFormat.currency(
                      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                  .format(price),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    if (!sparePart.isActive) return Colors.grey;
    if (sparePart.stockQuantity == 0) return Colors.red;
    if (sparePart.isLowStock) return Colors.orange;
    return Colors.green;
  }

  IconData _getStatusIcon() {
    if (!sparePart.isActive) return Icons.pause_circle_outline;
    if (sparePart.stockQuantity == 0)
      return Icons.remove_shopping_cart_outlined;
    if (sparePart.isLowStock) return Icons.warning_outlined;
    return Icons.check_circle_outline;
  }
}
