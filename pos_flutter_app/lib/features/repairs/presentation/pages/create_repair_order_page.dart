import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/customer.dart';
import '../../../../core/models/user.dart';
import '../../../../core/models/vehicle.dart';
import '../../../../core/theme/app_theme.dart';
import '../blocs/repair_bloc.dart';
import '../widgets/customer_search_widget.dart';
import '../widgets/mechanic_selection_widget.dart';
import '../widgets/vehicle_search_widget.dart';

class CreateRepairOrderPage extends StatefulWidget {
  const CreateRepairOrderPage({super.key});

  @override
  State<CreateRepairOrderPage> createState() => _CreateRepairOrderPageState();
}

class _CreateRepairOrderPageState extends State<CreateRepairOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _estimatedCostController = TextEditingController();
  final _notesController = TextEditingController();

  Customer? _selectedCustomer;
  Vehicle? _selectedVehicle;
  User? _selectedMechanic;

  @override
  void dispose() {
    _descriptionController.dispose();
    _estimatedCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Buat Order Perbaikan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocListener<RepairBloc, RepairState>(
        listener: (context, state) {
          if (state is RepairError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is RepairOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          }
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.1),
                        AppTheme.primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.build_circle,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Perbaikan Baru',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Masukkan detail kendaraan customer yang perlu diperbaiki',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Customer Selection
                _buildSectionTitle('1. Pilih Customer'),
                const SizedBox(height: 8),
                CustomerSearchWidget(
                  onCustomerSelected: (customer) {
                    setState(() {
                      _selectedCustomer = customer;
                      _selectedVehicle =
                          null; // Reset vehicle when customer changes
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Vehicle Selection
                _buildSectionTitle('2. Pilih Kendaraan'),
                const SizedBox(height: 8),
                VehicleSearchWidget(
                  customerId: _selectedCustomer?.id.toString(),
                  onVehicleSelected: (vehicle) {
                    setState(() {
                      _selectedVehicle = vehicle;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Mechanic Selection
                _buildSectionTitle('3. Assign Mekanik'),
                const SizedBox(height: 8),
                MechanicSelectionWidget(
                  onMechanicSelected: (mechanic) {
                    setState(() {
                      _selectedMechanic = mechanic;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Repair Details
                _buildSectionTitle('4. Detail Perbaikan'),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi Masalah *',
                    hintText: 'Jelaskan masalah kendaraan...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Deskripsi tidak boleh kosong';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Estimated Cost
                TextFormField(
                  controller: _estimatedCostController,
                  decoration: InputDecoration(
                    labelText: 'Perkiraan Biaya',
                    hintText: 'Rp 0',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final cost = double.tryParse(value);
                      if (cost == null || cost < 0) {
                        return 'Masukkan biaya yang valid';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Catatan Tambahan',
                    hintText: 'Catatan khusus untuk mekanik...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 32),

                // Submit Button
                BlocBuilder<RepairBloc, RepairState>(
                  builder: (context, state) {
                    final isLoading = state is RepairLoading;

                    return ElevatedButton(
                      onPressed: isLoading || !_canSubmit()
                          ? null
                          : _submitRepairOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Membuat Order...'),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle),
                                SizedBox(width: 8),
                                Text(
                                  'Buat Order Perbaikan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    );
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  bool _canSubmit() {
    return _selectedCustomer != null &&
        _selectedVehicle != null &&
        _selectedMechanic != null &&
        _descriptionController.text.trim().isNotEmpty;
  }

  void _submitRepairOrder() {
    if (!_formKey.currentState!.validate() || !_canSubmit()) {
      return;
    }

    final estimatedCost = _estimatedCostController.text.isNotEmpty
        ? double.tryParse(_estimatedCostController.text) ?? 0.0
        : 0.0;

    // Generate repair code
    final code =
        'RPR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    context.read<RepairBloc>().add(
          CreateRepairOrder(
            code: code,
            vehicleId: _selectedVehicle!.id,
            mechanicId: _selectedMechanic!.id,
            description: _descriptionController.text.trim(),
            estimatedCost: estimatedCost,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          ),
        );
  }
}
