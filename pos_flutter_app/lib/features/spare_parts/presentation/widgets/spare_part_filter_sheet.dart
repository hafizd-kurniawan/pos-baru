import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class SparePartFilterSheet extends StatefulWidget {
  final String? selectedFilter;
  final bool? isActiveFilter;
  final Function(String?, bool?) onFilterChanged;

  const SparePartFilterSheet({
    super.key,
    this.selectedFilter,
    this.isActiveFilter,
    required this.onFilterChanged,
  });

  @override
  State<SparePartFilterSheet> createState() => _SparePartFilterSheetState();
}

class _SparePartFilterSheetState extends State<SparePartFilterSheet> {
  String? _selectedFilter;
  bool? _isActiveFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.selectedFilter;
    _isActiveFilter = widget.isActiveFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Filter Spare Parts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedFilter = null;
                      _isActiveFilter = null;
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),

          const Divider(),

          // Filter Options
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stock Status Filter
                Text(
                  'Status Stok',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip(
                      label: 'Semua',
                      value: null,
                      selected: _selectedFilter == null,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilter = null);
                        }
                      },
                    ),
                    _buildFilterChip(
                      label: 'Stok Tersedia',
                      value: 'available',
                      selected: _selectedFilter == 'available',
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = selected ? 'available' : null;
                        });
                      },
                    ),
                    _buildFilterChip(
                      label: 'Stok Rendah',
                      value: 'low_stock',
                      selected: _selectedFilter == 'low_stock',
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = selected ? 'low_stock' : null;
                        });
                      },
                    ),
                    _buildFilterChip(
                      label: 'Habis',
                      value: 'out_of_stock',
                      selected: _selectedFilter == 'out_of_stock',
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = selected ? 'out_of_stock' : null;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Active Status Filter
                Text(
                  'Status Aktif',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip(
                      label: 'Semua',
                      value: null,
                      selected: _isActiveFilter == null,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _isActiveFilter = null);
                        }
                      },
                    ),
                    _buildFilterChip(
                      label: 'Aktif',
                      value: true,
                      selected: _isActiveFilter == true,
                      onSelected: (selected) {
                        setState(() {
                          _isActiveFilter = selected ? true : null;
                        });
                      },
                    ),
                    _buildFilterChip(
                      label: 'Tidak Aktif',
                      value: false,
                      selected: _isActiveFilter == false,
                      onSelected: (selected) {
                        setState(() {
                          _isActiveFilter = selected ? false : null;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Apply Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onFilterChanged(_selectedFilter, _isActiveFilter);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Terapkan Filter',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Add bottom padding for safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required dynamic value,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.3),
      ),
    );
  }
}
