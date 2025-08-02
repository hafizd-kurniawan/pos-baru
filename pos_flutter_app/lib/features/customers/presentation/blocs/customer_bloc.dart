import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

// Events
abstract class CustomerEvent extends Equatable {
  const CustomerEvent();
  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CustomerEvent {}

// States
abstract class CustomerState extends Equatable {
  const CustomerState();
  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomersLoaded extends CustomerState {
  final List<dynamic> customers;
  
  const CustomersLoaded({required this.customers});
  
  @override
  List<Object?> get props => [customers];
}

class CustomerError extends CustomerState {
  final String message;
  
  const CustomerError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

// Bloc
class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final ApiClient _apiClient;

  CustomerBloc({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));
      emit(const CustomersLoaded(customers: []));
    } catch (e) {
      emit(CustomerError(message: e.toString()));
    }
  }
}