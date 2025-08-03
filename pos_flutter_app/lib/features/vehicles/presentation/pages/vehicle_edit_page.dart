import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/vehicle.dart';
import '../../../../core/theme/app_theme.dart';
import '../blocs/vehicle_bloc.dart';
import '../widgets/form_section.dart';

class VehicleEditPage extends StatefulWidget {
  final String vehicleId;

  const VehicleEditPage({
    super.key,
    required this.vehicleId,
  });

  @override
  State<VehicleEditPage> createState() => _VehicleEditPageState();
}

class _VehicleEditPageState extends State<VehicleEditPage> {
  final _formKey = GlobalKey<FormState>();
  Vehicle? _vehicle;

  // Form controllers
  final _codeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _engineCapacityController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _chassisNumberController = TextEditingController();
  final _engineNumberController = TextEditingController();
  final _odometerController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _repairCostController = TextEditingController();
  final _hppPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _soldPriceController = TextEditingController();
  final _notesController = TextEditingController();

  // Dropdown values
  int? _selectedBrandId;
  String? _selectedFuelType;
  String? _selectedTransmissionType;
  String? _selectedSourceType;
  int? _selectedSourceId;
  String? _selectedConditionStatus;
  String? _selectedStatus;
  DateTime? _selectedSoldDate;

