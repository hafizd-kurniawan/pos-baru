import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class SparePartFilterChips extends StatelessWidget {
  final String? selectedStatus;
  final String? selectedCategory;
  final List<String> availableCategories;
  final Function(String?) onStatusChanged;
  final Function(String?) onCategoryChanged;

  const SparePartFilterChips({
    super.key,
    this.selectedStatus,
    this.selectedCategory,
    this.availableCategories = const [],
    required this.onStatusChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status filters
        Wrap(
          spacing: 8,
          children: [
            _buildFilterChip(
              label: 'Semua Status',
              isSelected: selectedStatus == null,
              onSelected: (_) => onStatusChanged(null),
            ),
            _buildFilterChip(
              label: 'Tersedia',
              isSelected: selectedStatus == 'available',
              onSelected: (_) => onStatusChanged('available'),
            ),
            _buildFilterChip(
              label: 'Stok Rendah',
              isSelected: selectedStatus == 'low_stock',
              onSelected: (_) => onStatusChanged('low_stock'),
            ),
            _buildFilterChip(
              label: 'Habis',
              isSelected: selectedStatus == 'out_of_stock',
              onSelected: (_) => onStatusChanged('out_of_stock'),
            ),
            _buildFilterChip(
              label: 'Tidak Aktif',
              isSelected: selectedStatus == 'inactive',
              onSelected: (_) => onStatusChanged('inactive'),
            ),
          ],
        ),
        if (availableCategories.isNotEmpty) ...[
          const SizedBox(height: 12),
          // Category filters
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                label: 'Semua Kategori',
                isSelected: selectedCategory == null,
                onSelected: (_) => onCategoryChanged(null),
              ),
              ...availableCategories.map((category) => _buildFilterChip(
                    label: category,
                    isSelected: selectedCategory == category,
                    onSelected: (_) => onCategoryChanged(category),
                  )),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryColor,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color:
            isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.3),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
