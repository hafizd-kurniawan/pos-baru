import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/models/customer.dart';
import '../../../../core/models/sale_transaction.dart';
import '../../../../core/models/vehicle.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/services/sale_transaction_service.dart';

// Events
abstract class SalesEvent extends Equatable {
  const SalesEvent();

  @override
  List<Object?> get props => [];
}

class LoadAvailableVehiclesForSale extends SalesEvent {
  final VehicleFilter filter;

  const LoadAvailableVehiclesForSale({
    this.filter = const VehicleFilter(),
  });

  @override
  List<Object?> get props => [filter];
}

class LoadVehicleBrands extends SalesEvent {}

class LoadVehicleModels extends SalesEvent {
  final String? brand;

  const LoadVehicleModels({this.brand});

  @override
  List<Object?> get props => [brand];
}

class SearchCustomerByPhone extends SalesEvent {
  final String phone;

  const SearchCustomerByPhone({required this.phone});

  @override
  List<Object?> get props => [phone];
}

class ClearCustomerSearch extends SalesEvent {}

class CreateSale extends SalesEvent {
  final CreateSaleTransactionRequest request;

  const CreateSale({required this.request});

  @override
  List<Object?> get props => [request];
}

class GenerateInvoice extends SalesEvent {
  final int saleId;

  const GenerateInvoice({required this.saleId});

  @override
  List<Object?> get props => [saleId];
}

class PrintInvoice extends SalesEvent {
  final int saleId;

  const PrintInvoice({required this.saleId});

  @override
  List<Object?> get props => [saleId];
}

// States
abstract class SalesState extends Equatable {
  const SalesState();

  @override
  List<Object?> get props => [];
}

class SalesInitial extends SalesState {}

class SalesLoading extends SalesState {}

class AvailableVehiclesLoaded extends SalesState {
  final List<Vehicle> vehicles;
  final VehicleFilter currentFilter;

  const AvailableVehiclesLoaded({
    required this.vehicles,
    required this.currentFilter,
  });

  @override
  List<Object?> get props => [vehicles, currentFilter];
}

class VehicleBrandsLoaded extends SalesState {
  final List<String> brands;

  const VehicleBrandsLoaded({required this.brands});

  @override
  List<Object?> get props => [brands];
}

class VehicleModelsLoaded extends SalesState {
  final List<String> models;
  final String? forBrand;

  const VehicleModelsLoaded({
    required this.models,
    this.forBrand,
  });

  @override
  List<Object?> get props => [models, forBrand];
}

class CustomerSearchLoaded extends SalesState {
  final Customer? customer;
  final String searchPhone;

  const CustomerSearchLoaded({
    this.customer,
    required this.searchPhone,
  });

  @override
  List<Object?> get props => [customer, searchPhone];
}

class SaleCreated extends SalesState {
  final SaleTransaction sale;

  const SaleCreated({required this.sale});

  @override
  List<Object?> get props => [sale];
}

class InvoiceGenerated extends SalesState {
  final Map<String, dynamic> invoiceData;

  const InvoiceGenerated({required this.invoiceData});

  @override
  List<Object?> get props => [invoiceData];
}

class InvoicePrinted extends SalesState {
  final String message;

  const InvoicePrinted({required this.message});

  @override
  List<Object?> get props => [message];
}

class SalesError extends SalesState {
  final String message;

  const SalesError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final SaleTransactionService _saleTransactionService;
  final ApiClient _apiClient;

  SalesBloc({
    required SaleTransactionService saleTransactionService,
    required ApiClient apiClient,
  })  : _saleTransactionService = saleTransactionService,
        _apiClient = apiClient,
        super(SalesInitial()) {
    on<LoadAvailableVehiclesForSale>(_onLoadAvailableVehiclesForSale);
    on<LoadVehicleBrands>(_onLoadVehicleBrands);
    on<LoadVehicleModels>(_onLoadVehicleModels);
    on<SearchCustomerByPhone>(_onSearchCustomerByPhone);
    on<ClearCustomerSearch>(_onClearCustomerSearch);
    on<CreateSale>(_onCreateSale);
    on<GenerateInvoice>(_onGenerateInvoice);
    on<PrintInvoice>(_onPrintInvoice);
  }

