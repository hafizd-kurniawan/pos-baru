import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/spare_part.dart';
import '../services/spare_part_service.dart';

// Events
abstract class SparePartEvent extends Equatable {
  const SparePartEvent();

  @override
  List<Object?> get props => [];
}

class LoadSpareParts extends SparePartEvent {
  final int page;
  final int limit;
  final bool? isActive;
  final String? search;
  final bool refresh;
  final String token;

  const LoadSpareParts({
    this.page = 1,
    this.limit = 20,
    this.isActive,
    this.search,
    this.refresh = false,
    required this.token,
  });

  @override
  List<Object?> get props => [page, limit, isActive, search, refresh, token];
}

class LoadSparePartDetail extends SparePartEvent {
  final int id;

  const LoadSparePartDetail({required this.id});

  @override
  List<Object?> get props => [id];
}

class LoadSparePartByCode extends SparePartEvent {
  final String code;

  const LoadSparePartByCode({required this.code});

  @override
  List<Object?> get props => [code];
}

class CreateSparePart extends SparePartEvent {
  final CreateSparePartRequest request;
  final String token;

  const CreateSparePart({required this.request, required this.token});

  @override
  List<Object?> get props => [request, token];
}

class UpdateSparePart extends SparePartEvent {
  final int id;
  final UpdateSparePartRequest request;
  final String token;

  const UpdateSparePart({
    required this.id,
    required this.request,
    required this.token,
  });

  @override
  List<Object?> get props => [id, request, token];
}

class DeleteSparePart extends SparePartEvent {
  final int id;
  final String token;

  const DeleteSparePart({required this.id, required this.token});

  @override
  List<Object?> get props => [id, token];
}

class UpdateStock extends SparePartEvent {
  final int id;
  final UpdateStockRequest request;
  final String token;

  const UpdateStock({
    required this.id,
    required this.request,
    required this.token,
  });

  @override
  List<Object?> get props => [id, request, token];
}

class LoadLowStockSpareParts extends SparePartEvent {
  const LoadLowStockSpareParts();
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
  final int total;
  final int currentPage;
  final bool hasMore;

