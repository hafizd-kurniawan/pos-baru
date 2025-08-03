import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/vehicle_type.dart';
import '../blocs/vehicle_type_bloc.dart';
import '../widgets/vehicle_type_form_dialog.dart';

class VehicleTypesPage extends StatefulWidget {
  const VehicleTypesPage({super.key});

  @override
  State<VehicleTypesPage> createState() => _VehicleTypesPageState();
}

class _VehicleTypesPageState extends State<VehicleTypesPage> {
  @override
  void initState() {
    super.initState();
    context.read<VehicleTypeBloc>().add(LoadVehicleTypes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Tipe Kendaraan'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showCreateDialog(),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Tambah Tipe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocListener<VehicleTypeBloc, VehicleTypeState>(
        listener: (context, state) {
          if (state is VehicleTypeOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.successColor,
              ),
            );
            context.read<VehicleTypeBloc>().add(LoadVehicleTypes());
          } else if (state is VehicleTypeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<VehicleTypeBloc>().add(LoadVehicleTypes());
          },
          child: BlocBuilder<VehicleTypeBloc, VehicleTypeState>(
            builder: (context, state) {
              if (state is VehicleTypeLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (state is VehicleTypesLoaded) {
                return _buildVehicleTypesList(state.vehicleTypes);
              }
              
              if (state is VehicleTypeError) {
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
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<VehicleTypeBloc>().add(LoadVehicleTypes());
                        },
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                );
              }
              
              return const Center(child: Text('No data available'));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleTypesList(List<VehicleType> vehicleTypes) {
    if (vehicleTypes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada tipe kendaraan',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textHint,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap tombol + untuk menambah tipe kendaraan',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: vehicleTypes.length,
        itemBuilder: (context, index) {
          final vehicleType = vehicleTypes[index];
          return _buildVehicleTypeCard(vehicleType);
        },
      ),
    );
  }

  Widget _buildVehicleTypeCard(VehicleType vehicleType) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            Icons.directions_car,
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          vehicleType.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: vehicleType.description != null
            ? Text(
                vehicleType.description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textHint,
                ),
              )
            : null,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditDialog(vehicleType);
                break;
              case 'delete':
                _showDeleteDialog(vehicleType);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Hapus', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => VehicleTypeFormDialog(
        onSubmit: (request) {
          context.read<VehicleTypeBloc>().add(CreateVehicleType(request: request));
        },
      ),
    );
  }

  void _showEditDialog(VehicleType vehicleType) {
    showDialog(
      context: context,
      builder: (context) => VehicleTypeFormDialog(
        vehicleType: vehicleType,
        onSubmit: (request) {
          final updateRequest = UpdateVehicleTypeRequest(
            name: request.name,
            description: request.description,
          );
          context.read<VehicleTypeBloc>().add(UpdateVehicleType(
            vehicleTypeId: vehicleType.id,
            request: updateRequest,
          ));
        },
      ),
    );
  }

  void _showDeleteDialog(VehicleType vehicleType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tipe Kendaraan'),
        content: Text(
          'Apakah Anda yakin ingin menghapus tipe kendaraan "${vehicleType.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<VehicleTypeBloc>().add(DeleteVehicleType(
                vehicleTypeId: vehicleType.id,
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
