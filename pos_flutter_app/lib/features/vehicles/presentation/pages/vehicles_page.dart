import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/models/vehicle.dart';
import '../../../../core/theme/app_theme.dart';
import '../blocs/vehicle_bloc.dart';
import '../widgets/enhanced_vehicle_card.dart';
import '../widgets/vehicle_filter_chips.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  String? selectedStatus;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasMore = true;
  int _currentPage = 1;
  List<Vehicle> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadVehicles({bool refresh = false}) {
    if (refresh) {
      _currentPage = 1;
      _vehicles.clear();
    }

    context.read<VehicleBloc>().add(LoadVehicles(
          page: _currentPage,
          limit: 20,
          status: selectedStatus,
        ));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        _hasMore) {
      _currentPage++;
      _loadVehicles();
    }
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      selectedStatus = status;
    });
    _loadVehicles(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manajemen Kendaraan',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kelola inventori kendaraan showroom',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.addVehicle),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Tambah Kendaraan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search and Filter Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari kendaraan...',
                      prefixIcon: const Icon(Icons.search,
                          color: AppTheme.textSecondary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: AppTheme.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                _loadVehicles(refresh: true);
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    onSubmitted: (_) => _loadVehicles(refresh: true),
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips
                  VehicleFilterChips(
                    selectedStatus: selectedStatus,
                    onStatusChanged: _onStatusFilterChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Vehicles List
            Expanded(
              child: BlocConsumer<VehicleBloc, VehicleState>(
                listener: (context, state) {
                  if (state is VehicleError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else if (state is VehicleOperationSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadVehicles(refresh: true);
                  }
                },
                builder: (context, state) {
                  if (state is VehicleLoading && _vehicles.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor),
                      ),
                    );
                  }

                  if (state is VehiclesLoaded) {
                    if (_currentPage == 1) {
                      _vehicles = state.vehicles;
                    } else {
                      _vehicles.addAll(state.vehicles);
                    }
                    _hasMore = state.hasMore;
                  }

                  if (_vehicles.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _loadVehicles(refresh: true),
                    color: AppTheme.primaryColor,
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _vehicles.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _vehicles.length) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor),
                            ),
                          );
                        }

                        final vehicle = _vehicles[index];
                        return EnhancedVehicleCard(
                          vehicle: vehicle,
                          onTap: () => _viewVehicleDetail(vehicle),
                          onEdit: () => _editVehicle(vehicle),
                          onDelete: () => _deleteVehicle(vehicle),
                          onViewDetail: () => _viewVehicleDetail(vehicle),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            selectedStatus != null
                ? 'Tidak ada kendaraan dengan status ini'
                : 'Belum ada kendaraan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedStatus != null
                ? 'Coba ubah filter atau tambah kendaraan baru'
                : 'Mulai dengan menambah kendaraan pertama',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.addVehicle),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Tambah Kendaraan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewVehicleDetail(Vehicle vehicle) {
    context.push('${AppRoutes.vehicles}/${vehicle.id}');
  }

  void _editVehicle(Vehicle vehicle) {
    context.push('${AppRoutes.vehicles}/${vehicle.id}/edit');
  }

  void _deleteVehicle(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kendaraan'),
        content: Text(
            'Apakah Anda yakin ingin menghapus kendaraan ${vehicle.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context
                  .read<VehicleBloc>()
                  .add(DeleteVehicle(vehicleId: vehicle.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
