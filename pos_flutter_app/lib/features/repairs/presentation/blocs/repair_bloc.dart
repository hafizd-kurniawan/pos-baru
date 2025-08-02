import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

// Events
abstract class RepairEvent extends Equatable {
  const RepairEvent();
  @override
  List<Object?> get props => [];
}

class LoadRepairs extends RepairEvent {}

// States
abstract class RepairState extends Equatable {
  const RepairState();
  @override
  List<Object?> get props => [];
}

class RepairInitial extends RepairState {}

class RepairLoading extends RepairState {}

class RepairsLoaded extends RepairState {
  final List<dynamic> repairs;
  
  const RepairsLoaded({required this.repairs});
  
  @override
  List<Object?> get props => [repairs];
}

class RepairError extends RepairState {
  final String message;
  
  const RepairError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

// Bloc
class RepairBloc extends Bloc<RepairEvent, RepairState> {
  final ApiClient _apiClient;

  RepairBloc({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(RepairInitial()) {
    on<LoadRepairs>(_onLoadRepairs);
  }

  Future<void> _onLoadRepairs(
    LoadRepairs event,
    Emitter<RepairState> emit,
  ) async {
    emit(RepairLoading());
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));
      emit(const RepairsLoaded(repairs: []));
    } catch (e) {
      emit(RepairError(message: e.toString()));
    }
  }
}