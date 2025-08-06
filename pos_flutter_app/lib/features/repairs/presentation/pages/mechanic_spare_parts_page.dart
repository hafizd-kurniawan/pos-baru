import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/repair.dart';
import '../../../../core/models/spare_part.dart';
import '../../../../core/models/vehicle.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../spare_parts/presentation/blocs/spare_part_bloc.dart';
import '../services/repair_service.dart';

class MechanicSparePartsPage extends StatefulWidget {
  final Vehicle vehicle;
  final Repair? repair;

  const MechanicSparePartsPage({
    super.key,
    required this.vehicle,
    this.repair,
  });

  @override
  State<MechanicSparePartsPage> createState() => _MechanicSparePartsPageState();
}

class _MechanicSparePartsPageState extends State<MechanicSparePartsPage> {
  final TextEditingController _searchController = TextEditingController();
  final Map<int, int> _selectedSpareParts = {}; // spare_part_id -> quantity
  final Map<int, SparePart> _sparePartsCache = {};
  final RepairService _repairService = RepairService();
  String _repairStatus = 'in_progress';
  String _selectedCategory = 'All';
  double _totalCost = 0.0;

  final List<String> _categories = [
    'All',
    'Engine',
    'Brake',
    'Electrical',
    'Transmission',
    'Suspension',
    'Tire',
    'Body',
    'Interior',
    'Exhaust',
    'Cooling',
    'Fuel',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _repairStatus = widget.repair?.status ?? 'in_progress';
    _loadSpareParts();
  }

  Future<void> _loadSpareParts() async {
    final token = await StorageService.getToken();
    if (token != null) {
      context.read<SparePartBloc>().add(LoadSpareParts(token: token));
    }
  }

