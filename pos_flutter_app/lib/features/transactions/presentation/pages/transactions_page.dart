import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/models/transaction.dart';
import '../../../../core/theme/app_theme.dart';
import '../blocs/transaction_bloc.dart';
import '../services/transaction_service.dart';
import '../widgets/transaction_card.dart';
import 'transaction_detail_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  late TransactionService _transactionService;
  bool _hasMore = true;
  int _currentPage = 1;
  List<Transaction> _transactions = [];
  String? _selectedType;
  String? _dateFrom;
  String? _dateTo;

  @override
  void initState() {
    super.initState();
    _transactionService = TransactionService();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTransactions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    switch (_tabController.index) {
      case 0:
        _selectedType = null;
        break;
      case 1:
        _selectedType = 'purchase';
        break;
      case 2:
        _selectedType = 'sales';
        break;
    }
    _loadTransactions(refresh: true);
  }

  void _loadTransactions({bool refresh = false}) {
    if (refresh) {
      _currentPage = 1;
      _transactions.clear();
    }

    context.read<TransactionBloc>().add(LoadTransactions(
          page: _currentPage,
          limit: 20,
          type: _selectedType,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
        ));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        _hasMore) {
      _currentPage++;
      _loadTransactions();
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
                      'Manajemen Transaksi',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kelola transaksi pembelian dan penjualan',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.addTransaction),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Transaksi Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filter Section
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
              child: Column(
                children: [
                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppTheme.textSecondary,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Semua'),
                        Tab(text: 'Pembelian'),
                        Tab(text: 'Penjualan'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Filters
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Dari Tanggal',
                          value: _dateFrom,
                          onChanged: (value) {
                            setState(() => _dateFrom = value);
                            _loadTransactions(refresh: true);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                          label: 'Sampai Tanggal',
                          value: _dateTo,
                          onChanged: (value) {
                            setState(() => _dateTo = value);
                            _loadTransactions(refresh: true);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Transactions List
            Expanded(
              child: BlocConsumer<TransactionBloc, TransactionState>(
                listener: (context, state) {
                  if (state is TransactionError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else if (state is TransactionOperationSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadTransactions(refresh: true);
                  }
                },
                builder: (context, state) {
                  if (state is TransactionLoading && _transactions.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor),
                      ),
                    );
                  }

                  if (state is TransactionsLoaded) {
                    if (_currentPage == 1) {
                      _transactions = state.transactions;
                    } else {
                      _transactions.addAll(state.transactions);
                    }
                    _hasMore = state.hasMore;
                  }

                  if (_transactions.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _loadTransactions(refresh: true),
                    color: AppTheme.primaryColor,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _transactions.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _transactions.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryColor),
                              ),
                            ),
                          );
                        }

                        final transaction = _transactions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TransactionCard(
                            transaction: transaction,
                            onTap: () => _viewTransactionDetail(transaction),
                            onUpdatePayment: () => _updatePayment(transaction),
                            onPrint: () => _printInvoice(transaction),
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

  Widget _buildDateField({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today, size: 20),
        filled: true,
        fillColor: AppTheme.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      controller: TextEditingController(text: value),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          final formattedDate =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          onChanged(formattedDate);
        }
      },
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
              Icons.receipt_long_outlined,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada transaksi',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai dengan membuat transaksi pertama',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.addTransaction),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Transaksi Baru'),
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

  void _viewTransactionDetail(Transaction transaction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionDetailPage(transaction: transaction),
      ),
    );
  }

  void _updatePayment(Transaction transaction) {
    // TODO: Show payment update dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Update pembayaran coming soon')),
    );
  }

  void _printInvoice(Transaction transaction) async {
    try {
      await _transactionService.printInvoice(transaction.id, transaction.type);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Invoice berhasil "dicetak" (Mock Print)'),
            ],
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Gagal print invoice: $e'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
