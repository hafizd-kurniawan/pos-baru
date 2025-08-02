import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/models/spare_part.dart';

// Events
abstract class SparePartEvent extends Equatable {
  const SparePartEvent();
  @override
  List<Object?> get props => [];
}

class LoadSpareParts extends SparePartEvent {}

class LoadSparePartDetail extends SparePartEvent {
  final int sparePartId;

  const LoadSparePartDetail(this.sparePartId);

  @override
  List<Object?> get props => [sparePartId];
}

// States
abstract class SparePartState extends Equatable {
  const SparePartState();
  @override
  List<Object?> get props => [];
}

class SparePartInitial extends SparePartState {}

class SparePartLoading extends SparePartState {}

class SparePartsLoaded extends SparePartState {
  final List<SparePart> spareParts;
  
  const SparePartsLoaded({required this.spareParts});
  
  @override
  List<Object?> get props => [spareParts];
}

class SparePartDetailLoaded extends SparePartState {
  final SparePart sparePart;
  
  const SparePartDetailLoaded({required this.sparePart});
  
  @override
  List<Object?> get props => [sparePart];
}

class SparePartError extends SparePartState {
  final String message;
  
  const SparePartError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

// Bloc
class SparePartBloc extends Bloc<SparePartEvent, SparePartState> {
  final ApiClient _apiClient;

  SparePartBloc({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(SparePartInitial()) {
    on<LoadSpareParts>(_onLoadSpareParts);
    on<LoadSparePartDetail>(_onLoadSparePartDetail);
  }

  Future<void> _onLoadSpareParts(
    LoadSpareParts event,
    Emitter<SparePartState> emit,
  ) async {
    emit(SparePartLoading());
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));
      emit(const SparePartsLoaded(spareParts: []));
    } catch (e) {
      emit(SparePartError(message: e.toString()));
    }
  }

  Future<void> _onLoadSparePartDetail(
    LoadSparePartDetail event,
    Emitter<SparePartState> emit,
  ) async {
    emit(SparePartLoading());
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));
      // Create a dummy spare part for now
      final sparePart = SparePart(
        id: event.sparePartId,
        code: 'SP-${event.sparePartId}',
        name: 'Sample Spare Part',
        description: 'Sample description',
        price: 100000.0,
        stock: 10,
        category: 'Sample Category',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      emit(SparePartDetailLoaded(sparePart: sparePart));
    } catch (e) {
      emit(SparePartError(message: e.toString()));
    }
  }
}
  
  const SparePartsLoaded({required this.spareParts});
  
  @override
  List<Object?> get props => [spareParts];
}

class SparePartError extends SparePartState {
  final String message;
  
  const SparePartError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

// Bloc
class SparePartBloc extends Bloc<SparePartEvent, SparePartState> {
  final ApiClient _apiClient;

  SparePartBloc({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(SparePartInitial()) {
    on<LoadSpareParts>(_onLoadSpareParts);
  }

  Future<void> _onLoadSpareParts(
    LoadSpareParts event,
    Emitter<SparePartState> emit,
  ) async {
    emit(SparePartLoading());
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));
      emit(const SparePartsLoaded(spareParts: []));
    } catch (e) {
      emit(SparePartError(message: e.toString()));
    }
  }
}