  // Options
  final List<String> _fuelTypes = ['Gasoline', 'Diesel', 'Electric', 'Hybrid'];
  final List<String> _transmissionTypes = ['Manual', 'Automatic', 'CVT'];
  final List<String> _sourceTypes = ['customer', 'supplier'];
  final List<String> _conditionStatuses = [
    'excellent',
    'good',
    'fair',
    'poor',
    'needs_repair'
  ];
  final List<String> _statuses = ['available', 'in_repair', 'sold', 'reserved'];
  List<VehicleBrand> _brands = [];

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _codeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _engineCapacityController.dispose();
    _licensePlateController.dispose();
    _chassisNumberController.dispose();
    _engineNumberController.dispose();
    _odometerController.dispose();
    _purchasePriceController.dispose();
    _repairCostController.dispose();
    _hppPriceController.dispose();
    _sellingPriceController.dispose();
    _soldPriceController.dispose();
    _notesController.dispose();
  }

  void _loadVehicle() {
    context
        .read<VehicleBloc>()
        .add(LoadVehicleDetail(vehicleId: int.parse(widget.vehicleId)));

    // Load brands as well
    _loadBrands();
  }

  void _loadBrands() async {
    // For now, we'll create dummy brands matching the vehicle data
    final now = DateTime.now();
    _brands = [
      VehicleBrand(id: 1, name: 'Honda', typeId: 1, createdAt: now),
      VehicleBrand(id: 2, name: 'Yamaha', typeId: 1, createdAt: now),
      VehicleBrand(id: 3, name: 'Suzuki', typeId: 1, createdAt: now),
      VehicleBrand(id: 4, name: 'Toyota', typeId: 2, createdAt: now),
      VehicleBrand(id: 5, name: 'Honda', typeId: 2, createdAt: now),
      VehicleBrand(id: 6, name: 'Suzuki', typeId: 2, createdAt: now),
    ];
    setState(() {});
  }

  void _populateForm(Vehicle vehicle) {
    _vehicle = vehicle;
    _codeController.text = vehicle.code;
    _modelController.text = vehicle.model;
    _yearController.text = vehicle.year.toString();
    _colorController.text = vehicle.color ?? '';
    _engineCapacityController.text = vehicle.engineCapacity ?? '';
    _licensePlateController.text = vehicle.licensePlate ?? '';
    _chassisNumberController.text = vehicle.chassisNumber ?? '';
    _engineNumberController.text = vehicle.engineNumber ?? '';
    _odometerController.text = vehicle.odometer.toString();
    _purchasePriceController.text = vehicle.purchasePrice.toString();
    _repairCostController.text = vehicle.repairCost?.toString() ?? '';
    _hppPriceController.text = vehicle.hppPrice?.toString() ?? '';
    _sellingPriceController.text = vehicle.sellingPrice?.toString() ?? '';
    _soldPriceController.text = vehicle.soldPrice?.toString() ?? '';
    _notesController.text = vehicle.notes ?? '';

    _selectedBrandId = vehicle.brandId;
    // Only set dropdown values if they exist in the options list
    _selectedFuelType =
        _fuelTypes.contains(vehicle.fuelType) ? vehicle.fuelType : null;
    _selectedTransmissionType =
        _transmissionTypes.contains(vehicle.transmissionType)
            ? vehicle.transmissionType
            : null;
    _selectedSourceType =
        _sourceTypes.contains(vehicle.sourceType) ? vehicle.sourceType : null;
    _selectedSourceId = vehicle.sourceId;
    _selectedConditionStatus =
        _conditionStatuses.contains(vehicle.conditionStatus)
            ? vehicle.conditionStatus
            : null;
    _selectedStatus =
        _statuses.contains(vehicle.status) ? vehicle.status : null;
    _selectedSoldDate = vehicle.soldDate;
  }

  void _saveVehicle() {
    if (_formKey.currentState!.validate() && _vehicle != null) {
      final request = UpdateVehicleRequest(
        code: _codeController.text,
        brandId: _selectedBrandId,
        model: _modelController.text,
        year: int.parse(_yearController.text),
        color: _colorController.text.isEmpty ? null : _colorController.text,
        engineCapacity: _engineCapacityController.text.isEmpty
            ? null
            : _engineCapacityController.text,
        fuelType: _selectedFuelType,
        transmissionType: _selectedTransmissionType,
        licensePlate: _licensePlateController.text.isEmpty
            ? null
            : _licensePlateController.text,
        chassisNumber: _chassisNumberController.text.isEmpty
            ? null
            : _chassisNumberController.text,
        engineNumber: _engineNumberController.text.isEmpty
            ? null
            : _engineNumberController.text,
        odometer: int.parse(_odometerController.text),
        sourceType: _selectedSourceType,
        sourceId: _selectedSourceId,
        purchasePrice: double.parse(_purchasePriceController.text),
        conditionStatus: _selectedConditionStatus,
        status: _selectedStatus,
        repairCost: _repairCostController.text.isEmpty
            ? null
            : double.parse(_repairCostController.text),
        hppPrice: _hppPriceController.text.isEmpty
            ? null
            : double.parse(_hppPriceController.text),
        sellingPrice: _sellingPriceController.text.isEmpty
            ? null
            : double.parse(_sellingPriceController.text),
        soldPrice: _soldPriceController.text.isEmpty
            ? null
            : double.parse(_soldPriceController.text),
        soldDate: _selectedSoldDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      context.read<VehicleBloc>().add(UpdateVehicle(
            vehicleId: _vehicle!.id,
            request: request,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Kendaraan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _saveVehicle,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Simpan'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<VehicleBloc, VehicleState>(
        listener: (context, state) {
          if (state is VehicleDetailLoaded) {
            _populateForm(state.vehicle);
          } else if (state is VehicleOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          } else if (state is VehicleError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is VehicleLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            );
          }

          if (_vehicle == null) {
            return const Center(
              child: Text('Kendaraan tidak ditemukan'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVehicleInfoSection(),
                  const SizedBox(height: 24),
                  _buildTechnicalSpecsSection(),
                  const SizedBox(height: 24),
                  _buildDocumentationSection(),
                  const SizedBox(height: 24),
                  _buildPricingSection(),
                  const SizedBox(height: 24),
                  _buildStatusSection(),
                  const SizedBox(height: 24),
                  _buildNotesSection(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVehicleInfoSection() {
    return FormSection(
      title: 'Informasi Kendaraan',
      icon: Icons.directions_car,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Kode Kendaraan',
                  hintText: 'VEH001',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kode kendaraan harus diisi';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedBrandId,
                decoration: const InputDecoration(
                  labelText: 'Brand',
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Pilih Brand'),
                  ),
                  ..._brands.map((brand) => DropdownMenuItem<int>(
                        value: brand.id,
                        child: Text(brand.name),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedBrandId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Brand harus dipilih';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  hintText: 'Avanza G',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Model harus diisi';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(
                  labelText: 'Tahun',
                  hintText: '2020',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tahun harus diisi';
                  }
                  final year = int.tryParse(value);
                  if (year == null || year < 1980) {
                    return 'Tahun harus minimal 1980';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _colorController,
          decoration: const InputDecoration(
            labelText: 'Warna',
            hintText: 'Silver',
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalSpecsSection() {
    return FormSection(
      title: 'Spesifikasi Teknis',
      icon: Icons.build,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _engineCapacityController,
                decoration: const InputDecoration(
                  labelText: 'Kapasitas Mesin',
                  hintText: '1500',
                  suffixText: 'cc',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedFuelType,
                decoration: const InputDecoration(
                  labelText: 'Jenis Bahan Bakar',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Pilih Jenis Bahan Bakar'),
                  ),
                  ..._fuelTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFuelType = value;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedTransmissionType,
                decoration: const InputDecoration(
                  labelText: 'Transmisi',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Pilih Transmisi'),
                  ),
                  ..._transmissionTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTransmissionType = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _odometerController,
                decoration: const InputDecoration(
                  labelText: 'Odometer',
                  hintText: '35000',
                  suffixText: 'km',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Odometer harus diisi';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentationSection() {
    return FormSection(
      title: 'Dokumentasi',
      icon: Icons.description,
      children: [
        TextFormField(
          controller: _licensePlateController,
          decoration: const InputDecoration(
            labelText: 'Nomor Plat',
            hintText: 'B1234ABC',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _chassisNumberController,
          decoration: const InputDecoration(
            labelText: 'Nomor Rangka',
            hintText: 'CHS1234567890',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _engineNumberController,
          decoration: const InputDecoration(
            labelText: 'Nomor Mesin',
            hintText: 'ENG1234567890',
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return FormSection(
      title: 'Harga',
      icon: Icons.attach_money,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _purchasePriceController,
                decoration: const InputDecoration(
                  labelText: 'Harga Beli',
                  hintText: '120000000',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga beli harus diisi';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _repairCostController,
                decoration: const InputDecoration(
                  labelText: 'Biaya Perbaikan',
                  hintText: '2000000',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _hppPriceController,
                decoration: const InputDecoration(
                  labelText: 'HPP',
                  hintText: '122000000',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _sellingPriceController,
                decoration: const InputDecoration(
                  labelText: 'Harga Jual',
                  hintText: '135000000',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_selectedStatus == 'sold') ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _soldPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Harga Terjual',
                    hintText: '135000000',
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedSoldDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedSoldDate = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Terjual',
                    ),
                    child: Text(
                      _selectedSoldDate != null
                          ? DateFormat('dd/MM/yyyy').format(_selectedSoldDate!)
                          : 'Pilih tanggal',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildStatusSection() {
    return FormSection(
      title: 'Status & Kondisi',
      icon: Icons.info,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedConditionStatus,
                decoration: const InputDecoration(
                  labelText: 'Kondisi',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Pilih Kondisi'),
                  ),
                  ..._conditionStatuses
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(_getConditionStatusLabel(status)),
                          ))
                      .toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedConditionStatus = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Kondisi harus dipilih';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Pilih Status'),
                  ),
                  ..._statuses
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(_getStatusLabel(status)),
                          ))
                      .toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Status harus dipilih';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedSourceType,
                decoration: const InputDecoration(
                  labelText: 'Sumber',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Pilih Sumber'),
                  ),
                  ..._sourceTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                                type == 'customer' ? 'Pelanggan' : 'Supplier'),
                          ))
                      .toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSourceType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Sumber harus dipilih';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: _selectedSourceId?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'ID Sumber',
                  hintText: '101',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  _selectedSourceId = int.tryParse(value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return FormSection(
      title: 'Catatan',
      icon: Icons.note,
      children: [
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Catatan Tambahan',
            hintText: 'Mobil bekas mulus, perlu servis berkala...',
            alignLabelWithHint: true,
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Batal'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveVehicle,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Simpan Perubahan'),
          ),
        ),
      ],
    );
  }

  String _getConditionStatusLabel(String status) {
    switch (status) {
      case 'excellent':
        return 'Sangat Baik';
      case 'good':
        return 'Baik';
      case 'fair':
        return 'Cukup';
      case 'poor':
        return 'Kurang';
      case 'needs_repair':
        return 'Perlu Perbaikan';
      default:
        return status;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Tersedia';
      case 'in_repair':
        return 'Dalam Perbaikan';
      case 'sold':
        return 'Terjual';
      case 'reserved':
        return 'Dipesan';
      default:
        return status;
    }
  }
}
