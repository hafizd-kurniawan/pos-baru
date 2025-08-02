import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/models/repair.dart';

// Events
abstract class RepairEvent extends Equatable {
  const RepairEvent();
  @override
  List<Object?> get props => [];
}

class LoadRepairs extends RepairEvent {}

class LoadRepairDetail extends RepairEvent {
  final int repairId;

  const LoadRepairDetail(this.repairId);

  @override
  List<Object?> get props => [repairId];
}

// States
abstract class RepairState extends Equatable {
  const RepairState();
  @override
  List<Object?> get props => [];
}

class RepairInitial extends RepairState {}

class RepairLoading extends RepairState {}

class RepairsLoaded extends RepairState {
  final List<Repair> repairs;
  
  const RepairsLoaded({required this.repairs});
  
  @override
  List<Object?> get props => [repairs];
}

class RepairDetailLoaded extends RepairState {
  final Repair repair;
  
  const RepairDetailLoaded({required this.repair});
  
  @override
  List<Object?> get props => [repair];
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
    on<LoadRepairDetail>(_onLoadRepairDetail);
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

  Future<void> _onLoadRepairDetail(
    LoadRepairDetail event,
    Emitter<RepairState> emit,
  ) async {
    emit(RepairLoading());
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));
      // Create a dummy repair for now
      final repair = Repair(
        id: event.repairId,
        vehicleId: 1,
        mechanicId: 1,
        mechanicName: 'Sample Mechanic',
        description: 'Sample repair description',
        status: 'in_progress',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      emit(RepairDetailLoaded(repair: repair));
    } catch (e) {
      emit(RepairError(message: e.toString()));
    }
  }
}