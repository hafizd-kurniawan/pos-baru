import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/models/customer.dart';
import '../blocs/customer_bloc.dart';
import '../widgets/customer_card.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasMore = true;
  int _currentPage = 1;
  List<Customer> _customers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadCustomers({bool refresh = false}) {
    if (refresh) {
      _currentPage = 1;
      _customers.clear();
    }
    
    context.read<CustomerBloc>().add(LoadCustomers(
      page: _currentPage,
      limit: 20,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
    ));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        _hasMore) {
      _currentPage++;
      _loadCustomers();
    }
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
                      'Manajemen Customer',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kelola data customer showroom',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.addCustomer),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Tambah Customer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari customer berdasarkan nama atau nomor telepon...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadCustomers(refresh: true);
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onSubmitted: (_) => _loadCustomers(refresh: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _loadCustomers(refresh: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cari'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Customers List
            Expanded(
              child: BlocConsumer<CustomerBloc, CustomerState>(
                listener: (context, state) {
                  if (state is CustomerError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else if (state is CustomerOperationSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadCustomers(refresh: true);
                  }
                },
                builder: (context, state) {
                  if (state is CustomerLoading && _customers.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    );
                  }

                  if (state is CustomersLoaded) {
                    if (_currentPage == 1) {
                      _customers = state.customers;
                    } else {
                      _customers.addAll(state.customers);
                    }
                    _hasMore = state.hasMore;
                  }

                  if (_customers.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _loadCustomers(refresh: true),
                    color: AppTheme.primaryColor,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _customers.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _customers.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                              ),
                            ),
                          );
                        }

                        final customer = _customers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CustomerCard(
                            customer: customer,
                            onTap: () => context.push('${AppRoutes.customers}/${customer.id}'),
                            onEdit: () => _editCustomer(customer),
                            onDelete: () => _deleteCustomer(customer),
                          ),
                        );
                      },
                    ),
                  );
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isNotEmpty 
                ? 'Tidak ada customer yang ditemukan' 
                : 'Belum ada customer',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty 
                ? 'Coba ubah kata kunci pencarian'
                : 'Mulai dengan menambah customer pertama',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.addCustomer),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Tambah Customer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editCustomer(Customer customer) {
    // TODO: Navigate to edit customer page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit customer coming soon')),
    );
  }

  void _deleteCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Customer'),
        content: Text('Apakah Anda yakin ingin menghapus customer ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<CustomerBloc>().add(DeleteCustomer(customerId: customer.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class CustomerDetailPage extends StatelessWidget {
  final int customerId;
  
  const CustomerDetailPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Customer')),
      body: Center(child: Text('Customer Detail: $customerId')),
    );
  }
}

class AddCustomerPage extends StatelessWidget {
  const AddCustomerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Customer')),
      body: const Center(child: Text('Add Customer Form')),
    );
  }
}