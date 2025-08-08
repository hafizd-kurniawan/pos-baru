import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/customer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../customers/presentation/blocs/customer_bloc.dart';

class CustomerSearchWidget extends StatefulWidget {
  final Function(Customer) onCustomerSelected;

  const CustomerSearchWidget({
    super.key,
    required this.onCustomerSelected,
  });

  @override
  State<CustomerSearchWidget> createState() => _CustomerSearchWidgetState();
}

class _CustomerSearchWidgetState extends State<CustomerSearchWidget> {
  final _searchController = TextEditingController();
  Customer? _selectedCustomer;
  bool _showDropdown = false;
  List<Customer> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchCustomers(String query) {
    if (query.length >= 2) {
      context.read<CustomerBloc>().add(LoadCustomers(search: query));
      setState(() {
        _showDropdown = true;
      });
    } else {
      setState(() {
        _showDropdown = false;
        _searchResults = [];
      });
    }
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      _searchController.text = '${customer.name} - ${customer.phone}';
      _showDropdown = false;
    });
    widget.onCustomerSelected(customer);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Cari Customer *',
            hintText: 'Ketik nama atau nomor telepon...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _selectedCustomer != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedCustomer = null;
                        _searchController.clear();
                        _showDropdown = false;
                      });
                    },
                  )
                : null,
          ),
          onChanged: _searchCustomers,
          validator: (value) {
            if (_selectedCustomer == null) {
              return 'Pilih customer terlebih dahulu';
            }
            return null;
          },
        ),
        if (_showDropdown)
          BlocListener<CustomerBloc, CustomerState>(
            listener: (context, state) {
              if (state is CustomersLoaded) {
                setState(() {
                  _searchResults = state.customers;
                });
              } else if (state is CustomerError) {
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
              child: BlocBuilder<CustomerBloc, CustomerState>(
                builder: (context, state) {
                  if (state is CustomerLoading) {
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
                        'Tidak ada customer ditemukan',
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
                      final customer = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        title: Text(
                          customer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.phone,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            if (customer.email != null)
                              Text(
                                customer.email!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        onTap: () => _selectCustomer(customer),
                      );
                    },
                  );
                },
              ),
            ),
          ),

        // Selected Customer Info
        if (_selectedCustomer != null)
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
                        'Customer Terpilih:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _selectedCustomer!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _selectedCustomer!.phone,
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
