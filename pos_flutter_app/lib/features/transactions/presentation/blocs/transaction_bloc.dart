import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/models/transaction.dart';
import '../../../../core/network/api_client.dart';

// Events
abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionEvent {
  final int page;
  final int limit;
  final String? type; // 'purchase' or 'sales'
  final String? dateFrom;
  final String? dateTo;

  const LoadTransactions({
    this.page = 1,
    this.limit = 10,
    this.type,
    this.dateFrom,
    this.dateTo,
  });

  @override
  List<Object?> get props => [page, limit, type, dateFrom, dateTo];
}

class LoadTransactionDetail extends TransactionEvent {
  final int transactionId;
  final String type; // 'purchase' or 'sales'

  const LoadTransactionDetail({
    required this.transactionId,
    required this.type,
  });

  @override
  List<Object?> get props => [transactionId, type];
}

class CreatePurchaseTransaction extends TransactionEvent {
  final CreatePurchaseTransactionRequest request;

  const CreatePurchaseTransaction({required this.request});

  @override
  List<Object?> get props => [request];
}

class CreateSalesTransaction extends TransactionEvent {
  final CreateSalesTransactionRequest request;

  const CreateSalesTransaction({required this.request});

  @override
  List<Object?> get props => [request];
}

class UpdateTransactionPayment extends TransactionEvent {
  final int transactionId;
  final String type; // 'purchase' or 'sales'
  final UpdateTransactionPaymentRequest request;

  const UpdateTransactionPayment({
    required this.transactionId,
    required this.type,
    required this.request,
  });

  @override
  List<Object?> get props => [transactionId, type, request];
}