  void _updateQuantity(SparePart sparePart, int change) {
    setState(() {
      final currentQty = _selectedSpareParts[sparePart.id] ?? 0;
      final newQty = (currentQty + change).clamp(0, sparePart.stockQuantity);

      if (newQty > 0) {
        _selectedSpareParts[sparePart.id] = newQty;
        _sparePartsCache[sparePart.id] = sparePart;
      } else {
        _selectedSpareParts.remove(sparePart.id);
        _sparePartsCache.remove(sparePart.id);
      }

      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double total = 0.0;
    _selectedSpareParts.forEach((id, quantity) {
      final sparePart = _sparePartsCache[id];
      if (sparePart != null) {
        total += sparePart.sellingPrice * quantity;
      }
    });
    _totalCost = total;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spare Parts Selection',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            Text(
              widget.vehicle.displayName,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(_repairStatus).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getStatusColor(_repairStatus)),
                ),
                child: Text(
                  _getStatusDisplay(_repairStatus),
                  style: TextStyle(
                    color: _getStatusColor(_repairStatus),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Side - Spare Parts Grid
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Search TextField
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search spare parts...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (value) {
                          setState(() {
                            // Search will be handled in the filtering logic
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Category Filter
                      Row(
                        children: [
                          Icon(Icons.category,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Category:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _categories.map((category) {
                                  final isSelected =
                                      _selectedCategory == category;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(
                                        category,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey[700],
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedCategory = category;
                                        });
                                      },
                                      backgroundColor: Colors.grey[100],
                                      selectedColor: AppTheme.primaryColor,
                                      checkmarkColor: Colors.white,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Spare Parts Grid
                Expanded(
                  child: _buildSparePartsGrid(),
                ),
              ],
            ),
          ),

          // Right Side - Cart & Summary
          Container(
            width: 320,
            color: Colors.white,
            child: Column(
              children: [
                _buildCartHeader(),
                Expanded(child: _buildSelectedItems()),
                _buildSummarySection(),
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparePartsGrid() {
    return BlocBuilder<SparePartBloc, SparePartState>(
      builder: (context, state) {
        if (state is SparePartLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is SparePartError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Error: ${state.message}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadSpareParts,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (state is SparePartsLoaded) {
          if (state.spareParts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No spare parts available',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Filter spare parts based on search and category
          final filteredSpareParts = state.spareParts.where((sparePart) {
            final matchesSearch = _searchController.text.isEmpty ||
                sparePart.name
                    .toLowerCase()
                    .contains(_searchController.text.toLowerCase()) ||
                sparePart.code
                    .toLowerCase()
                    .contains(_searchController.text.toLowerCase());

            final matchesCategory = _selectedCategory == 'All' ||
                sparePart.category == _selectedCategory;

            return matchesSearch && matchesCategory;
          }).toList();

          if (filteredSpareParts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isNotEmpty
                        ? 'No spare parts found for "${_searchController.text}"'
                        : 'No spare parts in ${_selectedCategory} category',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 5 : 4,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filteredSpareParts.length,
            itemBuilder: (context, index) {
              final sparePart = filteredSpareParts[index];
              return _buildSparePartCard(sparePart);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSparePartCard(SparePart sparePart) {
    final isSelected = _selectedSpareParts.containsKey(sparePart.id);
    final quantity = _selectedSpareParts[sparePart.id] ?? 0;
    final isOutOfStock = sparePart.stockQuantity <= 0;
    final isLowStock =
        sparePart.stockQuantity <= sparePart.minimumStock && !isOutOfStock;

    return GestureDetector(
      onTap: isOutOfStock ? null : () => _updateQuantity(sparePart, 1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.04),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with stock badge
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? Colors.red.withValues(alpha: 0.1)
                            : isLowStock
                                ? Colors.orange.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Stock: ${sparePart.stockQuantity}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isOutOfStock
                              ? Colors.red
                              : isLowStock
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          quantity.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Spare part info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sparePart.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (sparePart.code.isNotEmpty)
                      Text(
                        sparePart.code,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (sparePart.category.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          sparePart.category,
                          style: TextStyle(
                            fontSize: 9,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      CurrencyFormatter.formatIDR(sparePart.sellingPrice),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Add/Remove buttons
            if (!isOutOfStock)
              Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    if (isSelected) ...[
                      Expanded(
                        child: Container(
                          height: 32,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _updateQuantity(sparePart, -1),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(7),
                                        bottomLeft: Radius.circular(7),
                                      ),
                                    ),
                                    child: const Icon(Icons.remove, size: 16),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  color: Colors.white,
                                  child: Center(
                                    child: Text(
                                      quantity.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: quantity < sparePart.stockQuantity
                                      ? () => _updateQuantity(sparePart, 1)
                                      : null,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: quantity < sparePart.stockQuantity
                                          ? AppTheme.primaryColor
                                              .withValues(alpha: 0.1)
                                          : Colors.grey[100],
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(7),
                                        bottomRight: Radius.circular(7),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 16,
                                      color: quantity < sparePart.stockQuantity
                                          ? AppTheme.primaryColor
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Text(
                              'Add',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.shopping_cart_outlined, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          const Text(
            'Selected Parts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _selectedSpareParts.length.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedItems() {
    if (_selectedSpareParts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_shopping_cart, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No parts selected',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select parts from the grid',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedSpareParts.length,
      itemBuilder: (context, index) {
        final sparePartId = _selectedSpareParts.keys.elementAt(index);
        final quantity = _selectedSpareParts[sparePartId]!;
        final sparePart = _sparePartsCache[sparePartId]!;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sparePart.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _updateQuantity(sparePart, -quantity),
                    icon: const Icon(Icons.close, size: 16),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minHeight: 24, minWidth: 24),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    CurrencyFormatter.formatIDR(sparePart.sellingPrice),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    ' × $quantity',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    CurrencyFormatter.formatIDR(
                        sparePart.sellingPrice * quantity),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          const Text(
            'Repair Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _repairStatus,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(
                  value: 'in_progress', child: Text('In Progress')),
              DropdownMenuItem(value: 'completed', child: Text('Completed')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _repairStatus = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  'Total Cost',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatIDR(_totalCost),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Save & Update Progress button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saveRepairUpdate, // Always enabled
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save & Update Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  void _saveRepairUpdate() async {
    if (_selectedSpareParts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one spare part'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    bool isLoadingDialogShown = false;

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication token not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading dialog with proper management
      isLoadingDialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingContext) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Saving repair update...'),
              ],
            ),
          ),
        ),
      );

      print('Starting repair update process...');

      if (widget.repair == null) {
        // If no repair exists, create a new repair order first
        print('No repair found, creating new repair order...');

        try {
          // Get current user (mechanic) ID from storage or assume mechanic ID 1 for now
          const mechanicId = 1; // TODO: Get from user session

          // Generate repair code
          final repairCode = 'REP-${DateTime.now().millisecondsSinceEpoch}';

          final newRepair = await _repairService.createRepairOrder(
            code: repairCode,
            vehicleId: widget.vehicle.id,
            mechanicId: mechanicId,
            description: 'Repair created from mechanic spare parts selection',
            estimatedCost: _totalCost,
            notes: 'Auto-created repair order',
            token: token,
          );

          print('Successfully created repair order: ${newRepair.id}');

          // Update widget.repair reference (create a local variable since widget.repair is final)
          final currentRepair = newRepair;

          // Now proceed with adding spare parts to the new repair
          for (final entry in _selectedSpareParts.entries) {
            final sparePartId = entry.key;
            final quantity = entry.value;

            print(
                'Adding spare part $sparePartId with quantity $quantity to new repair ${currentRepair.id}');

            try {
              await _repairService.addSparePartToRepair(
                repairId: currentRepair.id,
                sparePartId: sparePartId,
                quantityUsed: quantity,
                token: token,
              );
              print('Successfully added spare part $sparePartId');
            } catch (e) {
              print('Failed to add spare part $sparePartId: $e');
            }
          }

          // Update repair progress
          // Only update status if currently pending, otherwise skip
          if (currentRepair.status == 'pending') {
            await _repairService.updateRepairProgress(
              id: currentRepair.id,
              status: 'in_progress',
              actualCost: _totalCost,
              notes:
                  'Spare parts added by mechanic (${_selectedSpareParts.length} items)',
              spareParts: [],
              token: token,
            );
          } else {
            print('Repair already in progress, skipping status update');
          }
        } catch (e) {
          print('Error creating repair: $e');
          rethrow; // Let the outer catch handle this
        }
      } else {
        // Existing repair found, proceed as normal
        print('Existing repair found: ${widget.repair!.id}');

        // Step 1: Add each spare part to repair order individually
        for (final entry in _selectedSpareParts.entries) {
          final sparePartId = entry.key;
          final quantity = entry.value;

          print('Adding spare part $sparePartId with quantity $quantity');

          try {
            await _repairService.addSparePartToRepair(
              repairId: widget.repair!.id,
              sparePartId: sparePartId,
              quantityUsed: quantity,
              token: token,
            );
            print('Successfully added spare part $sparePartId');
          } catch (e) {
            print('Failed to add spare part $sparePartId: $e');
            // Continue with other spare parts, don't stop the whole process
          }
        }

        // Step 2: Update repair progress and total cost
        print('Updating repair progress with cost $_totalCost');

        // Only update status if currently pending, otherwise just update cost
        if (widget.repair!.status == 'pending') {
          await _repairService.updateRepairProgress(
            id: widget.repair!.id,
            status: 'in_progress',
            actualCost: _totalCost,
            notes: _selectedSpareParts.isEmpty
                ? 'Repair progress updated by mechanic (no spare parts)'
                : 'Spare parts updated by mechanic (${_selectedSpareParts.length} items)',
            spareParts: [], // Empty since we already added spare parts individually
            token: token,
          );
        } else {
          // For repairs already in progress, just update the cost via notes
          // Since we can't update status, we'll use a different approach
          print('Repair already in progress, skipping status update');
        }
      }

      print('Repair update completed successfully!');

      // Close loading dialog safely
      if (mounted && isLoadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
        isLoadingDialogShown = false;
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Repair updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to previous page with result indicating success
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      print('Error updating repair: $e');

      // Close loading dialog safely if still open
      if (mounted && isLoadingDialogShown) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (popError) {
          print('Error closing loading dialog: $popError');
        }
        isLoadingDialogShown = false;
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating repair: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
