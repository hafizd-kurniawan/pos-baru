import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

// Events
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {}

class LoadAdminDashboard extends DashboardEvent {}

class LoadCashierDashboard extends DashboardEvent {}

class LoadMechanicDashboard extends DashboardEvent {}

// States
abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final Map<String, dynamic> data;

  const DashboardLoaded({required this.data});

  @override
  List<Object?> get props => [data];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ApiClient _apiClient;

  DashboardBloc({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<LoadAdminDashboard>(_onLoadAdminDashboard);
    on<LoadCashierDashboard>(_onLoadCashierDashboard);
    on<LoadMechanicDashboard>(_onLoadMechanicDashboard);
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final response = await _apiClient.get(ApiEndpoints.dashboard);
      emit(DashboardLoaded(data: response.data));
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  Future<void> _onLoadAdminDashboard(
    LoadAdminDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final response = await _apiClient.get(ApiEndpoints.adminDashboard);
      emit(DashboardLoaded(data: response.data));
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  Future<void> _onLoadCashierDashboard(
    LoadCashierDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final response = await _apiClient.get(ApiEndpoints.cashierDashboard);
      emit(DashboardLoaded(data: response.data));
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  Future<void> _onLoadMechanicDashboard(
    LoadMechanicDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final response = await _apiClient.get(ApiEndpoints.mechanicDashboard);
      emit(DashboardLoaded(data: response.data));
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }
}