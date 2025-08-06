import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/spare_part.dart';
import '../services/mechanic_repair_service.dart';

// Events
abstract class MechanicRepairEvent extends Equatable {
  const MechanicRepairEvent();

  @override
  List<Object?> get props => [];
}

class LoadMechanicRepairs extends MechanicRepairEvent {
  final String? status;
  final int page;
  final int limit;
  final bool refresh;

  const LoadMechanicRepairs({
    this.status,
    this.page = 1,
    this.limit = 20,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [status, page, limit, refresh];
}

class LoadRepairDetail extends MechanicRepairEvent {
  final int repairId;

  const LoadRepairDetail({
    required this.repairId,
  });

  @override
  List<Object?> get props => [repairId];
}

class StartRepair extends MechanicRepairEvent {
  final int repairId;
  final String? notes;

  const StartRepair({
    required this.repairId,
    this.notes,
  });

  @override
  List<Object?> get props => [repairId, notes];
}

class AddRepairItem extends MechanicRepairEvent {
  final int repairId;
  final CreateRepairItemRequest request;

  const AddRepairItem({
    required this.repairId,
    required this.request,
  });

  @override
  List<Object?> get props => [repairId, request];
}

class UpdateRepairItem extends MechanicRepairEvent {
  final int repairId;
  final int itemId;
  final UpdateRepairItemRequest request;

  const UpdateRepairItem({
    required this.repairId,
    required this.itemId,
    required this.request,
  });

  @override
  List<Object?> get props => [repairId, itemId, request];
}

class RemoveRepairItem extends MechanicRepairEvent {
  final int repairId;
  final int itemId;

  const RemoveRepairItem({
    required this.repairId,
    required this.itemId,
  });

  @override
  List<Object?> get props => [repairId, itemId];
}

class CompleteRepair extends MechanicRepairEvent {
  final int repairId;
  final double laborCost;
  final String? notes;

  const CompleteRepair({
    required this.repairId,
    required this.laborCost,
    this.notes,
  });

  @override
  List<Object?> get props => [repairId, laborCost, notes];
}

class SearchSpareParts extends MechanicRepairEvent {
  final String query;

  const SearchSpareParts({
    required this.query,
  });

  @override
  List<Object?> get props => [query];
}

// States
abstract class MechanicRepairState extends Equatable {
  const MechanicRepairState();

  @override
  List<Object?> get props => [];
}

class MechanicRepairInitial extends MechanicRepairState {}

class MechanicRepairLoading extends MechanicRepairState {}

class MechanicRepairsLoaded extends MechanicRepairState {
  final List<RepairWithItems> repairs;
  final bool hasMore;
  final int currentPage;

  const MechanicRepairsLoaded({
    required this.repairs,
    required this.hasMore,
    required this.currentPage,
  });

  @override
  List<Object?> get props => [repairs, hasMore, currentPage];
}

class RepairDetailLoaded extends MechanicRepairState {
  final RepairWithItems repairWithItems;

  const RepairDetailLoaded({required this.repairWithItems});

  @override
  List<Object?> get props => [repairWithItems];
}

class SparePartsSearchLoaded extends MechanicRepairState {
  final List<SparePart> spareParts;

  const SparePartsSearchLoaded({required this.spareParts});

  @override
  List<Object?> get props => [spareParts];
}

class MechanicRepairOperationSuccess extends MechanicRepairState {
  final String message;
  final RepairWithItems? repairWithItems;

  const MechanicRepairOperationSuccess({
    required this.message,
    this.repairWithItems,
  });

  @override
  List<Object?> get props => [message, repairWithItems];
}

class MechanicRepairError extends MechanicRepairState {
  final String message;

  const MechanicRepairError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class MechanicRepairBloc
    extends Bloc<MechanicRepairEvent, MechanicRepairState> {
  final MechanicRepairService _mechanicRepairService;

  MechanicRepairBloc({MechanicRepairService? mechanicRepairService})
      : _mechanicRepairService =
            mechanicRepairService ?? MechanicRepairService(),
        super(MechanicRepairInitial()) {
    on<LoadMechanicRepairs>(_onLoadMechanicRepairs);
    on<LoadRepairDetail>(_onLoadRepairDetail);
    on<StartRepair>(_onStartRepair);
    on<AddRepairItem>(_onAddRepairItem);
    on<UpdateRepairItem>(_onUpdateRepairItem);
    on<RemoveRepairItem>(_onRemoveRepairItem);
    on<CompleteRepair>(_onCompleteRepair);
    on<SearchSpareParts>(_onSearchSpareParts);
  }

  Future<void> _onLoadMechanicRepairs(
    LoadMechanicRepairs event,
    Emitter<MechanicRepairState> emit,
  ) async {
    if (event.refresh || state is! MechanicRepairsLoaded) {
      emit(MechanicRepairLoading());
    }

    try {
      final repairs = await _mechanicRepairService.getMechanicRepairs(
        status: event.status ?? 'pending',
        page: event.page,
        limit: event.limit,
      );

      emit(MechanicRepairsLoaded(
        repairs: repairs,
        hasMore: repairs.length >= event.limit,
        currentPage: event.page,
      ));
    } catch (e) {
      emit(MechanicRepairError(message: e.toString()));
    }
  }

  Future<void> _onLoadRepairDetail(
    LoadRepairDetail event,
    Emitter<MechanicRepairState> emit,
  ) async {
    emit(MechanicRepairLoading());

    try {
      final repairWithItems = await _mechanicRepairService.getRepairDetail(
        repairId: event.repairId,
      );

      emit(RepairDetailLoaded(repairWithItems: repairWithItems));
    } catch (e) {
      emit(MechanicRepairError(message: e.toString()));
    }
  }

  Future<void> _onStartRepair(
    StartRepair event,
    Emitter<MechanicRepairState> emit,
  ) async {
    emit(MechanicRepairLoading());

    try {
      await _mechanicRepairService.startRepair(
        repairId: event.repairId,
        notes: event.notes,
      );

      // Reload repair detail
      final repair = await _mechanicRepairService.getRepairInfo(
        repairId: event.repairId,
      );

      final items = await _mechanicRepairService.getRepairItems(
        repairId: event.repairId,
      );

      final repairWithItems = RepairWithItems(
        repair: repair,
        items: items,
      );

      emit(MechanicRepairOperationSuccess(
        message: 'Perbaikan berhasil dimulai',
        repairWithItems: repairWithItems,
      ));
    } catch (e) {
      emit(MechanicRepairError(message: e.toString()));
    }
  }

  Future<void> _onAddRepairItem(
    AddRepairItem event,
    Emitter<MechanicRepairState> emit,
  ) async {
    emit(MechanicRepairLoading());

    try {
      await _mechanicRepairService.addRepairItem(
        repairId: event.repairId,
        request: event.request,
      );

      // Reload repair detail
      final repair = await _mechanicRepairService.getRepairInfo(
        repairId: event.repairId,
      );

      final items = await _mechanicRepairService.getRepairItems(
        repairId: event.repairId,
      );

      final repairWithItems = RepairWithItems(
        repair: repair,
        items: items,
      );

      emit(MechanicRepairOperationSuccess(
        message: 'Spare part berhasil ditambahkan',
        repairWithItems: repairWithItems,
      ));
    } catch (e) {
      emit(MechanicRepairError(message: e.toString()));
    }
  }

  Future<void> _onUpdateRepairItem(
    UpdateRepairItem event,
    Emitter<MechanicRepairState> emit,
  ) async {
    emit(MechanicRepairLoading());

    try {
      await _mechanicRepairService.updateRepairItem(
        repairId: event.repairId,
        itemId: event.itemId,
        request: event.request,
      );

      // Reload repair detail
      final repair = await _mechanicRepairService.getRepairInfo(
        repairId: event.repairId,
      );

      final items = await _mechanicRepairService.getRepairItems(
        repairId: event.repairId,
      );

      final repairWithItems = RepairWithItems(
        repair: repair,
        items: items,
      );

      emit(MechanicRepairOperationSuccess(
        message: 'Spare part berhasil diupdate',
        repairWithItems: repairWithItems,
      ));
    } catch (e) {
      emit(MechanicRepairError(message: e.toString()));
    }
  }

  Future<void> _onRemoveRepairItem(
    RemoveRepairItem event,
    Emitter<MechanicRepairState> emit,
  ) async {
    emit(MechanicRepairLoading());

    try {
      await _mechanicRepairService.removeRepairItem(
        repairId: event.repairId,
        itemId: event.itemId,
      );

      // Reload repair detail
      final repair = await _mechanicRepairService.getRepairInfo(
        repairId: event.repairId,
      );

      final items = await _mechanicRepairService.getRepairItems(
        repairId: event.repairId,
      );

      final repairWithItems = RepairWithItems(
        repair: repair,
        items: items,
      );

      emit(MechanicRepairOperationSuccess(
        message: 'Spare part berhasil dihapus',
        repairWithItems: repairWithItems,
      ));
    } catch (e) {
      emit(MechanicRepairError(message: e.toString()));
    }
  }

  Future<void> _onCompleteRepair(
    CompleteRepair event,
    Emitter<MechanicRepairState> emit,
  ) async {
    emit(MechanicRepairLoading());

    try {
      await _mechanicRepairService.completeRepair(
        repairId: event.repairId,
        laborCost: event.laborCost,
        notes: event.notes,
      );

      // Reload repair detail
      final repair = await _mechanicRepairService.getRepairInfo(
        repairId: event.repairId,
      );

      final items = await _mechanicRepairService.getRepairItems(
        repairId: event.repairId,
      );

      final repairWithItems = RepairWithItems(
        repair: repair,
        items: items,
      );

      emit(MechanicRepairOperationSuccess(
        message: 'Perbaikan berhasil diselesaikan',
        repairWithItems: repairWithItems,
      ));
    } catch (e) {
      emit(MechanicRepairError(message: e.toString()));
    }
  }

  Future<void> _onSearchSpareParts(
    SearchSpareParts event,
    Emitter<MechanicRepairState> emit,
  ) async {
    try {
      final spareParts = await _mechanicRepairService.searchSpareParts(
        event.query,
      );

      emit(SparePartsSearchLoaded(spareParts: spareParts));
    } catch (e) {
      emit(MechanicRepairError(message: e.toString()));
    }
  }
}
