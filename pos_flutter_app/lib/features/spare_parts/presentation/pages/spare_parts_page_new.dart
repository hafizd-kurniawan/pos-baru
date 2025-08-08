import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/models/spare_part.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../blocs/spare_part_bloc.dart';
import '../widgets/enhanced_spare_part_card.dart';
import '../widgets/spare_part_filter_chips.dart';

class SparePartsPage extends StatefulWidget {
  const SparePartsPage({Key? key}) : super(key: key);

  @override
  State<SparePartsPage> createState() => _SparePartsPageState();
}

class _SparePartsPageState extends State<SparePartsPage> {
  final _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedCategory;
  final ScrollController _scrollController = ScrollController();
  bool _hasMore = true;
  int _currentPage = 1;
  List<SparePart> _spareParts = [];

  @override
  void initState() {
    super.initState();
    _loadSpareParts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadSpareParts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _spareParts.clear();
    }

    final token = await StorageService.getToken();
    if (token != null && mounted) {
      context.read<SparePartBloc>().add(LoadSpareParts(
            token: token,
            page: _currentPage,
            limit: 20,
            status: _selectedStatus,
            category: _selectedCategory,
            search: _searchController.text.isNotEmpty
                ? _searchController.text
                : null,
          ));
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        _hasMore) {
      _currentPage++;
      _loadSpareParts();
    }
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadSpareParts(refresh: true);
  }

  void _onCategoryFilterChanged(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadSpareParts(refresh: true);
  }

  void _showSparePartDetails(SparePart sparePart) {
    context.push('${AppRoutes.spareParts}/${sparePart.id}');
  }

  void _editSparePart(SparePart sparePart) {
    context.push('${AppRoutes.spareParts}/${sparePart.id}/edit');
  }

  void _deleteSparePart(SparePart sparePart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Spare Part'),
        content: Text('Apakah Anda yakin ingin menghapus ${sparePart.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final token = await StorageService.getToken();
              if (token != null && mounted) {
                context.read<SparePartBloc>().add(
                      DeleteSparePart(id: sparePart.id, token: token),
                    );
              }
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manajemen Spare Part',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kelola inventori spare part dan komponen',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push('${AppRoutes.spareParts}/add'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Spare Part'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search and Filters
            Row(
              children: [
                // Search
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari spare part...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _loadSpareParts(refresh: true),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _loadSpareParts(refresh: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cari'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filter Chips
            SparePartFilterChips(
              selectedStatus: _selectedStatus,
              selectedCategory: _selectedCategory,
              onStatusChanged: _onStatusFilterChanged,
              onCategoryChanged: _onCategoryFilterChanged,
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: BlocConsumer<SparePartBloc, SparePartState>(
                listener: (context, state) {
                  if (state is SparePartError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else if (state is SparePartsLoaded) {
                    if (_currentPage == 1) {
                      _spareParts = List.from(state.spareParts);
                    } else {
                      _spareParts.addAll(state.spareParts);
                    }
                    _hasMore = state.hasMore;
                  } else if (state is SparePartDeleted) {
                    _loadSpareParts(refresh: true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Spare part berhasil dihapus'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is SparePartLoading && _currentPage == 1) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_spareParts.isEmpty && state is! SparePartLoading) {
                    return _buildEmptyState();
                  }

                  return _buildGridView();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada spare part',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan spare part pertama Anda',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('${AppRoutes.spareParts}/add'),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Spare Part'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _spareParts.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _spareParts.length) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final sparePart = _spareParts[index];
        return EnhancedSparePartCard(
          sparePart: sparePart,
          onTap: () => _showSparePartDetails(sparePart),
          onViewDetail: () => _showSparePartDetails(sparePart),
          onEdit: () => _editSparePart(sparePart),
          onDelete: () => _deleteSparePart(sparePart),
        );
      },
    );
  }
}
