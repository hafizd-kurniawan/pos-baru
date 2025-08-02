import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

// Events
abstract class SparePartEvent extends Equatable {
  const SparePartEvent();
  @override
  List<Object?> get props => [];
}

class LoadSpareParts extends SparePartEvent {}

// States
abstract class SparePartState extends Equatable {
  const SparePartState();
  @override
  List<Object?> get props => [];
}

class SparePartInitial extends SparePartState {}

class SparePartLoading extends SparePartState {}

class SparePartsLoaded extends SparePartState {
  final List<dynamic> spareParts;
  
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