  const SparePartsLoaded({
    required this.spareParts,
    required this.total,
    required this.currentPage,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [spareParts, total, currentPage, hasMore];
}

class SparePartDetailLoaded extends SparePartState {
  final SparePart sparePart;

  const SparePartDetailLoaded({required this.sparePart});

  @override
  List<Object?> get props => [sparePart];
}

class SparePartOperationSuccess extends SparePartState {
  final String message;
  final SparePart? sparePart;

  const SparePartOperationSuccess({
    required this.message,
    this.sparePart,
  });

  @override
  List<Object?> get props => [message, sparePart];
}

// Alias for backward compatibility
typedef SparePartSuccess = SparePartOperationSuccess;

class LowStockSparePartsLoaded extends SparePartState {
  final List<SparePart> spareParts;

  const LowStockSparePartsLoaded({required this.spareParts});

  @override
  List<Object?> get props => [spareParts];
}

class SparePartError extends SparePartState {
  final String message;

  const SparePartError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class SparePartBloc extends Bloc<SparePartEvent, SparePartState> {
  final SparePartService _sparePartService;

  SparePartBloc({SparePartService? sparePartService})
      : _sparePartService = sparePartService ?? SparePartService(),
        super(SparePartInitial()) {
    on<LoadSpareParts>(_onLoadSpareParts);
    on<LoadSparePartDetail>(_onLoadSparePartDetail);
    on<LoadSparePartByCode>(_onLoadSparePartByCode);
    on<CreateSparePart>(_onCreateSparePart);
    on<UpdateSparePart>(_onUpdateSparePart);
    on<DeleteSparePart>(_onDeleteSparePart);
    on<UpdateStock>(_onUpdateStock);
    on<LoadLowStockSpareParts>(_onLoadLowStockSpareParts);
  }

  Future<void> _onLoadSpareParts(
    LoadSpareParts event,
    Emitter<SparePartState> emit,
  ) async {
    if (event.refresh || state is! SparePartsLoaded) {
      emit(SparePartLoading());
    }

    try {
      final result = await _sparePartService.getSpareParts(
        page: event.page,
        limit: event.limit,
        isActive: event.isActive,
        search: event.search,
        token: event.token,
      );

      final List<SparePart> spareParts;
      if (event.refresh || state is! SparePartsLoaded) {
        spareParts = result.data;
      } else {
        final currentState = state as SparePartsLoaded;
        spareParts = [...currentState.spareParts, ...result.data];
      }

      emit(SparePartsLoaded(
        spareParts: spareParts,
        total: result.total,
        currentPage: event.page,
        hasMore: result.hasMore,
      ));
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
      final sparePart = await _sparePartService.getSparePartById(event.id);
      emit(SparePartDetailLoaded(sparePart: sparePart));
    } catch (e) {
      emit(SparePartError(message: e.toString()));
    }
  }

  Future<void> _onLoadSparePartByCode(
    LoadSparePartByCode event,
    Emitter<SparePartState> emit,
  ) async {
    emit(SparePartLoading());
    try {
      final sparePart = await _sparePartService.getSparePartByCode(event.code);
      emit(SparePartDetailLoaded(sparePart: sparePart));
    } catch (e) {
      emit(SparePartError(message: e.toString()));
    }
  }

  Future<void> _onCreateSparePart(
    CreateSparePart event,
    Emitter<SparePartState> emit,
  ) async {
    emit(SparePartLoading());
    try {
      final sparePart = await _sparePartService.createSparePart(
        request: event.request,
        token: event.token,
      );
      emit(SparePartOperationSuccess(
        message: 'Spare part berhasil dibuat',
        sparePart: sparePart,
      ));
    } catch (e) {
      emit(SparePartError(message: e.toString()));
    }
  }

  Future<void> _onUpdateSparePart(
    UpdateSparePart event,
    Emitter<SparePartState> emit,
  ) async {
    emit(SparePartLoading());
    try {
      final sparePart = await _sparePartService.updateSparePart(
        id: event.id,
        request: event.request,
        token: event.token,
      );
      emit(SparePartOperationSuccess(
        message: 'Spare part berhasil diupdate',
        sparePart: sparePart,
      ));
    } catch (e) {
      emit(SparePartError(message: e.toString()));
    }
  }

  Future<void> _onDeleteSparePart(
    DeleteSparePart event,
    Emitter<SparePartState> emit,
  ) async {
    emit(SparePartLoading());
    try {
      await _sparePartService.deleteSparePart(
        id: event.id,
        token: event.token,
      );
      emit(const SparePartOperationSuccess(
        message: 'Spare part berhasil dihapus',
      ));
    } catch (e) {
      emit(SparePartError(message: e.toString()));
    }
  }

  Future<void> _onUpdateStock(
    UpdateStock event,
    Emitter<SparePartState> emit,
  ) async {
    emit(SparePartLoading());
    try {
      final sparePart = await _sparePartService.updateStock(
        id: event.id,
        request: event.request,
        token: event.token,
      );
      emit(SparePartOperationSuccess(
        message: 'Stok berhasil diupdate',
        sparePart: sparePart,
      ));
    } catch (e) {
      emit(SparePartError(message: e.toString()));
    }
  }

  Future<void> _onLoadLowStockSpareParts(
    LoadLowStockSpareParts event,
    Emitter<SparePartState> emit,
  ) async {
    emit(SparePartLoading());
    try {
      final spareParts = await _sparePartService.getLowStockSpareParts();
      emit(LowStockSparePartsLoaded(spareParts: spareParts));
    } catch (e) {
      emit(SparePartError(message: e.toString()));
    }
  }
}
