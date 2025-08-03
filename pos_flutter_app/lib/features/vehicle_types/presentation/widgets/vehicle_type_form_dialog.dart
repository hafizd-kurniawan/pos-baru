import 'package:flutter/material.dart';
import '../../../../core/models/vehicle_type.dart';
import '../../../../core/theme/app_theme.dart';

class VehicleTypeFormDialog extends StatefulWidget {
  final VehicleType? vehicleType;
  final Function(CreateVehicleTypeRequest) onSubmit;

  const VehicleTypeFormDialog({
    super.key,
    this.vehicleType,
    required this.onSubmit,
  });

  @override
  State<VehicleTypeFormDialog> createState() => _VehicleTypeFormDialogState();
}

class _VehicleTypeFormDialogState extends State<VehicleTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.vehicleType != null) {
      _nameController.text = widget.vehicleType!.name;
      _descriptionController.text = widget.vehicleType!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.vehicleType == null ? 'Tambah Tipe Kendaraan' : 'Edit Tipe Kendaraan',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Tipe Kendaraan *',
                  hintText: 'Masukkan nama tipe kendaraan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.directions_car),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama tipe kendaraan wajib diisi';
                  }
                  if (value.trim().length < 2) {
                    return 'Nama tipe kendaraan minimal 2 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi (Opsional)',
                  hintText: 'Masukkan deskripsi tipe kendaraan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty && value.trim().length < 5) {
                    return 'Deskripsi minimal 5 karakter';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text(
            widget.vehicleType == null ? 'Tambah' : 'Simpan',
          ),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final request = CreateVehicleTypeRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      );
      
      widget.onSubmit(request);
      Navigator.of(context).pop();
    }
  }
}