// States
abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionsLoaded extends TransactionState {
  final List<Transaction> transactions;
  final int total;
  final int currentPage;
  final bool hasMore;

  const TransactionsLoaded({
    required this.transactions,
    required this.total,
    required this.currentPage,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [transactions, total, currentPage, hasMore];
}

class TransactionDetailLoaded extends TransactionState {
  final Transaction transaction;

  const TransactionDetailLoaded({required this.transaction});

  @override
  List<Object?> get props => [transaction];
}

class TransactionOperationSuccess extends TransactionState {
  final String message;

  const TransactionOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final ApiClient _apiClient;

  TransactionBloc({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<LoadTransactionDetail>(_onLoadTransactionDetail);
    on<CreatePurchaseTransaction>(_onCreatePurchaseTransaction);
    on<CreateSalesTransaction>(_onCreateSalesTransaction);
    on<UpdateTransactionPayment>(_onUpdateTransactionPayment);
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      List<Transaction> allTransactions = [];
      int totalCount = 0;
      int currentPage = event.page;
      bool hasMore = false;

      if (event.type == 'purchase') {
        // Load only purchase transactions
        final result = await _loadPurchaseTransactions(event);
        allTransactions = result['transactions'];
        totalCount = result['total'];
        hasMore = result['hasMore'];
      } else if (event.type == 'sales') {
        // Load only sales transactions
        final result = await _loadSalesTransactions(event);
        allTransactions = result['transactions'];
        totalCount = result['total'];
        hasMore = result['hasMore'];
      } else {
        // Load both types - start with sales first since we have data there
        final salesResult = await _loadSalesTransactions(event);
        allTransactions.addAll(salesResult['transactions']);
        totalCount += (salesResult['total'] as num).toInt();

        // Also try to load purchase transactions
        try {
          final purchaseResult = await _loadPurchaseTransactions(event);
          allTransactions.addAll(purchaseResult['transactions']);
          totalCount += (purchaseResult['total'] as num).toInt();
        } catch (e) {
          print('⚠️ Could not load purchase transactions: $e');
        }

        // Sort by date descending
        allTransactions
            .sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
        hasMore = false; // For combined view, disable pagination for now
      }

      emit(TransactionsLoaded(
        transactions: allTransactions,
        total: totalCount,
        currentPage: currentPage,
        hasMore: hasMore,
      ));
    } catch (e) {
      print('❌ Load transactions error: $e');
      emit(TransactionError(message: e.toString()));
    }
  }

  Future<Map<String, dynamic>> _loadSalesTransactions(
      LoadTransactions event) async {
    final queryParams = <String, dynamic>{
      'page': event.page,
      'limit': event.limit,
    };

    if (event.dateFrom != null) {
      queryParams['date_from'] = event.dateFrom;
    }
    if (event.dateTo != null) {
      queryParams['date_to'] = event.dateTo;
    }

    final response = await _apiClient.get(
      ApiEndpoints.salesTransactions,
      queryParameters: queryParams,
    );

    final data = response.data;
    print('🔍 Sales Transaction Response: $data');

    final responseData = data['data'];
    final transactionsData = responseData['transactions'];
    final transactionsList = transactionsData != null
        ? (transactionsData as List)
            .map((json) => Transaction.fromJson(json))
            .toList()
        : <Transaction>[];

    final pagination = responseData['pagination'];

    return {
      'transactions': transactionsList,
      'total': pagination['total'] ?? 0,
      'hasMore':
          (pagination['current_page'] ?? 1) < (pagination['total_pages'] ?? 1),
    };
  }

  Future<Map<String, dynamic>> _loadPurchaseTransactions(
      LoadTransactions event) async {
    final queryParams = <String, dynamic>{
      'page': event.page,
      'limit': event.limit,
    };

    if (event.dateFrom != null) {
      queryParams['date_from'] = event.dateFrom;
    }
    if (event.dateTo != null) {
      queryParams['date_to'] = event.dateTo;
    }

    final response = await _apiClient.get(
      ApiEndpoints.purchaseTransactions,
      queryParameters: queryParams,
    );

    final data = response.data;
    print('🔍 Purchase Transaction Response: $data');

    final responseData = data['data'];
    final transactionsData = responseData['transactions'];
    final transactionsList = transactionsData != null
        ? (transactionsData as List)
            .map((json) => Transaction.fromJson(json))
            .toList()
        : <Transaction>[];

    final pagination = responseData['pagination'];

    return {
      'transactions': transactionsList,
      'total': pagination['total'] ?? 0,
      'hasMore':
          (pagination['current_page'] ?? 1) < (pagination['total_pages'] ?? 1),
    };
  }

  Future<void> _onLoadTransactionDetail(
    LoadTransactionDetail event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      String endpoint;
      if (event.type == 'purchase') {
        endpoint = ApiEndpoints.purchaseTransactionById(event.transactionId);
      } else {
        endpoint = ApiEndpoints.salesTransactionById(event.transactionId);
      }

      final response = await _apiClient.get(endpoint);
      final data = response.data;
      print('🔍 Transaction Detail Response: $data');

      // Handle response structure - data is nested under 'data.transaction'
      Map<String, dynamic> transactionData;
      if (data['data'] != null && data['data']['transaction'] != null) {
        transactionData = data['data']['transaction'];
      } else if (data['data'] != null) {
        transactionData = data['data'];
      } else {
        // Fallback to using the data directly
        transactionData = data;
      }

      print('🔍 Parsed transaction data: $transactionData');
      final transaction = Transaction.fromJson(transactionData);
      print(
          '🔍 Created Transaction object: ID=${transaction.id}, Invoice=${transaction.invoiceNumber}');

      emit(TransactionDetailLoaded(transaction: transaction));
    } catch (e) {
      print('❌ Load transaction detail error: $e');
      emit(TransactionError(message: e.toString()));
    }
  }

  Future<void> _onCreatePurchaseTransaction(
    CreatePurchaseTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      await _apiClient.post(
        ApiEndpoints.purchaseTransactions,
        data: event.request.toJson(),
      );

      emit(const TransactionOperationSuccess(
          message: 'Transaksi pembelian berhasil dibuat'));
    } catch (e) {
      emit(TransactionError(message: e.toString()));
    }
  }

  Future<void> _onCreateSalesTransaction(
    CreateSalesTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      await _apiClient.post(
        ApiEndpoints.salesTransactions,
        data: event.request.toJson(),
      );

      emit(const TransactionOperationSuccess(
          message: 'Transaksi penjualan berhasil dibuat'));
    } catch (e) {
      emit(TransactionError(message: e.toString()));
    }
  }

  Future<void> _onUpdateTransactionPayment(
    UpdateTransactionPayment event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      String endpoint;
      if (event.type == 'purchase') {
        endpoint = ApiEndpoints.updatePurchasePayment(event.transactionId);
      } else {
        endpoint = ApiEndpoints.updateSalesPayment(event.transactionId);
      }

      await _apiClient.patch(
        endpoint,
        data: event.request.toJson(),
      );

      emit(const TransactionOperationSuccess(
          message: 'Pembayaran berhasil diperbarui'));
    } catch (e) {
      emit(TransactionError(message: e.toString()));
    }
  }
}
