import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TransactionFilterChips extends StatelessWidget {
  final String? selectedType;
  final ValueChanged<String?> onTypeChanged;

  const TransactionFilterChips({
    super.key,
    this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'value': null, 'label': 'Semua', 'icon': Icons.view_list},
      {'value': 'purchase', 'label': 'Pembelian', 'icon': Icons.shopping_cart},
      {'value': 'sales', 'label': 'Penjualan', 'icon': Icons.sell},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((filter) {
        final isSelected = selectedType == filter['value'];
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                filter['icon'] as IconData,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                filter['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
          selected: isSelected,
          onSelected: (_) => onTypeChanged(filter['value'] as String?),
          backgroundColor: Colors.transparent,
          selectedColor: AppTheme.primaryColor,
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary.withOpacity(0.3),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}