  Future<void> _onLoadAvailableVehiclesForSale(
    LoadAvailableVehiclesForSale event,
    Emitter<SalesState> emit,
  ) async {
    emit(SalesLoading());
    try {
      // Build query parameters for available vehicles
      final queryParams = <String, dynamic>{
        'status': 'available', // Only load available vehicles for sale
        'page': 1,
        'limit': 50, // Get more vehicles for selection
      };

      // Add filter parameters if they exist
      if (event.filter.search != null && event.filter.search!.isNotEmpty) {
        queryParams['search'] = event.filter.search;
      }
      if (event.filter.brand != null && event.filter.brand!.isNotEmpty) {
        queryParams['brand'] = event.filter.brand;
      }
      if (event.filter.type != null && event.filter.type!.isNotEmpty) {
        queryParams['type'] = event.filter.type;
      }
      if (event.filter.minYear != null) {
        queryParams['min_year'] = event.filter.minYear;
      }
      if (event.filter.maxYear != null) {
        queryParams['max_year'] = event.filter.maxYear;
      }
      if (event.filter.sortBy != null && event.filter.sortBy!.isNotEmpty) {
        queryParams['sort_by'] = event.filter.sortBy;
      }
      if (event.filter.sortOrder != null &&
          event.filter.sortOrder!.isNotEmpty) {
        queryParams['sort_order'] = event.filter.sortOrder;
      }

      // Debug print untuk melihat filter yang diterapkan
      print('🔍 Filter Query Parameters: $queryParams');
      print('🔍 Original Filter: ${event.filter}');

      final response = await _apiClient.get(
        ApiEndpoints.vehicles,
        queryParameters: queryParams,
      );

      final data = response.data;
      final dataList = data['data'] as List?;
      final vehiclesList = dataList != null
          ? dataList.map((json) => Vehicle.fromJson(json)).toList()
          : <Vehicle>[];

      // Debug print untuk melihat hasil filter
      print('🚗 Vehicles loaded: ${vehiclesList.length} vehicles');
      if (vehiclesList.isNotEmpty) {
        print('🚗 First vehicle: ${vehiclesList.first.brand?.name} ${vehiclesList.first.model}');
      }

      emit(AvailableVehiclesLoaded(
        vehicles: vehiclesList,
        currentFilter: event.filter,
      ));
    } catch (e) {
      print('❌ Error loading vehicles: $e');
      emit(SalesError(message: e.toString()));
    }
  }

  Future<void> _onSearchCustomerByPhone(
    SearchCustomerByPhone event,
    Emitter<SalesState> emit,
  ) async {
    emit(SalesLoading());
    try {
      // This would call the customer service to search by phone
      // For now, we'll emit a simple state

      emit(CustomerSearchLoaded(
        customer: null, // Will be replaced with actual API call
        searchPhone: event.phone,
      ));
    } catch (e) {
      emit(SalesError(message: e.toString()));
    }
  }

  Future<void> _onClearCustomerSearch(
    ClearCustomerSearch event,
    Emitter<SalesState> emit,
  ) async {
    emit(SalesInitial());
  }

  Future<void> _onCreateSale(
    CreateSale event,
    Emitter<SalesState> emit,
  ) async {
    emit(SalesLoading());
    try {
      final sale =
          await _saleTransactionService.createSaleTransaction(event.request);
      emit(SaleCreated(sale: sale));
    } catch (e) {
      emit(SalesError(message: e.toString()));
    }
  }

  Future<void> _onGenerateInvoice(
    GenerateInvoice event,
    Emitter<SalesState> emit,
  ) async {
    emit(SalesLoading());
    try {
      final invoiceData =
          await _saleTransactionService.generateInvoice(event.saleId);
      emit(InvoiceGenerated(invoiceData: invoiceData));
    } catch (e) {
      emit(SalesError(message: e.toString()));
    }
  }

  Future<void> _onPrintInvoice(
    PrintInvoice event,
    Emitter<SalesState> emit,
  ) async {
    emit(SalesLoading());
    try {
      await _saleTransactionService.printInvoice(event.saleId);
      emit(const InvoicePrinted(message: 'Invoice berhasil dicetak'));
    } catch (e) {
      emit(SalesError(message: e.toString()));
    }
  }

  Future<void> _onLoadVehicleBrands(
    LoadVehicleBrands event,
    Emitter<SalesState> emit,
  ) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.vehicleBrands);

      final data = response.data;
      final Set<String> brandsSet = {}; // Use Set to avoid duplicates

      if (data is List) {
        // If response is directly a list of brand objects
        for (final item in data) {
          if (item is Map<String, dynamic> && item.containsKey('name')) {
            final brandName = item['name'].toString().trim();
            if (brandName.isNotEmpty) {
              brandsSet.add(brandName);
            }
          } else if (item is String) {
            final brandName = item.trim();
            if (brandName.isNotEmpty) {
              brandsSet.add(brandName);
            }
          }
        }
      } else if (data is Map && data.containsKey('data')) {
        final dataList = data['data'] as List?;
        if (dataList != null) {
          for (final item in dataList) {
            if (item is Map<String, dynamic> && item.containsKey('name')) {
              final brandName = item['name'].toString().trim();
              if (brandName.isNotEmpty) {
                brandsSet.add(brandName);
              }
            } else if (item is String) {
              final brandName = item.trim();
              if (brandName.isNotEmpty) {
                brandsSet.add(brandName);
              }
            }
          }
        }
      }

      // Convert Set to sorted List
      final List<String> brands = brandsSet.toList()..sort();

      emit(VehicleBrandsLoaded(brands: brands));
    } catch (e) {
      emit(SalesError(message: e.toString()));
    }
  }

  Future<void> _onLoadVehicleModels(
    LoadVehicleModels event,
    Emitter<SalesState> emit,
  ) async {
    try {
      String endpoint = ApiEndpoints.vehicleModels;
      if (event.brand != null && event.brand!.isNotEmpty) {
        endpoint = ApiEndpoints.vehicleModelsByBrand(event.brand!);
      }

      final response = await _apiClient.get(endpoint);

      final data = response.data;
      final List<String> models = [];

      if (data is List) {
        models.addAll(data.map((item) => item.toString()));
      } else if (data is Map && data.containsKey('data')) {
        final dataList = data['data'] as List?;
        if (dataList != null) {
          models.addAll(dataList.map((item) => item.toString()));
        }
      }

      emit(VehicleModelsLoaded(models: models, forBrand: event.brand));
    } catch (e) {
      emit(SalesError(message: e.toString()));
    }
  }
}
