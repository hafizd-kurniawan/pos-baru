import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/models/vehicle.dart';
import '../../../../core/network/api_client.dart';

// Events
abstract class VehicleEvent extends Equatable {
  const VehicleEvent();

  @override
  List<Object?> get props => [];
}

class LoadVehicles extends VehicleEvent {
  final int page;
  final int limit;
  final String? status;

  const LoadVehicles({
    this.page = 1,
    this.limit = 10,
    this.status,
  });

  @override
  List<Object?> get props => [page, limit, status];
}

class LoadVehicleDetail extends VehicleEvent {
  final int vehicleId;

  const LoadVehicleDetail({required this.vehicleId});

  @override
  List<Object?> get props => [vehicleId];
}

class CreateVehicle extends VehicleEvent {
  final CreateVehicleRequest request;

  const CreateVehicle({required this.request});

  @override
  List<Object?> get props => [request];
}

class UpdateVehicle extends VehicleEvent {
  final int vehicleId;
  final UpdateVehicleRequest request;

  const UpdateVehicle({
    required this.vehicleId,
    required this.request,
  });

  @override
  List<Object?> get props => [vehicleId, request];
}

class SetSellingPrice extends VehicleEvent {
  final int vehicleId;
  final double sellingPrice;

  const SetSellingPrice({
    required this.vehicleId,
    required this.sellingPrice,
  });

  @override
  List<Object?> get props => [vehicleId, sellingPrice];
}

class DeleteVehicle extends VehicleEvent {
  final int vehicleId;

  const DeleteVehicle({required this.vehicleId});

  @override
  List<Object?> get props => [vehicleId];
}

// States
abstract class VehicleState extends Equatable {
  const VehicleState();

  @override
  List<Object?> get props => [];
}

class VehicleInitial extends VehicleState {}

class VehicleLoading extends VehicleState {}

class VehiclesLoaded extends VehicleState {
  final List<Vehicle> vehicles;
  final int total;
  final int currentPage;
  final bool hasMore;

  const VehiclesLoaded({
    required this.vehicles,
    required this.total,
    required this.currentPage,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [vehicles, total, currentPage, hasMore];
}

class VehicleDetailLoaded extends VehicleState {
  final Vehicle vehicle;

  const VehicleDetailLoaded({required this.vehicle});

  @override
  List<Object?> get props => [vehicle];
}

class VehicleOperationSuccess extends VehicleState {
  final String message;

  const VehicleOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class VehicleError extends VehicleState {
  final String message;

  const VehicleError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  final ApiClient _apiClient;

  VehicleBloc({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(VehicleInitial()) {
    on<LoadVehicles>(_onLoadVehicles);
    on<LoadVehicleDetail>(_onLoadVehicleDetail);
    on<CreateVehicle>(_onCreateVehicle);
    on<UpdateVehicle>(_onUpdateVehicle);
    on<SetSellingPrice>(_onSetSellingPrice);
    on<DeleteVehicle>(_onDeleteVehicle);
  }

  Future<void> _onLoadVehicles(
    LoadVehicles event,
    Emitter<VehicleState> emit,
  ) async {
    emit(VehicleLoading());
    try {
      final queryParams = <String, dynamic>{
        'page': event.page,
        'limit': event.limit,
      };

      if (event.status != null) {
        queryParams['status'] = event.status;
      }

      final response = await _apiClient.get(
        ApiEndpoints.vehicles,
        queryParameters: queryParams,
      );

      final data = response.data;
      final dataList = data['data'] as List?;
      final vehiclesList = dataList != null
          ? dataList.map((json) => Vehicle.fromJson(json)).toList()
          : <Vehicle>[];

      // Get meta information for pagination
      final meta = data['meta'] as Map<String, dynamic>?;

      emit(VehiclesLoaded(
        vehicles: vehiclesList,
        total: meta?['total'] ?? data['total'] ?? 0,
        currentPage: meta?['page'] ?? data['page'] ?? 1,
        hasMore: (meta?['page'] ?? data['page'] ?? 1) <
            (meta?['total_pages'] ?? data['total_pages'] ?? 1),
      ));
    } catch (e) {
      emit(VehicleError(message: e.toString()));
    }
  }

  Future<void> _onLoadVehicleDetail(
    LoadVehicleDetail event,
    Emitter<VehicleState> emit,
  ) async {
    emit(VehicleLoading());
    try {
      final response = await _apiClient.get(
        ApiEndpoints.vehicleById(event.vehicleId),
      );

      // Handle backend response structure: {success, message, data}
      final responseData = response.data;
      final vehicleData = responseData['data'] ?? responseData;

      final vehicle = Vehicle.fromJson(vehicleData);
      emit(VehicleDetailLoaded(vehicle: vehicle));
    } catch (e) {
      emit(VehicleError(message: e.toString()));
    }
  }

  Future<void> _onCreateVehicle(
    CreateVehicle event,
    Emitter<VehicleState> emit,
  ) async {
    emit(VehicleLoading());
    try {
      await _apiClient.post(
        ApiEndpoints.vehicles,
        data: event.request.toJson(),
      );

      emit(const VehicleOperationSuccess(
          message: 'Kendaraan berhasil ditambahkan'));
    } catch (e) {
      emit(VehicleError(message: e.toString()));
    }
  }

  Future<void> _onUpdateVehicle(
    UpdateVehicle event,
    Emitter<VehicleState> emit,
  ) async {
    emit(VehicleLoading());
    try {
      await _apiClient.put(
        ApiEndpoints.vehicleById(event.vehicleId),
        data: event.request.toJson(),
      );

      emit(const VehicleOperationSuccess(
          message: 'Kendaraan berhasil diperbarui'));
    } catch (e) {
      emit(VehicleError(message: e.toString()));
    }
  }

  Future<void> _onSetSellingPrice(
    SetSellingPrice event,
    Emitter<VehicleState> emit,
  ) async {
    emit(VehicleLoading());
    try {
      final request = SetSellingPriceRequest(sellingPrice: event.sellingPrice);

      await _apiClient.patch(
        ApiEndpoints.setVehicleSellingPrice(event.vehicleId),
        data: request.toJson(),
      );

      emit(const VehicleOperationSuccess(
          message: 'Harga jual berhasil ditetapkan'));
    } catch (e) {
      emit(VehicleError(message: e.toString()));
    }
  }

  Future<void> _onDeleteVehicle(
    DeleteVehicle event,
    Emitter<VehicleState> emit,
  ) async {
    emit(VehicleLoading());
    try {
      await _apiClient.delete(
        ApiEndpoints.vehicleById(event.vehicleId),
      );

      emit(
          const VehicleOperationSuccess(message: 'Kendaraan berhasil dihapus'));
    } catch (e) {
      emit(VehicleError(message: e.toString()));
    }
  }
}
