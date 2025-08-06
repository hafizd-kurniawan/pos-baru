import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/models/repair.dart';
import '../../../../core/models/vehicle.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../vehicles/presentation/blocs/vehicle_bloc.dart';
import '../blocs/repair_bloc.dart';

class RepairsPage extends StatefulWidget {
  const RepairsPage({super.key});

  @override
  State<RepairsPage> createState() => _RepairsPageState();
}

class _RepairsPageState extends State<RepairsPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  final Map<String, int> _statusCounts = {
    'in_progress': 0,
    'pending': 0,
    'completed': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final token = await StorageService.getToken();
    if (token != null) {
      // Load vehicles with in_repair status and all repair orders
      context.read<VehicleBloc>().add(const LoadVehicles(status: 'in_repair'));
      context.read<RepairBloc>().add(LoadRepairs(token: token));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Workshop Repair Management',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Dikerjakan'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go(AppRoutes.addRepair),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildRepairStatusTab('in_progress'),
          _buildRepairStatusTab('pending'),
          _buildRepairStatusTab('completed'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Cards Row
          _buildStatusCards(),
          const SizedBox(height: 24),

          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search vehicles by license plate...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              // TODO: Implement search filter
            },
          ),
          const SizedBox(height: 24),

          // Vehicles in Repair Grid
          const Text(
            'Vehicles Currently in Repair',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildVehicleGrid(),
        ],
      ),
    );
  }

  Widget _buildStatusCards() {
    return BlocBuilder<RepairBloc, RepairState>(
      builder: (context, state) {
        if (state is RepairsLoaded) {
          // Count repairs by status
          _statusCounts['in_progress'] =
              state.repairs.where((r) => r.status == 'in_progress').length;
          _statusCounts['pending'] =
              state.repairs.where((r) => r.status == 'pending').length;
          _statusCounts['completed'] =
              state.repairs.where((r) => r.status == 'completed').length;
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                'Dikerjakan',
                _statusCounts['in_progress']!,
                Icons.build,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                'Pending',
                _statusCounts['pending']!,
                Icons.pending,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                'Completed',
                _statusCounts['completed']!,
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleGrid() {
    return BlocBuilder<VehicleBloc, VehicleState>(
      builder: (context, state) {
        if (state is VehicleLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is VehicleError) {
          return Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Error loading vehicles: ${state.message}'),
              ],
            ),
          );
        } else if (state is VehiclesLoaded) {
          // Filter vehicles with in_repair status
          final inRepairVehicles = state.vehicles
              .where((vehicle) => vehicle.status == 'in_repair')
              .toList();

          if (inRepairVehicles.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.directions_car_outlined,
                      size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No vehicles currently in repair',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: inRepairVehicles.length,
            itemBuilder: (context, index) {
              final vehicle = inRepairVehicles[index];
              return _buildVehicleCard(vehicle);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'In Repair',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Vehicle Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (vehicle.licensePlate?.isNotEmpty == true)
                    Text(
                      vehicle.licensePlate!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  const Spacer(),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showVehicleRepairDetail(vehicle),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'View Repair',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairStatusTab(String status) {
    return BlocBuilder<RepairBloc, RepairState>(
      builder: (context, state) {
        if (state is RepairLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is RepairError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error: ${state.message}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (state is RepairsLoaded) {
          final filteredRepairs =
              state.repairs.where((repair) => repair.status == status).toList();

          if (filteredRepairs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.build_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No repairs with ${status.replaceAll('_', ' ')} status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredRepairs.length,
            itemBuilder: (context, index) {
              final repair = filteredRepairs[index];
              return _buildRepairCard(repair);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRepairCard(Repair repair) {
    Color statusColor;
    IconData statusIcon;

    switch (repair.status) {
      case 'in_progress':
        statusColor = Colors.orange;
        statusIcon = Icons.build;
        break;
      case 'pending':
        statusColor = Colors.blue;
        statusIcon = Icons.pending;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(statusIcon, color: statusColor, size: 28),
        ),
        title: Text(
          repair.description,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Mechanic: ${repair.mechanic?.name ?? 'Unknown Mechanic'}'),
            Text('Estimated: \$${repair.estimatedCost.toStringAsFixed(2)}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => context.go('${AppRoutes.repairs}/${repair.id}'),
      ),
    );
  }

  void _showVehicleRepairDetail(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Repair Details - ${vehicle.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('License Plate: ${vehicle.licensePlate ?? 'N/A'}'),
            Text('Status: ${vehicle.statusDisplay}'),
            const SizedBox(height: 16),
            const Text(
              'This vehicle is currently being repaired. Would you like to manage spare parts and repair progress?',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToSparePartsManagement(vehicle);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Manage Repair'),
          ),
        ],
      ),
    );
  }

  void _navigateToSparePartsManagement(Vehicle vehicle) {
    // Find the repair order for this vehicle
    Repair? relatedRepair;
    final repairState = context.read<RepairBloc>().state;
    if (repairState is RepairsLoaded) {
      relatedRepair = repairState.repairs
          .where((repair) => repair.vehicleId == vehicle.id)
          .firstOrNull;
    }

    context.go(
      AppRoutes.spareParts,
      extra: {
        'vehicle': vehicle,
        'repair': relatedRepair,
      },
    );
  }
}
