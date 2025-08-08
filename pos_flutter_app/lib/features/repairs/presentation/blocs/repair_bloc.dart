import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/repair.dart';
import '../services/repair_service.dart';

// Events
abstract class RepairEvent extends Equatable {
  const RepairEvent();
  @override
  List<Object?> get props => [];
}

class LoadRepairs extends RepairEvent {
  final String token;
  final String? status;
  final int page;
  final int limit;
  final bool refresh;

  const LoadRepairs({
    required this.token,
    this.status,
    this.page = 1,
    this.limit = 20,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [token, status, page, limit, refresh];
}

class LoadRepairDetail extends RepairEvent {
  final int repairId;
  final String token;

  const LoadRepairDetail({
    required this.repairId,
    required this.token,
  });

  @override
  List<Object?> get props => [repairId, token];
}

class CreateRepair extends RepairEvent {
  final CreateRepairRequest request;
  final String token;

  const CreateRepair({
    required this.request,
    required this.token,
  });

  @override
  List<Object?> get props => [request, token];
}

class UpdateRepair extends RepairEvent {
  final int id;
  final UpdateRepairRequest request;
  final String token;

  const UpdateRepair({
    required this.id,
    required this.request,
    required this.token,
  });

  @override
  List<Object?> get props => [id, request, token];
}

class DeleteRepair extends RepairEvent {
  final int id;
  final String token;

  const DeleteRepair({
    required this.id,
    required this.token,
  });

  @override
  List<Object?> get props => [id, token];
}

class CreateRepairOrder extends RepairEvent {
  final String code;
  final int vehicleId;
  final int mechanicId;
  final String description;
  final double estimatedCost;
  final String? notes;

  const CreateRepairOrder({
    required this.code,
    required this.vehicleId,
    required this.mechanicId,
    required this.description,
    required this.estimatedCost,
    this.notes,
  });

  @override
  List<Object?> get props =>
      [code, vehicleId, mechanicId, description, estimatedCost, notes];
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
  final int total;
  final int currentPage;
  final bool hasMore;

  const RepairsLoaded({
    required this.repairs,
    required this.total,
    required this.currentPage,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [repairs, total, currentPage, hasMore];
}

class RepairDetailLoaded extends RepairState {
  final Repair repair;

  const RepairDetailLoaded({required this.repair});

  @override
  List<Object?> get props => [repair];
}

class RepairOperationSuccess extends RepairState {
  final String message;
  final Repair? repair;

  const RepairOperationSuccess({
    required this.message,
    this.repair,
  });

  @override
  List<Object?> get props => [message, repair];
}

class RepairError extends RepairState {
  final String message;

  const RepairError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class RepairBloc extends Bloc<RepairEvent, RepairState> {
  final RepairService _repairService;

  RepairBloc({RepairService? repairService})
      : _repairService = repairService ?? RepairService(),
        super(RepairInitial()) {
    on<LoadRepairs>(_onLoadRepairs);
    on<LoadRepairDetail>(_onLoadRepairDetail);
    on<CreateRepair>(_onCreateRepair);
    on<UpdateRepair>(_onUpdateRepair);
    on<DeleteRepair>(_onDeleteRepair);
    on<CreateRepairOrder>(_onCreateRepairOrder);
  }

  Future<void> _onLoadRepairs(
    LoadRepairs event,
    Emitter<RepairState> emit,
  ) async {
    if (event.refresh || state is! RepairsLoaded) {
      emit(RepairLoading());
    }

    try {
      final repairs = await _repairService.getRepairs(
        token: event.token,
        status: event.status,
        page: event.page,
        limit: event.limit,
      );

      emit(RepairsLoaded(
        repairs: repairs,
        total: repairs.length,
        currentPage: event.page,
        hasMore: repairs.length >= event.limit,
      ));
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
      final repair = await _repairService.getRepairById(
        id: event.repairId,
        token: event.token,
      );
      emit(RepairDetailLoaded(repair: repair));
    } catch (e) {
      emit(RepairError(message: e.toString()));
    }
  }

  Future<void> _onCreateRepair(
    CreateRepair event,
    Emitter<RepairState> emit,
  ) async {
    emit(RepairLoading());
    try {
      final repair = await _repairService.createRepair(
        request: event.request,
        token: event.token,
      );
      emit(RepairOperationSuccess(
        message: 'Repair berhasil dibuat',
        repair: repair,
      ));
    } catch (e) {
      emit(RepairError(message: e.toString()));
    }
  }

  Future<void> _onUpdateRepair(
    UpdateRepair event,
    Emitter<RepairState> emit,
  ) async {
    emit(RepairLoading());
    try {
      final repair = await _repairService.updateRepair(
        id: event.id,
        request: event.request,
        token: event.token,
      );
      emit(RepairOperationSuccess(
        message: 'Repair berhasil diupdate',
        repair: repair,
      ));
    } catch (e) {
      emit(RepairError(message: e.toString()));
    }
  }

  Future<void> _onDeleteRepair(
    DeleteRepair event,
    Emitter<RepairState> emit,
  ) async {
    emit(RepairLoading());
    try {
      await _repairService.deleteRepair(
        id: event.id,
        token: event.token,
      );
      emit(const RepairOperationSuccess(
        message: 'Repair berhasil dihapus',
      ));
    } catch (e) {
      emit(RepairError(message: e.toString()));
    }
  }

  Future<void> _onCreateRepairOrder(
    CreateRepairOrder event,
    Emitter<RepairState> emit,
  ) async {
    emit(RepairLoading());
    try {
      final request = CreateRepairRequest(
        vehicleId: event.vehicleId,
        mechanicId: event.mechanicId,
        description: event.description,
        estimatedCost: event.estimatedCost,
      );

      final repair = await _repairService.createRepair(
        request: request,
        token: '', // Token will be handled by ApiClient
      );

      emit(RepairOperationSuccess(
        message: 'Order repair berhasil dibuat dan ditugaskan ke mechanic',
        repair: repair,
      ));
    } catch (e) {
      emit(RepairError(message: e.toString()));
    }
  }
}
