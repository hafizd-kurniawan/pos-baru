import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/spare_part.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../vehicles/presentation/widgets/form_section.dart';
import '../blocs/spare_part_bloc.dart';
import '../services/spare_part_service.dart';

class EditSparePartPage extends StatefulWidget {
  final int sparePartId;

  const EditSparePartPage({
    super.key,
    required this.sparePartId,
  });

  @override
  State<EditSparePartPage> createState() => _EditSparePartPageState();
}

class _EditSparePartPageState extends State<EditSparePartPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _unitController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final _minimumStockController = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;
  SparePart? _sparePart;

  final _sparePartService = SparePartService();
  List<String> _categories = [];
  List<String> _units = ['pcs', 'set', 'liter', 'kg', 'meter', 'roll'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadSparePartDetail();
  }

  Future<void> _loadCategories() async {
    try {
      final token = await StorageService.getToken();
      if (token != null) {
        final categories = await _sparePartService.getCategories(token: token);
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  void _loadSparePartDetail() async {
    final token = await StorageService.getToken();
    if (token != null && mounted) {
      context.read<SparePartBloc>().add(
            LoadSparePartDetail(id: widget.sparePartId),
          );
    }
  }

  void _populateForm(SparePart sparePart) {
    _nameController.text = sparePart.name;
    _codeController.text = sparePart.code;
    _descriptionController.text = sparePart.description ?? '';
    _categoryController.text = sparePart.category;
    _unitController.text = sparePart.unit;
    _purchasePriceController.text = sparePart.purchasePrice.toString();
    _sellingPriceController.text = sparePart.sellingPrice.toString();
    _stockQuantityController.text = sparePart.stockQuantity.toString();
    _minimumStockController.text = sparePart.minimumStock.toString();
    _isActive = sparePart.isActive;
    _sparePart = sparePart;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final token = await StorageService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token tidak ditemukan')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Create update request
    if (_sparePart == null) return;

    final updateRequest = UpdateSparePartRequest(
      id: _sparePart!.id,
      code: _sparePart!.code,
      name: _nameController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      category: _categoryController.text,
      unit: _unitController.text,
      purchasePrice: double.parse(_purchasePriceController.text),
      sellingPrice: double.parse(_sellingPriceController.text),
      stockQuantity: int.parse(_stockQuantityController.text),
      minimumStock: int.parse(_minimumStockController.text),
    );

    context.read<SparePartBloc>().add(UpdateSparePart(
          id: widget.sparePartId,
          request: updateRequest,
          token: token,
        ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockQuantityController.dispose();
    _minimumStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Edit Spare Part',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<SparePartBloc, SparePartState>(
        listener: (context, state) {
          if (state is SparePartDetailLoaded) {
            _populateForm(state.sparePart);
          } else if (state is SparePartOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            context.pop(true); // Return true to indicate success
          } else if (state is SparePartError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isLoading = false;
            });
          }
        },
        builder: (context, state) {
          if (state is SparePartLoading && _sparePart == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information Section
                  FormSection(
                    title: 'Informasi Dasar',
                    icon: Icons.inventory,
                    children: [
                      // Name field
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Spare Part',
                          hintText: 'Masukkan nama spare part',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama spare part tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Code field (disabled)
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Kode Spare Part',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFF5F5F5),
                        ),
                        enabled: false,
                      ),
                      const SizedBox(height: 16),

                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                          hintText: 'Masukkan deskripsi spare part',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Category and Unit row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Kategori',
                                border: OutlineInputBorder(),
                              ),
                              value:
                                  _categories.contains(_categoryController.text)
                                      ? _categoryController.text
                                      : null,
                              items: [
                                ..._categories.map((category) {
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  );
                                }).toList(),
                                if (!_categories
                                        .contains(_categoryController.text) &&
                                    _categoryController.text.isNotEmpty)
                                  DropdownMenuItem(
                                    value: _categoryController.text,
                                    child: Text(_categoryController.text),
                                  ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _categoryController.text = value ?? '';
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Kategori tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _categoryController,
                              decoration: const InputDecoration(
                                labelText: 'Atau Kategori Baru',
                                hintText: 'Kategori baru',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Unit field
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Satuan',
                          border: OutlineInputBorder(),
                        ),
                        value: _units.contains(_unitController.text)
                            ? _unitController.text
                            : _unitController.text.isNotEmpty
                                ? _unitController.text
                                : null,
                        items: [
                          ..._units.map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(unit.toUpperCase()),
                            );
                          }).toList(),
                          if (!_units.contains(_unitController.text) &&
                              _unitController.text.isNotEmpty)
                            DropdownMenuItem(
                              value: _unitController.text,
                              child: Text(_unitController.text.toUpperCase()),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _unitController.text = value ?? '';
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Satuan tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Price and Stock Section
                  FormSection(
                    title: 'Informasi Harga & Stok',
                    icon: Icons.attach_money,
                    children: [
                      // Purchase Price field
                      TextFormField(
                        controller: _purchasePriceController,
                        decoration: const InputDecoration(
                          labelText: 'Harga Beli',
                          hintText: 'Masukkan harga beli',
                          border: OutlineInputBorder(),
                          prefixText: 'Rp ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harga beli tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Selling Price field
                      TextFormField(
                        controller: _sellingPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Harga Jual',
                          hintText: 'Masukkan harga jual',
                          border: OutlineInputBorder(),
                          prefixText: 'Rp ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harga jual tidak boleh kosong';
                          }
                          final purchasePrice =
                              double.tryParse(_purchasePriceController.text) ??
                                  0;
                          final sellingPrice = double.tryParse(value) ?? 0;
                          if (sellingPrice <= purchasePrice) {
                            return 'Harga jual harus lebih tinggi dari harga beli';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Stock fields
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stockQuantityController,
                              decoration: const InputDecoration(
                                labelText: 'Stok Saat Ini',
                                hintText: 'Jumlah stok',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Stok tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _minimumStockController,
                              decoration: const InputDecoration(
                                labelText: 'Stok Minimum',
                                hintText: 'Stok minimum',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Stok minimum tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Status Section
                  FormSection(
                    title: 'Status',
                    icon: Icons.toggle_on,
                    children: [
                      SwitchListTile(
                        title: const Text('Spare Part Aktif'),
                        subtitle: Text(_isActive ? 'Aktif' : 'Tidak Aktif'),
                        value: _isActive,
                        onChanged: (bool value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Simpan Perubahan',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
