import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class VehicleFilterChips extends StatelessWidget {
  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  const VehicleFilterChips({
    super.key,
    this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'value': null, 'label': 'Semua', 'icon': Icons.grid_view},
      {'value': 'available', 'label': 'Tersedia', 'icon': Icons.check_circle},
      {'value': 'sold', 'label': 'Terjual', 'icon': Icons.sell},
      {'value': 'in_repair', 'label': 'Perbaikan', 'icon': Icons.build},
      {'value': 'reserved', 'label': 'Dipesan', 'icon': Icons.book_online},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((filter) {
        final isSelected = selectedStatus == filter['value'];
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
          onSelected: (_) => onStatusChanged(filter['value'] as String?),
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