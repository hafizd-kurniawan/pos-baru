import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/models/customer.dart';

// Events
abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CustomerEvent {
  final int page;
  final int limit;
  final String? search;

  const LoadCustomers({
    this.page = 1,
    this.limit = 10,
    this.search,
  });

  @override
  List<Object?> get props => [page, limit, search];
}

class LoadCustomerDetail extends CustomerEvent {
  final int customerId;

  const LoadCustomerDetail({required this.customerId});

  @override
  List<Object?> get props => [customerId];
}

class CreateCustomer extends CustomerEvent {
  final CreateCustomerRequest request;

  const CreateCustomer({required this.request});

  @override
  List<Object?> get props => [request];
}

class UpdateCustomer extends CustomerEvent {
  final int customerId;
  final UpdateCustomerRequest request;

  const UpdateCustomer({
    required this.customerId,
    required this.request,
  });

  @override
  List<Object?> get props => [customerId, request];
}

class DeleteCustomer extends CustomerEvent {
  final int customerId;

  const DeleteCustomer({required this.customerId});

  @override
  List<Object?> get props => [customerId];
}

class SearchCustomerByPhone extends CustomerEvent {
  final String phone;

  const SearchCustomerByPhone({required this.phone});

  @override
  List<Object?> get props => [phone];
}

class SearchCustomerByEmail extends CustomerEvent {
  final String email;

  const SearchCustomerByEmail({required this.email});

  @override
  List<Object?> get props => [email];
}

// States
abstract class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomersLoaded extends CustomerState {
  final List<Customer> customers;
  final int total;
  final int currentPage;
  final bool hasMore;

  const CustomersLoaded({
    required this.customers,
    required this.total,
    required this.currentPage,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [customers, total, currentPage, hasMore];
}

class CustomerDetailLoaded extends CustomerState {
  final Customer customer;

  const CustomerDetailLoaded({required this.customer});

  @override
  List<Object?> get props => [customer];
}

class CustomerOperationSuccess extends CustomerState {
  final String message;

  const CustomerOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class CustomerError extends CustomerState {
  final String message;

  const CustomerError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final ApiClient _apiClient;

  CustomerBloc({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<LoadCustomerDetail>(_onLoadCustomerDetail);
    on<CreateCustomer>(_onCreateCustomer);
    on<UpdateCustomer>(_onUpdateCustomer);
    on<DeleteCustomer>(_onDeleteCustomer);
    on<SearchCustomerByPhone>(_onSearchCustomerByPhone);
    on<SearchCustomerByEmail>(_onSearchCustomerByEmail);
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      final queryParams = <String, dynamic>{
        'page': event.page,
        'limit': event.limit,
      };
      
      if (event.search != null) {
        queryParams['search'] = event.search;
      }

      final response = await _apiClient.get(
        ApiEndpoints.customers,
        queryParameters: queryParams,
      );

      final data = response.data;
      final customersList = (data['data'] as List)
          .map((json) => Customer.fromJson(json))
          .toList();

      emit(CustomersLoaded(
        customers: customersList,
        total: data['total'] ?? 0,
        currentPage: data['page'] ?? 1,
        hasMore: (data['page'] ?? 1) < (data['total_pages'] ?? 1),
      ));
    } catch (e) {
      emit(CustomerError(message: e.toString()));
    }
  }

  Future<void> _onLoadCustomerDetail(
    LoadCustomerDetail event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      final response = await _apiClient.get(
        ApiEndpoints.customerById(event.customerId),
      );

      final customer = Customer.fromJson(response.data);
      emit(CustomerDetailLoaded(customer: customer));
    } catch (e) {
      emit(CustomerError(message: e.toString()));
    }
  }

  Future<void> _onCreateCustomer(
    CreateCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      await _apiClient.post(
        ApiEndpoints.customers,
        data: event.request.toJson(),
      );

      emit(const CustomerOperationSuccess(message: 'Customer berhasil ditambahkan'));
    } catch (e) {
      emit(CustomerError(message: e.toString()));
    }
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      await _apiClient.put(
        ApiEndpoints.customerById(event.customerId),
        data: event.request.toJson(),
      );

      emit(const CustomerOperationSuccess(message: 'Customer berhasil diperbarui'));
    } catch (e) {
      emit(CustomerError(message: e.toString()));
    }
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      await _apiClient.delete(
        ApiEndpoints.customerById(event.customerId),
      );

      emit(const CustomerOperationSuccess(message: 'Customer berhasil dihapus'));
    } catch (e) {
      emit(CustomerError(message: e.toString()));
    }
  }

  Future<void> _onSearchCustomerByPhone(
    SearchCustomerByPhone event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      final response = await _apiClient.get(
        ApiEndpoints.customerByPhone(event.phone),
      );

      final customer = Customer.fromJson(response.data);
      emit(CustomerDetailLoaded(customer: customer));
    } catch (e) {
      emit(CustomerError(message: e.toString()));
    }
  }

  Future<void> _onSearchCustomerByEmail(
    SearchCustomerByEmail event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      final response = await _apiClient.get(
        ApiEndpoints.customerByEmail(event.email),
      );

      final customer = Customer.fromJson(response.data);
      emit(CustomerDetailLoaded(customer: customer));
    } catch (e) {
      emit(CustomerError(message: e.toString()));
    }
  }
}