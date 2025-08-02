import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/models/supplier.dart';

// Events
abstract class SupplierEvent extends Equatable {
  const SupplierEvent();
  @override
  List<Object?> get props => [];
}

class LoadSuppliers extends SupplierEvent {}

class LoadSupplierDetail extends SupplierEvent {
  final int supplierId;

  const LoadSupplierDetail(this.supplierId);

  @override
  List<Object?> get props => [supplierId];
}

// States
abstract class SupplierState extends Equatable {
  const SupplierState();
  @override
  List<Object?> get props => [];
}

class SupplierInitial extends SupplierState {}

class SupplierLoading extends SupplierState {}

class SuppliersLoaded extends SupplierState {
  final List<Supplier> suppliers;
  
  const SuppliersLoaded({required this.suppliers});
  
  @override
  List<Object?> get props => [suppliers];
}

class SupplierDetailLoaded extends SupplierState {
  final Supplier supplier;
  
  const SupplierDetailLoaded({required this.supplier});
  
  @override
  List<Object?> get props => [supplier];
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
    on<LoadSupplierDetail>(_onLoadSupplierDetail);
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

  Future<void> _onLoadSupplierDetail(
    LoadSupplierDetail event,
    Emitter<SupplierState> emit,
  ) async {
    emit(SupplierLoading());
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));
      // Create a dummy supplier for now
      final supplier = Supplier(
        id: event.supplierId,
        name: 'Sample Supplier',
        phone: '+6281234567890',
        email: 'supplier@example.com',
        address: 'Sample Address',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      emit(SupplierDetailLoaded(supplier: supplier));
    } catch (e) {
      emit(SupplierError(message: e.toString()));
    }
  }
}