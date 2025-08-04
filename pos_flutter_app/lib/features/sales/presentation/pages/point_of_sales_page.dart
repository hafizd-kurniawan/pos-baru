import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/customer.dart';
import '../../../../core/models/sale_transaction.dart';
import '../../../../core/models/vehicle.dart';
import '../../../../core/theme/app_theme.dart';
import '../../services/sales_service.dart';
import '../blocs/sales_bloc.dart';
import '../widgets/customer_search_widget.dart';
import '../widgets/invoice_preview_dialog.dart';

class PointOfSalesPage extends StatefulWidget {
  const PointOfSalesPage({super.key});

  @override
  State<PointOfSalesPage> createState() => _PointOfSalesPageState();
}

class _PointOfSalesPageState extends State<PointOfSalesPage> {
  Vehicle? _selectedVehicle;
  Customer? _selectedCustomer;
  VehicleFilter _currentFilter = const VehicleFilter();

  final _paymentFormKey = GlobalKey<FormState>();
  final _sellingPriceController = TextEditingController();
  final _downPaymentController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  final _yearFromController = TextEditingController();
  final _yearToController = TextEditingController();

  String _selectedPaymentMethod = 'cash';
  String _selectedPaymentStatus = 'paid';
  DateTime _transactionDate = DateTime.now();

  String? _selectedBrand;
  String? _selectedVehicleType;
  List<String> _availableBrands = [];
  List<String> _vehicleTypes = ['motorcycle', 'car', 'truck'];

  @override
  void initState() {
    super.initState();
    _loadAvailableVehicles();
    _loadVehicleBrands();
  }

  @override
  void dispose() {
    _sellingPriceController.dispose();
    _downPaymentController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    _yearFromController.dispose();
    _yearToController.dispose();
    super.dispose();
  }

  void _loadAvailableVehicles() {
    context
        .read<SalesBloc>()
        .add(LoadAvailableVehiclesForSale(filter: _currentFilter));
  }

  void _loadVehicleBrands() {
    context.read<SalesBloc>().add(LoadVehicleBrands());
  }

  void _onFilterChanged(VehicleFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
    _loadAvailableVehicles();
  }

  void _updateFilter() {
    final newFilter = VehicleFilter(
      search: _searchController.text.isEmpty ? null : _searchController.text,
      brand: _selectedBrand,
      type: _selectedVehicleType,
      minYear: _yearFromController.text.isEmpty
          ? null
          : int.tryParse(_yearFromController.text),
      maxYear: _yearToController.text.isEmpty
          ? null
          : int.tryParse(_yearToController.text),
      sortBy: _currentFilter.sortBy,
      sortOrder: _currentFilter.sortOrder,
    );
    
    // Debug print untuk melihat filter yang dibuat
    print('🔧 UI Filter Update:');
    print('   Search: ${newFilter.search}');
    print('   Brand: ${newFilter.brand}');
    print('   Type: ${newFilter.type}');
    print('   Min Year: ${newFilter.minYear}');
    print('   Max Year: ${newFilter.maxYear}');
    
    _onFilterChanged(newFilter);
  }

  void _resetFilters() {
    setState(() {
      _selectedBrand = null;
      _selectedVehicleType = null;
      _searchController.clear();
      _yearFromController.clear();
      _yearToController.clear();
    });
    final newFilter = const VehicleFilter();
    _onFilterChanged(newFilter);
  }

