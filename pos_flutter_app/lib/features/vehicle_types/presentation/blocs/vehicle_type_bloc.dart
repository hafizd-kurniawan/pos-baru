import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models/vehicle_type.dart';
import '../../../../shared/services/vehicle_type_service.dart';

// Events
abstract class VehicleTypeEvent extends Equatable {
  const VehicleTypeEvent();

  @override
  List<Object?> get props => [];
}

class LoadVehicleTypes extends VehicleTypeEvent {}

class LoadVehicleTypeDetail extends VehicleTypeEvent {
  final int vehicleTypeId;

  const LoadVehicleTypeDetail({required this.vehicleTypeId});

  @override
  List<Object?> get props => [vehicleTypeId];
}

class CreateVehicleType extends VehicleTypeEvent {
  final CreateVehicleTypeRequest request;

  const CreateVehicleType({required this.request});

  @override
  List<Object?> get props => [request];
}

class UpdateVehicleType extends VehicleTypeEvent {
  final int vehicleTypeId;
  final UpdateVehicleTypeRequest request;

  const UpdateVehicleType({
    required this.vehicleTypeId,
    required this.request,
  });

  @override
  List<Object?> get props => [vehicleTypeId, request];
}

class DeleteVehicleType extends VehicleTypeEvent {
  final int vehicleTypeId;

  const DeleteVehicleType({required this.vehicleTypeId});

  @override
  List<Object?> get props => [vehicleTypeId];
}

// States
abstract class VehicleTypeState extends Equatable {
  const VehicleTypeState();

  @override
  List<Object?> get props => [];
}

class VehicleTypeInitial extends VehicleTypeState {}

class VehicleTypeLoading extends VehicleTypeState {}

class VehicleTypesLoaded extends VehicleTypeState {
  final List<VehicleType> vehicleTypes;

  const VehicleTypesLoaded({required this.vehicleTypes});

  @override
  List<Object?> get props => [vehicleTypes];
}

class VehicleTypeDetailLoaded extends VehicleTypeState {
  final VehicleType vehicleType;

  const VehicleTypeDetailLoaded({required this.vehicleType});

  @override
  List<Object?> get props => [vehicleType];
}

class VehicleTypeOperationSuccess extends VehicleTypeState {
  final String message;

  const VehicleTypeOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class VehicleTypeError extends VehicleTypeState {
  final String message;

  const VehicleTypeError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class VehicleTypeBloc extends Bloc<VehicleTypeEvent, VehicleTypeState> {
  final VehicleTypeService _vehicleTypeService;

  VehicleTypeBloc({required VehicleTypeService vehicleTypeService})
      : _vehicleTypeService = vehicleTypeService,
        super(VehicleTypeInitial()) {
    on<LoadVehicleTypes>(_onLoadVehicleTypes);
    on<LoadVehicleTypeDetail>(_onLoadVehicleTypeDetail);
    on<CreateVehicleType>(_onCreateVehicleType);
    on<UpdateVehicleType>(_onUpdateVehicleType);
    on<DeleteVehicleType>(_onDeleteVehicleType);
  }

  Future<void> _onLoadVehicleTypes(
    LoadVehicleTypes event,
    Emitter<VehicleTypeState> emit,
  ) async {
    emit(VehicleTypeLoading());
    try {
      final vehicleTypes = await _vehicleTypeService.getVehicleTypes();
      emit(VehicleTypesLoaded(vehicleTypes: vehicleTypes));
    } catch (e) {
      emit(VehicleTypeError(message: e.toString()));
    }
  }

  Future<void> _onLoadVehicleTypeDetail(
    LoadVehicleTypeDetail event,
    Emitter<VehicleTypeState> emit,
  ) async {
    emit(VehicleTypeLoading());
    try {
      final vehicleType = await _vehicleTypeService.getVehicleTypeById(event.vehicleTypeId);
      emit(VehicleTypeDetailLoaded(vehicleType: vehicleType));
    } catch (e) {
      emit(VehicleTypeError(message: e.toString()));
    }
  }

  Future<void> _onCreateVehicleType(
    CreateVehicleType event,
    Emitter<VehicleTypeState> emit,
  ) async {
    emit(VehicleTypeLoading());
    try {
      await _vehicleTypeService.createVehicleType(event.request);
      emit(const VehicleTypeOperationSuccess(message: 'Tipe kendaraan berhasil ditambahkan'));
    } catch (e) {
      emit(VehicleTypeError(message: e.toString()));
    }
  }

  Future<void> _onUpdateVehicleType(
    UpdateVehicleType event,
    Emitter<VehicleTypeState> emit,
  ) async {
    emit(VehicleTypeLoading());
    try {
      await _vehicleTypeService.updateVehicleType(event.vehicleTypeId, event.request);
      emit(const VehicleTypeOperationSuccess(message: 'Tipe kendaraan berhasil diperbarui'));
    } catch (e) {
      emit(VehicleTypeError(message: e.toString()));
    }
  }

  Future<void> _onDeleteVehicleType(
    DeleteVehicleType event,
    Emitter<VehicleTypeState> emit,
  ) async {
    emit(VehicleTypeLoading());
    try {
      await _vehicleTypeService.deleteVehicleType(event.vehicleTypeId);
      emit(const VehicleTypeOperationSuccess(message: 'Tipe kendaraan berhasil dihapus'));
    } catch (e) {
      emit(VehicleTypeError(message: e.toString()));
    }
  }
}
