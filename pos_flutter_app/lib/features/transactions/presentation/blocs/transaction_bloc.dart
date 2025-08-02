import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/models/transaction.dart';

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
      // Determine which endpoint to use based on type
      String endpoint;
      if (event.type == 'purchase') {
        endpoint = ApiEndpoints.purchaseTransactions;
      } else if (event.type == 'sales') {
        endpoint = ApiEndpoints.salesTransactions;
      } else {
        // Load both types - we'll need to combine them
        // For now, let's load purchase transactions as default
        endpoint = ApiEndpoints.purchaseTransactions;
      }

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
        endpoint,
        queryParameters: queryParams,
      );

      final data = response.data;
      final transactionsList = (data['data'] as List)
          .map((json) => Transaction.fromJson(json))
          .toList();

      emit(TransactionsLoaded(
        transactions: transactionsList,
        total: data['total'] ?? 0,
        currentPage: data['page'] ?? 1,
        hasMore: (data['page'] ?? 1) < (data['total_pages'] ?? 1),
      ));
    } catch (e) {
      emit(TransactionError(message: e.toString()));
    }
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
      final transaction = Transaction.fromJson(response.data);
      emit(TransactionDetailLoaded(transaction: transaction));
    } catch (e) {
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

      emit(const TransactionOperationSuccess(message: 'Transaksi pembelian berhasil dibuat'));
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

      emit(const TransactionOperationSuccess(message: 'Transaksi penjualan berhasil dibuat'));
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

      emit(const TransactionOperationSuccess(message: 'Pembayaran berhasil diperbarui'));
    } catch (e) {
      emit(TransactionError(message: e.toString()));
    }
  }
}