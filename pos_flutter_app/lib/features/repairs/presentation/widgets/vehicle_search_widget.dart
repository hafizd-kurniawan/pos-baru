import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/vehicle.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../vehicles/presentation/blocs/vehicle_bloc.dart';

class VehicleSearchWidget extends StatefulWidget {
  final String? customerId;
  final Function(Vehicle) onVehicleSelected;

  const VehicleSearchWidget({
    super.key,
    this.customerId,
    required this.onVehicleSelected,
  });

  @override
  State<VehicleSearchWidget> createState() => _VehicleSearchWidgetState();
}

class _VehicleSearchWidgetState extends State<VehicleSearchWidget> {
  final _searchController = TextEditingController();
  Vehicle? _selectedVehicle;
  bool _showDropdown = false;
  List<Vehicle> _searchResults = [];

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) {
      _loadCustomerVehicles();
    }
  }

  @override
  void didUpdateWidget(VehicleSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.customerId != oldWidget.customerId) {
      _clearSelection();
      if (widget.customerId != null) {
        _loadCustomerVehicles();
      } else {
        setState(() {
          _searchResults = [];
          _showDropdown = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSelection() {
    setState(() {
      _selectedVehicle = null;
      _searchController.clear();
      _showDropdown = false;
    });
  }

  void _loadCustomerVehicles() {
    if (widget.customerId != null) {
      context.read<VehicleBloc>().add(LoadVehicles());
      setState(() {
        _showDropdown = true;
      });
    }
  }

  void _searchVehicles(String query) {
    if (query.length >= 2) {
      context.read<VehicleBloc>().add(LoadVehicles());
      setState(() {
        _showDropdown = true;
      });
    } else if (widget.customerId != null) {
      _loadCustomerVehicles();
    } else {
      setState(() {
        _showDropdown = false;
        _searchResults = [];
      });
    }
  }

  void _selectVehicle(Vehicle vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
      _searchController.text =
          '${vehicle.licensePlate ?? 'No Plate'} - ${vehicle.brand} ${vehicle.model}';
      _showDropdown = false;
    });
    widget.onVehicleSelected(vehicle);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Pilih Kendaraan *',
            hintText: widget.customerId != null
                ? 'Pilih dari kendaraan customer atau cari...'
                : 'Pilih customer terlebih dahulu',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.directions_car),
            suffixIcon: _selectedVehicle != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSelection,
                  )
                : widget.customerId != null
                    ? IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadCustomerVehicles,
                      )
                    : null,
          ),
          enabled: widget.customerId != null,
          onChanged: _searchVehicles,
          validator: (value) {
            if (_selectedVehicle == null) {
              return 'Pilih kendaraan terlebih dahulu';
            }
            return null;
          },
        ),
        if (_showDropdown && widget.customerId != null)
          BlocListener<VehicleBloc, VehicleState>(
            listener: (context, state) {
              if (state is VehiclesLoaded) {
                setState(() {
                  _searchResults = state.vehicles;
                });
              } else if (state is VehicleError) {
                setState(() {
                  _searchResults = [];
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: BlocBuilder<VehicleBloc, VehicleState>(
                builder: (context, state) {
                  if (state is VehicleLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (_searchResults.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Tidak ada kendaraan ditemukan',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) {
                      final vehicle = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.directions_car,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        title: Text(
                          vehicle.licensePlate ?? 'No Plate',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${vehicle.brand} ${vehicle.model}'),
                            Text(
                              'Tahun: ${vehicle.year}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.directions_car,
                          color: AppTheme.primaryColor.withOpacity(0.5),
                          size: 20,
                        ),
                        onTap: () => _selectVehicle(vehicle),
                      );
                    },
                  );
                },
              ),
            ),
          ),

        // Selected Vehicle Info
        if (_selectedVehicle != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kendaraan Terpilih:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _selectedVehicle!.licensePlate ?? 'No Plate',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_selectedVehicle!.brand} ${_selectedVehicle!.model}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
