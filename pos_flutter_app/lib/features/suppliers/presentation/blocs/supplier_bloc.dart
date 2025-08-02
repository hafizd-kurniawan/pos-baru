import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

// Events
abstract class SupplierEvent extends Equatable {
  const SupplierEvent();
  @override
  List<Object?> get props => [];
}

class LoadSuppliers extends SupplierEvent {}

// States
abstract class SupplierState extends Equatable {
  const SupplierState();
  @override
  List<Object?> get props => [];
}

class SupplierInitial extends SupplierState {}

class SupplierLoading extends SupplierState {}

class SuppliersLoaded extends SupplierState {
  final List<dynamic> suppliers;
  
  const SuppliersLoaded({required this.suppliers});
  
  @override
  List<Object?> get props => [suppliers];
}

class SupplierError extends SupplierState {
  final String message;
  
  const SupplierError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

// Bloc
class SupplierBloc extends Bloc<SupplierEvent, SupplierState> {
  final ApiClient _apiClient;

  SupplierBloc({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(SupplierInitial()) {
    on<LoadSuppliers>(_onLoadSuppliers);
  }

  Future<void> _onLoadSuppliers(
    LoadSuppliers event,
    Emitter<SupplierState> emit,
  ) async {
    emit(SupplierLoading());
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));
      emit(const SuppliersLoaded(suppliers: []));
    } catch (e) {
      emit(SupplierError(message: e.toString()));
    }
  }
}