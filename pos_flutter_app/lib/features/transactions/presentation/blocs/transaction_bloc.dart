import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

// Events
abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionEvent {}

// States
abstract class TransactionState extends Equatable {
  const TransactionState();
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionsLoaded extends TransactionState {
  final List<dynamic> transactions;
  
  const TransactionsLoaded({required this.transactions});
  
  @override
  List<Object?> get props => [transactions];
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
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));
      emit(const TransactionsLoaded(transactions: []));
    } catch (e) {
      emit(TransactionError(message: e.toString()));
    }
  }
}