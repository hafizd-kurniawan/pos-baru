import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/vehicle.dart';
import '../blocs/vehicle_bloc.dart';
import '../widgets/form_section.dart';

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _codeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _engineCapacityController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _odometerController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Form values
  int? _selectedBrandId;
  String _selectedFuelType = 'Bensin';
  String _selectedTransmissionType = 'Manual';
  String _selectedSourceType = 'customer';
  int? _selectedSourceId;
  String _selectedConditionStatus = 'good';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateVehicleCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _engineCapacityController.dispose();
    _licensePlateController.dispose();
    _odometerController.dispose();
    _purchasePriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _generateVehicleCode() {
    final now = DateTime.now();
    final code = 'VHC${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecondsSinceEpoch.toString().substring(10)}';
    _codeController.text = code;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Tambah Kendaraan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveVehicle,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Simpan',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocListener<VehicleBloc, VehicleState>(
        listener: (context, state) {
          if (state is VehicleLoading) {
            setState(() => _isLoading = true);
          } else if (state is VehicleOperationSuccess) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          } else if (state is VehicleError) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Basic Information Section
                FormSection(
                  title: 'Informasi Dasar',
                  icon: Icons.info_outline,
                  children: [
                    _buildTextFormField(
                      controller: _codeController,
                      label: 'Kode Kendaraan',
                      hint: 'VHC20240101001',
                      readOnly: true,
                      validator: (value) => value?.isEmpty == true ? 'Kode kendaraan harus diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildBrandDropdown(),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _modelController,
                      label: 'Model',
                      hint: 'Beat, Vario, PCX',
                      validator: (value) => value?.isEmpty == true ? 'Model harus diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            controller: _yearController,
                            label: 'Tahun',
                            hint: '2023',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Tahun harus diisi';
                              final year = int.tryParse(value!);
                              if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                                return 'Tahun tidak valid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextFormField(
                            controller: _colorController,
                            label: 'Warna',
                            hint: 'Merah, Biru, Hitam',
                            validator: (value) => value?.isEmpty == true ? 'Warna harus diisi' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Technical Specifications Section
                FormSection(
                  title: 'Spesifikasi Teknis',
                  icon: Icons.settings,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            controller: _engineCapacityController,
                            label: 'Kapasitas Mesin',
                            hint: '110cc, 150cc',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _buildFuelTypeDropdown()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTransmissionTypeDropdown()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildConditionStatusDropdown()),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Vehicle Details Section
                FormSection(
                  title: 'Detail Kendaraan',
                  icon: Icons.directions_car,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            controller: _licensePlateController,
                            label: 'Nomor Polisi',
                            hint: 'B1234ABC',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextFormField(
                            controller: _odometerController,
                            label: 'Odometer (km)',
                            hint: '15000',
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Source & Pricing Section
                FormSection(
                  title: 'Sumber & Harga',
                  icon: Icons.attach_money,
                  children: [
                    _buildSourceTypeDropdown(),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _purchasePriceController,
                      label: 'Harga Beli',
                      hint: '25000000',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Harga beli harus diisi';
                        final price = double.tryParse(value!);
                        if (price == null || price <= 0) return 'Harga beli tidak valid';
                        return null;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Additional Information Section
                FormSection(
                  title: 'Informasi Tambahan',
                  icon: Icons.note,
                  children: [
                    _buildTextFormField(
                      controller: _descriptionController,
                      label: 'Deskripsi',
                      hint: 'Catatan atau keterangan tambahan...',
                      maxLines: 3,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveVehicle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Simpan Kendaraan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: readOnly ? AppTheme.backgroundColor : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildBrandDropdown() {
    // TODO: Get brands from API
    final brands = [
      {'id': 1, 'name': 'Honda'},
      {'id': 2, 'name': 'Yamaha'},
      {'id': 3, 'name': 'Kawasaki'},
      {'id': 4, 'name': 'Suzuki'},
    ];

    return DropdownButtonFormField<int>(
      value: _selectedBrandId,
      decoration: InputDecoration(
        labelText: 'Merek',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: brands.map((brand) {
        return DropdownMenuItem<int>(
          value: brand['id'] as int,
          child: Text(brand['name'] as String),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedBrandId = value),
      validator: (value) => value == null ? 'Merek harus dipilih' : null,
    );
  }

  Widget _buildFuelTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedFuelType,
      decoration: InputDecoration(
        labelText: 'Jenis Bahan Bakar',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: const [
        DropdownMenuItem(value: 'Bensin', child: Text('Bensin')),
        DropdownMenuItem(value: 'Diesel', child: Text('Diesel')),
        DropdownMenuItem(value: 'Listrik', child: Text('Listrik')),
        DropdownMenuItem(value: 'Hybrid', child: Text('Hybrid')),
      ],
      onChanged: (value) => setState(() => _selectedFuelType = value!),
    );
  }

  Widget _buildTransmissionTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTransmissionType,
      decoration: InputDecoration(
        labelText: 'Jenis Transmisi',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: const [
        DropdownMenuItem(value: 'Manual', child: Text('Manual')),
        DropdownMenuItem(value: 'Otomatis', child: Text('Otomatis')),
        DropdownMenuItem(value: 'CVT', child: Text('CVT')),
      ],
      onChanged: (value) => setState(() => _selectedTransmissionType = value!),
    );
  }

  Widget _buildConditionStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedConditionStatus,
      decoration: InputDecoration(
        labelText: 'Kondisi',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: const [
        DropdownMenuItem(value: 'excellent', child: Text('Sangat Baik')),
        DropdownMenuItem(value: 'good', child: Text('Baik')),
        DropdownMenuItem(value: 'fair', child: Text('Cukup')),
        DropdownMenuItem(value: 'poor', child: Text('Kurang')),
      ],
      onChanged: (value) => setState(() => _selectedConditionStatus = value!),
    );
  }

  Widget _buildSourceTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSourceType,
      decoration: InputDecoration(
        labelText: 'Sumber Kendaraan',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: const [
        DropdownMenuItem(value: 'customer', child: Text('Customer')),
        DropdownMenuItem(value: 'supplier', child: Text('Supplier')),
        DropdownMenuItem(value: 'dealer', child: Text('Dealer')),
        DropdownMenuItem(value: 'auction', child: Text('Lelang')),
      ],
      onChanged: (value) => setState(() => _selectedSourceType = value!),
    );
  }

  void _saveVehicle() {
    if (!_formKey.currentState!.validate()) return;

    final request = CreateVehicleRequest(
      code: _codeController.text,
      brandId: _selectedBrandId!,
      model: _modelController.text,
      year: int.parse(_yearController.text),
      color: _colorController.text,
      engineCapacity: _engineCapacityController.text.isNotEmpty ? _engineCapacityController.text : null,
      fuelType: _selectedFuelType,
      transmissionType: _selectedTransmissionType,
      licensePlate: _licensePlateController.text.isNotEmpty ? _licensePlateController.text : null,
      odometer: _odometerController.text.isNotEmpty ? int.parse(_odometerController.text) : null,
      sourceType: _selectedSourceType,
      sourceId: _selectedSourceId,
      purchasePrice: double.parse(_purchasePriceController.text),
      conditionStatus: _selectedConditionStatus,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
    );

    context.read<VehicleBloc>().add(CreateVehicle(request: request));
  }
}