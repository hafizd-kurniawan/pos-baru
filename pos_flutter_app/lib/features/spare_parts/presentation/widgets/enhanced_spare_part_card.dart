import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/spare_part.dart';
import '../../../../core/theme/app_theme.dart';

class EnhancedSparePartCard extends StatefulWidget {
  final SparePart sparePart;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewDetail;

  const EnhancedSparePartCard({
    super.key,
    required this.sparePart,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onViewDetail,
  });

  @override
  State<EnhancedSparePartCard> createState() => _EnhancedSparePartCardState();
}

class _EnhancedSparePartCardState extends State<EnhancedSparePartCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Widget _buildStockStatusChip() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!widget.sparePart.isActive) {
      statusColor = Colors.red;
      statusText = 'Tidak Aktif';
      statusIcon = Icons.block;
    } else if (widget.sparePart.stockQuantity <= 0) {
      statusColor = Colors.red;
      statusText = 'Habis';
      statusIcon = Icons.inventory_2_outlined;
    } else if (widget.sparePart.stockQuantity <=
        widget.sparePart.minimumStock) {
      statusColor = Colors.orange;
      statusText = 'Stok Rendah';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.green;
      statusText = 'Tersedia';
      statusIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 12, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (!_isHovered) return const SizedBox.shrink();

    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onViewDetail != null)
              _buildActionButton(
                icon: Icons.visibility,
                color: Colors.blue,
                onPressed: widget.onViewDetail!,
                tooltip: 'Detail',
              ),
            if (widget.onEdit != null)
              _buildActionButton(
                icon: Icons.edit,
                color: Colors.orange,
                onPressed: widget.onEdit!,
                tooltip: 'Edit',
              ),
            if (widget.onDelete != null)
              _buildActionButton(
                icon: Icons.delete,
                color: Colors.red,
                onPressed: widget.onDelete!,
                tooltip: 'Hapus',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Material(
              elevation: _elevationAnimation.value,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isHovered
                          ? AppTheme.primaryColor.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with code and status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.sparePart.code,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _buildStockStatusChip(),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Name
                            Text(
                              widget.sparePart.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // Category
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.sparePart.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Stock info
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.sparePart.stockQuantity} ${widget.sparePart.unit}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Price
                            Text(
                              _formatCurrency(widget.sparePart.sellingPrice),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
