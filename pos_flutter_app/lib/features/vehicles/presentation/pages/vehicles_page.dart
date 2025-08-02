import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../blocs/vehicle_bloc.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  @override
  void initState() {
    super.initState();
    context.read<VehicleBloc>().add(const LoadVehicles());
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
                Text(
                  'Manajemen Kendaraan',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to add vehicle
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Kendaraan'),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Content
            Expanded(
              child: BlocBuilder<VehicleBloc, VehicleState>(
                builder: (context, state) {
                  if (state is VehicleLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is VehiclesLoaded) {
                    return _buildVehiclesList(state.vehicles);
                  } else if (state is VehicleError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${state.message}',
                            style: TextStyle(color: AppTheme.errorColor),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<VehicleBloc>().add(const LoadVehicles());
                            },
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    );
                  }
                  return _buildEmptyState();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiclesList(List<dynamic> vehicles) {
    if (vehicles.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        return _buildVehicleCard();
      },
    );
  }

  Widget _buildVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.directions_car,
                size: 48,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Honda Beat 2023',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Merah • Manual',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Tersedia',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'Rp 28.000.000',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
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
          Icon(
            Icons.directions_car_outlined,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada kendaraan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan kendaraan pertama Anda',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to add vehicle
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Kendaraan'),
          ),
        ],
      ),
    );
  }
}