  void _onVehicleSelected(Vehicle vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
      _sellingPriceController.text = vehicle.sellingPrice?.toString() ?? '';
    });
  }

  void _onCustomerSelected(Customer? customer) {
    setState(() {
      _selectedCustomer = customer;
    });
  }

  void _resetForm() {
    setState(() {
      _selectedVehicle = null;
      _selectedCustomer = null;
      _sellingPriceController.clear();
      _downPaymentController.clear();
      _notesController.clear();
      _selectedPaymentMethod = 'cash';
      _selectedPaymentStatus = 'paid';
    });
  }

  void _showInvoicePreview(SalesTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Invoice Transaksi'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice: ${transaction.invoiceNumber ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text('Customer: ${transaction.customer?.name ?? 'N/A'}'),
                    Text('Phone: ${transaction.customer?.phone ?? 'N/A'}'),
                    const SizedBox(height: 8),
                    Text('Vehicle: ${transaction.vehicle?.brand?.name ?? 'N/A'} ${transaction.vehicle?.model ?? 'N/A'}'),
                    Text('Plat: ${transaction.vehicle?.licensePlate ?? 'N/A'}'),
                    Text('Tahun: ${transaction.vehicle?.year ?? 'N/A'}'),
                    const SizedBox(height: 8),
                    Text('Harga Jual: Rp ${_formatCurrency(transaction.sellingPrice)}'),
                    Text('Down Payment: Rp ${_formatCurrency(transaction.downPayment)}'),
                    Text('Sisa Bayar: Rp ${_formatCurrency(transaction.remainingPayment)}'),
                    Text('Metode: ${transaction.paymentMethod ?? 'N/A'}'),
                    Text('Status: ${transaction.paymentStatus}'),
                    if (transaction.notes != null && transaction.notes!.isNotEmpty) 
                      Text('Catatan: ${transaction.notes}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showPrintConfirmation(transaction);
            },
            icon: const Icon(Icons.print),
            label: const Text('Cetak Invoice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrintConfirmation(SalesTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cetak Invoice?'),
        content: const Text('Apakah Anda ingin mencetak invoice sekarang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _printInvoice(transaction);
            },
            child: const Text('Ya, Cetak'),
          ),
        ],
      ),
    );
  }

  void _printInvoice(dynamic transaction) {
    // Handle both SalesTransaction and SaleTransaction
    Navigator.of(context).pop(); // Close dialog first if called from dialog
    
    // TODO: Implement actual printing logic
    _showSnackBar('Invoice akan dicetak... (Fitur printing belum diimplementasi)');
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  void _processSale() async {
    if (_selectedVehicle == null) {
      _showSnackBar('Pilih kendaraan terlebih dahulu', isError: true);
      return;
    }

    if (_selectedCustomer == null) {
      _showSnackBar('Pilih atau daftarkan customer terlebih dahulu',
          isError: true);
      return;
    }

    if (!_paymentFormKey.currentState!.validate()) {
      return;
    }

    try {
      // Show loading
      _showSnackBar('Memproses transaksi...');

      final salesService = context.read<SalesService>();
      
      final salesTransaction = await salesService.createTransaction(
        customerId: _selectedCustomer!.id,
        vehicleId: _selectedVehicle!.id,
        sellingPrice: double.parse(_sellingPriceController.text),
        paymentMethod: _selectedPaymentMethod,
        paymentStatus: _selectedPaymentStatus,
        downPayment: _downPaymentController.text.isNotEmpty
            ? double.parse(_downPaymentController.text)
            : 0.0,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Show success message
      _showSnackBar('Transaksi berhasil dibuat! Invoice: ${salesTransaction.invoiceNumber}');
      
      // Show invoice dialog
      _showInvoicePreview(salesTransaction);
      
      // Reset form
      _resetForm();
      
      // Reload vehicles
      _loadAvailableVehicles();
      
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildModernAppBar(),
      body: BlocListener<SalesBloc, SalesState>(
        listener: (context, state) {
          if (state is SaleCreated) {
            _onTransactionCompleted(state.sale);
            _loadAvailableVehicles();
          } else if (state is SalesError) {
            _showSnackBar(state.message, isError: true);
          } else if (state is VehicleBrandsLoaded) {
            setState(() {
              // Reset selected brand jika tidak ada dalam list baru
              if (_selectedBrand != null &&
                  !state.brands.contains(_selectedBrand)) {
                _selectedBrand = null;
              }
              // Only update if brands are different to avoid unnecessary rebuilds
              if (_availableBrands != state.brands) {
                _availableBrands = List.from(state.brands); // Create a copy
              }
            });
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildModernFilterBar(),
                const SizedBox(height: 20),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: _buildVehiclePanel(),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 3,
                        child: _buildTransactionPanel(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Point of Sales',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Sistem Penjualan Kendaraan',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                BlocBuilder<SalesBloc, SalesState>(
                  builder: (context, state) {
                    if (state is AvailableVehiclesLoaded) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          '${state.vehicles.length} Units',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernFilterBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.filter_list_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    // Badge indicator for active filters
                    if (_hasActiveFilters())
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _getActiveFilterCount().toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter & Pencarian Kendaraan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Temukan kendaraan berdasarkan kriteria yang diinginkan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withValues(alpha: 0.1),
                          Colors.orange.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.2),
                      ),
                    ),
                    child: IconButton(
                      onPressed: _resetFilters,
                      icon: const Icon(
                        Icons.clear_all_rounded,
                        color: Colors.orange,
                        size: 22,
                      ),
                      tooltip: 'Reset Filter',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.1),
                          AppTheme.primaryColor.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: IconButton(
                      onPressed: _loadAvailableVehicles,
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: AppTheme.primaryColor,
                        size: 22,
                      ),
                      tooltip: 'Refresh Data',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[50]!,
                  Colors.white,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _updateFilter(),
              decoration: InputDecoration(
                hintText:
                    'Cari berdasarkan nama, model, atau merek kendaraan...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildBrandDropdown(),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildVehicleTypeDropdown(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildYearInput(
                  controller: _yearFromController,
                  label: 'Tahun Dari',
                  hint: '2020',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 2,
                width: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildYearInput(
                  controller: _yearToController,
                  label: 'Tahun Sampai',
                  hint: '2024',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandDropdown() {
    // Pastikan _selectedBrand valid atau reset ke null jika tidak ada dalam list
    if (_selectedBrand != null &&
        _availableBrands.isNotEmpty &&
        !_availableBrands.contains(_selectedBrand)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedBrand = null;
        });
      });
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _availableBrands.isNotEmpty &&
                _availableBrands.contains(_selectedBrand)
            ? _selectedBrand
            : null,
        decoration: InputDecoration(
          labelText: 'Merek Kendaraan',
          labelStyle: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.branding_watermark_rounded,
              color: Colors.blue,
              size: 18,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        hint: Text(
          _availableBrands.isEmpty ? 'Memuat merek...' : 'Pilih Merek',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
        ),
        items: _availableBrands.isEmpty
            ? [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Memuat merek...'),
                ),
              ]
            : [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(
                        Icons.apps,
                        size: 16,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 8),
                      Text('🏪 Semua Merek'),
                    ],
                  ),
                ),
                ..._availableBrands.map((brand) => DropdownMenuItem<String>(
                      value: brand,
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 16,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              brand,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
        onChanged: _availableBrands.isEmpty
            ? null
            : (value) {
                setState(() {
                  _selectedBrand = value;
                });
                _updateFilter();
              },
        dropdownColor: Colors.white,
        elevation: 8,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildVehicleTypeDropdown() {
    Map<String, String> typeLabels = {
      'motorcycle': '🏍️ Motor',
      'car': '🚗 Mobil',
      'truck': '🚛 Truck',
    };

    // Pastikan _selectedVehicleType valid atau reset ke null jika tidak ada dalam list
    if (_selectedVehicleType != null &&
        !_vehicleTypes.contains(_selectedVehicleType)) {
      _selectedVehicleType = null;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedVehicleType,
        decoration: InputDecoration(
          labelText: 'Jenis Kendaraan',
          labelStyle: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.category_rounded,
              color: Colors.green,
              size: 18,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        hint: Text(
          'Pilih Jenis',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('🌟 Semua Jenis'),
          ),
          ..._vehicleTypes.map((type) => DropdownMenuItem<String>(
                value: type,
                child: Text(typeLabels[type] ?? type),
              )),
        ],
        onChanged: (value) {
          setState(() {
            _selectedVehicleType = value;
          });
          _updateFilter();
        },
        dropdownColor: Colors.white,
        elevation: 8,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildYearInput({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: (value) => _updateFilter(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: Colors.purple,
              size: 16,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildVehiclePanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.directions_car_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Pilih Kendaraan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<SalesBloc, SalesState>(
              builder: (context, state) {
                if (state is SalesLoading) {
                  return _buildLoadingState();
                } else if (state is AvailableVehiclesLoaded) {
                  // Apply client-side filtering as backup
                  List<Vehicle> filteredVehicles = _applyClientSideFilter(state.vehicles);
                  
                  if (filteredVehicles.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildVehicleGrid(filteredVehicles);
                } else if (state is SalesError) {
                  return _buildErrorState(state.message);
                }
                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Memuat kendaraan...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tidak ada kendaraan tersedia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Silakan tambah kendaraan baru atau ubah filter',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Terjadi Kesalahan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAvailableVehicles,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[500],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleGrid(List<Vehicle> vehicles) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 0.75, // Adjusted ratio for better card proportions
        ),
        itemCount: vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = vehicles[index];
          final isSelected = _selectedVehicle?.id == vehicle.id;

          return _buildVehicleCard(vehicle, isSelected);
        },
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle, bool isSelected) {
    // Helper function untuk deteksi jenis kendaraan yang lebih akurat
    IconData getVehicleIcon(String? brandName, String? model) {
      final brandLower = brandName?.toLowerCase() ?? '';
      final modelLower = model?.toLowerCase() ?? '';
      
      // Daftar brand motor
      List<String> motorBrands = [
        'honda', 'yamaha', 'suzuki', 'kawasaki', 'ducati', 'harley', 
        'ktm', 'benelli', 'sym', 'piaggio', 'vespa'
      ];
      
      // Daftar model motor
      List<String> motorModels = [
        'beat', 'vario', 'scoopy', 'cbr', 'pcx', 'nmax', 'aerox', 
        'mio', 'jupiter', 'satria', 'gsx', 'ninja', 'klx', 'trail',
        'matic', 'bebek', 'sport', 'naked', 'touring', 'enduro'
      ];
      
      // Daftar model mobil
      List<String> carModels = [
        'avanza', 'xenia', 'innova', 'fortuner', 'rush', 'terios',
        'brio', 'jazz', 'city', 'civic', 'accord', 'crv', 'hrv',
        'livina', 'grand', 'march', 'juke', 'xtrail', 'serena',
        'pajero', 'outlander', 'mirage', 'lancer', 'montero',
        'sedan', 'hatchback', 'suv', 'mpv', 'crossover'
      ];
      
      // Daftar model truck/commercial
      List<String> truckModels = [
        'truck', 'pickup', 'colt', 'engkel', 'tronton', 'fuso',
        'hino', 'isuzu', 'dyna', 'dutro', 'elf', 'giga', 'ranger',
        'hilux', 'navara', 'triton', 'strada', 'commercial'
      ];
      
      // Prioritas deteksi: model dulu, baru brand
      // Cek truck/commercial vehicle
      for (String truckModel in truckModels) {
        if (modelLower.contains(truckModel) || brandLower.contains(truckModel)) {
          return Icons.local_shipping;
        }
      }
      
      // Cek motor
      for (String motorModel in motorModels) {
        if (modelLower.contains(motorModel)) {
          return Icons.two_wheeler;
        }
      }
      
      for (String motorBrand in motorBrands) {
        if (brandLower.contains(motorBrand)) {
          // Double check: pastikan bukan mobil dari brand yang sama
          bool isCarModel = carModels.any((carModel) => modelLower.contains(carModel));
          if (!isCarModel) {
            return Icons.two_wheeler;
          }
        }
      }
      
      // Default mobil
      return Icons.directions_car;
    }

    // Helper function untuk warna berdasarkan jenis kendaraan
    Color getVehicleColor(String? brandName, String? model) {
      final icon = getVehicleIcon(brandName, model);
      
      switch (icon) {
        case Icons.two_wheeler:
          return Colors.orange;
        case Icons.local_shipping:
          return Colors.green;
        case Icons.directions_car:
        default:
          return Colors.blue;
      }
    }

    final vehicleColor = getVehicleColor(vehicle.brand?.name, vehicle.model);

    return GestureDetector(
      onTap: () => _onVehicleSelected(vehicle),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: isSelected ? 20 : 12,
              offset: Offset(0, isSelected ? 6 : 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan status dan brand
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    vehicleColor.withValues(alpha: 0.1),
                    vehicleColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: vehicleColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      getVehicleIcon(vehicle.brand?.name, vehicle.model),
                      size: 24,
                      color: vehicleColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.brand?.name ?? 'Unknown Brand',
                          style: TextStyle(
                            fontSize: 11,
                            color: vehicleColor.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: vehicle.status == 'available'
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vehicle.status == 'available'
                                ? 'TERSEDIA'
                                : vehicle.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 8,
                              color: vehicle.status == 'available'
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Vehicle details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Model name
                    Text(
                      vehicle.model,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Vehicle specs row
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vehicle.year.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (vehicle.color != null) ...[
                          Icon(
                            Icons.palette,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              vehicle.color!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Engine & Fuel info
                    if (vehicle.engineCapacity != null ||
                        vehicle.fuelType != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (vehicle.engineCapacity != null) ...[
                            Icon(
                              Icons.speed,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              vehicle.engineCapacity!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (vehicle.engineCapacity != null &&
                              vehicle.fuelType != null)
                            const SizedBox(width: 8),
                          if (vehicle.fuelType != null) ...[
                            Icon(
                              Icons.local_gas_station,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                vehicle.fuelType!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    const Spacer(),

                    // Price section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Harga Jual',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Rp ${_formatPrice(vehicle.sellingPrice ?? 0)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.primaryColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Detail Transaksi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _selectedVehicle == null
                  ? _buildSelectPrompt()
                  : _buildTransactionForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.touch_app_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Pilih Kendaraan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Silakan pilih kendaraan yang akan dijual',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionForm() {
    return Form(
      key: _paymentFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectedVehicleInfo(),
            const SizedBox(height: 24),
            _buildCustomerSelection(),
            const SizedBox(height: 24),
            _buildPriceFields(),
            const SizedBox(height: 24),
            _buildPaymentDetails(),
            const SizedBox(height: 24),
            _buildNotesField(),
            const SizedBox(height: 32),
            _buildProcessButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedVehicleInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Kendaraan Terpilih',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_selectedVehicle!.brand?.name ?? 'Unknown'} ${_selectedVehicle!.model}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tahun ${_selectedVehicle!.year}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        CustomerSearchWidget(
          selectedCustomer: _selectedCustomer,
          onCustomerSelected: _onCustomerSelected,
        ),
      ],
    );
  }

  Widget _buildPriceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Harga & Pembayaran',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _sellingPriceController,
          decoration: InputDecoration(
            labelText: 'Harga Jual',
            prefixText: 'Rp ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Harga jual harus diisi';
            }
            if (double.tryParse(value) == null) {
              return 'Harga tidak valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _downPaymentController,
          decoration: InputDecoration(
            labelText: 'Uang Muka (Opsional)',
            prefixText: 'Rp ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (double.tryParse(value) == null) {
                return 'Jumlah tidak valid';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detail Pembayaran',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedPaymentMethod,
          decoration: InputDecoration(
            labelText: 'Metode Pembayaran',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: const [
            DropdownMenuItem(value: 'cash', child: Text('Tunai')),
            DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
            DropdownMenuItem(value: 'credit', child: Text('Kredit')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedPaymentStatus,
          decoration: InputDecoration(
            labelText: 'Status Pembayaran',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: const [
            DropdownMenuItem(value: 'paid', child: Text('Lunas')),
            DropdownMenuItem(value: 'partial', child: Text('Sebagian')),
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedPaymentStatus = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catatan (Opsional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: 'Tambahkan catatan...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildProcessButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: BlocBuilder<SalesBloc, SalesState>(
        builder: (context, state) {
          final isLoading = state is SalesLoading;

          return ElevatedButton.icon(
            onPressed: isLoading ? null : _processSale,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.point_of_sale_rounded),
            label: Text(
              isLoading ? 'Memproses...' : 'Proses Penjualan',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          );
        },
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  // Client-side filtering sebagai fallback jika server-side filtering tidak bekerja
  List<Vehicle> _applyClientSideFilter(List<Vehicle> vehicles) {
    return vehicles.where((vehicle) {
      // Filter berdasarkan search text
      if (_searchController.text.isNotEmpty) {
        final searchText = _searchController.text.toLowerCase();
        final brandName = vehicle.brand?.name.toLowerCase() ?? '';
        final model = vehicle.model.toLowerCase();
        final licensePlate = vehicle.licensePlate?.toLowerCase() ?? '';
        
        if (!brandName.contains(searchText) && 
            !model.contains(searchText) && 
            !licensePlate.contains(searchText)) {
          return false;
        }
      }
      
      // Filter berdasarkan brand
      if (_selectedBrand != null && _selectedBrand!.isNotEmpty) {
        final vehicleBrand = vehicle.brand?.name.toLowerCase() ?? '';
        if (vehicleBrand != _selectedBrand!.toLowerCase()) {
          return false;
        }
      }
      
      // Filter berdasarkan vehicle type
      if (_selectedVehicleType != null && _selectedVehicleType!.isNotEmpty) {
        // Deteksi jenis kendaraan berdasarkan brand dan model
        final brandLower = vehicle.brand?.name.toLowerCase() ?? '';
        final modelLower = vehicle.model.toLowerCase();
        
        switch (_selectedVehicleType!.toLowerCase()) {
          case 'motorcycle':
            List<String> motorBrands = ['honda', 'yamaha', 'suzuki', 'kawasaki', 'ducati'];
            List<String> motorModels = ['beat', 'vario', 'scoopy', 'cbr', 'pcx', 'nmax', 'aerox', 'mio'];
            
            bool isMotorcycle = motorBrands.any((brand) => brandLower.contains(brand)) ||
                               motorModels.any((model) => modelLower.contains(model));
            if (!isMotorcycle) return false;
            break;
            
          case 'car':
            List<String> truckModels = ['truck', 'pickup', 'colt', 'engkel', 'tronton'];
            List<String> motorModels = ['beat', 'vario', 'scoopy', 'cbr', 'pcx', 'nmax', 'aerox', 'mio'];
            
            bool isTruck = truckModels.any((model) => modelLower.contains(model));
            bool isMotorcycle = motorModels.any((model) => modelLower.contains(model));
            
            if (isTruck || isMotorcycle) return false;
            break;
            
          case 'truck':
            List<String> truckModels = ['truck', 'pickup', 'colt', 'engkel', 'tronton', 'fuso', 'hino'];
            bool isTruck = truckModels.any((model) => modelLower.contains(model));
            if (!isTruck) return false;
            break;
        }
      }
      
      // Filter berdasarkan tahun
      if (_yearFromController.text.isNotEmpty) {
        final minYear = int.tryParse(_yearFromController.text);
        if (minYear != null && vehicle.year < minYear) {
          return false;
        }
      }
      
      if (_yearToController.text.isNotEmpty) {
        final maxYear = int.tryParse(_yearToController.text);
        if (maxYear != null && vehicle.year > maxYear) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  void _onTransactionCompleted(SaleTransaction sale) {
    // Reset form after successful transaction
    setState(() {
      _selectedVehicle = null;
      _selectedCustomer = null;
      _sellingPriceController.clear();
      _downPaymentController.clear();
      _notesController.clear();
      _selectedPaymentMethod = 'cash';
      _selectedPaymentStatus = 'paid';
      _transactionDate = DateTime.now();
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Transaksi berhasil! Invoice: ${sale.transactionCode}'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Lihat Invoice',
          textColor: Colors.white,
          onPressed: () => _showInvoiceDialog(sale),
        ),
      ),
    );

    // Auto show invoice preview
    Future.delayed(const Duration(milliseconds: 500), () {
      _showInvoiceDialog(sale);
    });
  }

  void _showInvoiceDialog(SaleTransaction sale) {
    showDialog(
      context: context,
      builder: (context) => InvoicePreviewDialog(
        sale: sale,
        onPrint: () => _printInvoice(sale),
        onGeneratePDF: () => _generatePDF(sale),
      ),
    );
  }

  void _generatePDF(SaleTransaction sale) {
    Navigator.of(context).pop(); // Close dialog first
    
    // TODO: Implement PDF generation functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.white),
            SizedBox(width: 8),
            Text('Sedang menggenerate PDF...'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _searchController.text.isNotEmpty ||
        _selectedBrand != null ||
        _yearFromController.text.isNotEmpty ||
        _yearToController.text.isNotEmpty;
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_searchController.text.isNotEmpty) count++;
    if (_selectedBrand != null) count++;
    if (_yearFromController.text.isNotEmpty) count++;
    if (_yearToController.text.isNotEmpty) count++;
    return count;
  }
}
