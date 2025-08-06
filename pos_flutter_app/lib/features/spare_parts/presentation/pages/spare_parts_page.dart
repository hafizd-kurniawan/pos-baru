import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/models/spare_part.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../blocs/spare_part_bloc.dart';

class SparePartsPage extends StatefulWidget {
  const SparePartsPage({Key? key}) : super(key: key);

  @override
  State<SparePartsPage> createState() => _SparePartsPageState();
}

class _SparePartsPageState extends State<SparePartsPage> {
  final _searchController = TextEditingController();
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final token = await StorageService.getToken();
    if (token != null && mounted) {
      context.read<SparePartBloc>().add(LoadSpareParts(token: token));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spare Parts'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go(AppRoutes.addSparePart),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari spare part...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // TODO: Implement search
              },
            ),
          ),
          
          // Content
          Expanded(
            child: BlocBuilder<SparePartBloc, SparePartState>(
              builder: (context, state) {
                if (state is SparePartLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is SparePartError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.message}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadData(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (state is SparePartsLoaded) {
                  if (state.spareParts.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada spare part',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tambahkan spare part pertama Anda',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.spareParts.length,
                    itemBuilder: (context, index) {
                      final sparePart = state.spareParts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.build_circle,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          title: Text(
                            sparePart.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rp ${sparePart.sellingPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text('Stock: ${sparePart.stockQuantity}'),
                            ],
                          ),
                          onTap: () {
                            // Navigate to detail
                            context.go('${AppRoutes.spareParts}/${sparePart.id}');
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  context.go('${AppRoutes.spareParts}/${sparePart.id}/edit');
                                  break;
                                case 'delete':
                                  _deleteSparePart(sparePart);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Hapus'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _deleteSparePart(SparePart sparePart) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Apakah Anda yakin ingin menghapus ${sparePart.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final token = await StorageService.getToken();
      if (token != null && mounted) {
        context.read<SparePartBloc>().add(
          DeleteSparePart(id: sparePart.id, token: token),
        );
      }
    }
  }
}
