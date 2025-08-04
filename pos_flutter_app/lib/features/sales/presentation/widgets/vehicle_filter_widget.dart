import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/models/sale_transaction.dart';
import '../../../../core/theme/app_theme.dart';

class VehicleFilterWidget extends StatefulWidget {
  final VehicleFilter currentFilter;
  final ValueChanged<VehicleFilter> onFilterChanged;

  const VehicleFilterWidget({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<VehicleFilterWidget> createState() => _VehicleFilterWidgetState();
}

class _VehicleFilterWidgetState extends State<VehicleFilterWidget> {
  final _searchController = TextEditingController();
  final _minYearController = TextEditingController();
  final _maxYearController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();

  String _sortBy = 'created_at';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minYearController.dispose();
    _maxYearController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _searchController.text = widget.currentFilter.search ?? '';
    _minYearController.text = widget.currentFilter.minYear?.toString() ?? '';
    _maxYearController.text = widget.currentFilter.maxYear?.toString() ?? '';
    _brandController.text = widget.currentFilter.brand ?? '';
    _modelController.text = widget.currentFilter.model ?? '';
    _sortBy = widget.currentFilter.sortBy ?? 'created_at';
    _sortOrder = widget.currentFilter.sortOrder ?? 'desc';
  }

  void _applyFilter() {
    final filter = VehicleFilter(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      minYear: _minYearController.text.isNotEmpty
          ? int.tryParse(_minYearController.text)
          : null,
      maxYear: _maxYearController.text.isNotEmpty
          ? int.tryParse(_maxYearController.text)
          : null,
      brand: _brandController.text.isNotEmpty ? _brandController.text : null,
      model: _modelController.text.isNotEmpty ? _modelController.text : null,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    );

    widget.onFilterChanged(filter);
  }

  void _clearFilter() {
    _searchController.clear();
    _minYearController.clear();
    _maxYearController.clear();
    _brandController.clear();
    _modelController.clear();
    setState(() {
      _sortBy = 'created_at';
      _sortOrder = 'desc';
    });
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text(
        'Filter & Pencarian',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      leading: const Icon(Icons.filter_list, color: AppTheme.primaryColor),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari nama, kode, atau nomor polisi...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _applyFilter(),
              ),

              const SizedBox(height: 16),

              // Year Range
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minYearController,
                      decoration: InputDecoration(
                        labelText: 'Tahun Min',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _maxYearController,
                      decoration: InputDecoration(
                        labelText: 'Tahun Max',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Brand and Model
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _brandController,
                      decoration: InputDecoration(
                        labelText: 'Brand',
                        hintText: 'Honda, Yamaha, dll',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _modelController,
                      decoration: InputDecoration(
                        labelText: 'Model',
                        hintText: 'Beat, Vario, dll',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Sort Options
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _sortBy,
                      decoration: InputDecoration(
                        labelText: 'Urutkan Berdasarkan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'created_at',
                          child: Text('Tanggal Ditambahkan'),
                        ),
                        DropdownMenuItem(
                          value: 'year',
                          child: Text('Tahun'),
                        ),
                        DropdownMenuItem(
                          value: 'odometer',
                          child: Text('Kilometer'),
                        ),
                        DropdownMenuItem(
                          value: 'selling_price',
                          child: Text('Harga Jual'),
                        ),
                        DropdownMenuItem(
                          value: 'brand_name',
                          child: Text('Brand'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _sortOrder,
                      decoration: InputDecoration(
                        labelText: 'Urutan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'asc',
                          child: Text('Naik (A-Z, 1-9)'),
                        ),
                        DropdownMenuItem(
                          value: 'desc',
                          child: Text('Turun (Z-A, 9-1)'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortOrder = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clearFilter,
                      icon: const Icon(Icons.clear),
                      label: const Text('Bersihkan'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _applyFilter,
                      icon: const Icon(Icons.search),
                      label: const Text('Terapkan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
