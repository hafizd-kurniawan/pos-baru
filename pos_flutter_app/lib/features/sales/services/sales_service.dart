import '../../../core/models/customer.dart';
import '../../../core/models/vehicle.dart';
import '../../../core/network/api_client.dart';

class SalesTransaction {
  final int? id;
  final String? invoiceNumber;
  final DateTime? transactionDate;
  final int customerId;
  final int vehicleId;
  final double hppPrice;
  final double sellingPrice;
  final double profit;
  final String? paymentMethod;
  final String paymentStatus;
  final double downPayment;
  final double remainingPayment;
  final String? notes;
  final Customer? customer;
  final Vehicle? vehicle;

  SalesTransaction({
    this.id,
    this.invoiceNumber,
    this.transactionDate,
    required this.customerId,
    required this.vehicleId,
    this.hppPrice = 0.0,
    required this.sellingPrice,
    this.profit = 0.0,
    this.paymentMethod,
    required this.paymentStatus,
    required this.downPayment,
    this.remainingPayment = 0.0,
    this.notes,
    this.customer,
    this.vehicle,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'vehicle_id': vehicleId,
      'hpp_price': hppPrice,
      'selling_price': sellingPrice,
      'profit': profit,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'down_payment': downPayment,
      'remaining_payment': remainingPayment,
      'notes': notes,
    };
  }

  factory SalesTransaction.fromJson(Map<String, dynamic> json) {
    return SalesTransaction(
      id: json['id'],
      invoiceNumber: json['invoice_number'],
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'])
          : null,
      customerId: json['customer_id'] ?? 0,
      vehicleId: json['vehicle_id'] ?? 0,
      hppPrice: (json['hpp_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'] ?? 'pending',
      downPayment: (json['down_payment'] as num?)?.toDouble() ?? 0.0,
      remainingPayment: (json['remaining_payment'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'],
      customer:
          json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      vehicle:
          json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
    );
  }
}

class SalesService {
  final ApiClient _apiClient;

  SalesService({required ApiClient apiClient}) : _apiClient = apiClient;

  // Create new sales transaction
  Future<SalesTransaction> createTransaction({
    required int customerId,
    required int vehicleId,
    required double sellingPrice,
    String? paymentMethod,
    String paymentStatus = 'pending',
    double downPayment = 0.0,
    String? notes,
  }) async {
    try {
      final data = {
        'customer_id': customerId,
        'vehicle_id': vehicleId,
        'selling_price': sellingPrice,
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        'down_payment': downPayment,
        'notes': notes,
      };

      print('📤 Creating sales transaction: $data');

      final response =
          await _apiClient.post('/api/sales/transactions', data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        print('✅ Sales transaction created: $responseData');

        if (responseData['data'] != null &&
            responseData['data']['data'] != null) {
          return SalesTransaction.fromJson(responseData['data']['data']);
        }
      }

      throw Exception('Failed to create sales transaction');
    } catch (e) {
      print('❌ Sales transaction creation error: $e');
      throw Exception('Error creating sales transaction: $e');
    }
  }

  // Get available vehicles for sale
  Future<List<Vehicle>> getAvailableVehicles({
    String? search,
    String? brand,
    int? yearFrom,
    int? yearTo,
    String sortBy = 'created_at',
  }) async {
    try {
      String queryParams = '?';
      List<String> params = [];

      if (search != null && search.isNotEmpty) {
        params.add('search=${Uri.encodeComponent(search)}');
      }
      if (brand != null && brand.isNotEmpty) {
        params.add('brand=${Uri.encodeComponent(brand)}');
      }
      if (yearFrom != null) {
        params.add('year_from=$yearFrom');
      }
      if (yearTo != null) {
        params.add('year_to=$yearTo');
      }
      params.add('sort_by=$sortBy');

      queryParams += params.join('&');

      final response =
          await _apiClient.get('/api/sales/vehicles/available$queryParams');

      if (response.statusCode == 200) {
        final data = response.data;
        print('🚗 Available vehicles response: $data');

        if (data['data'] != null) {
          final List<dynamic> vehiclesJson = data['data'];
          return vehiclesJson.map((json) => Vehicle.fromJson(json)).toList();
        }
      }

      return [];
    } catch (e) {
      print('❌ Get available vehicles error: $e');
      return [];
    }
  }

  // Get sales transactions
  Future<List<SalesTransaction>> getTransactions({
    int page = 1,
    int limit = 10,
    String? status,
    String? dateFrom,
    String? dateTo,
    int? customerId,
  }) async {
    try {
      String queryParams = '?page=$page&limit=$limit';

      if (status != null && status.isNotEmpty) {
        queryParams += '&status=${Uri.encodeComponent(status)}';
      }
      if (dateFrom != null && dateFrom.isNotEmpty) {
        queryParams += '&date_from=${Uri.encodeComponent(dateFrom)}';
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        queryParams += '&date_to=${Uri.encodeComponent(dateTo)}';
      }
      if (customerId != null) {
        queryParams += '&customer_id=$customerId';
      }

      final response =
          await _apiClient.get('/api/sales/transactions$queryParams');

      if (response.statusCode == 200) {
        final data = response.data;
        print('📋 Sales transactions response: $data');

        if (data['data'] != null) {
          final List<dynamic> transactionsJson = data['data'];
          return transactionsJson
              .map((json) => SalesTransaction.fromJson(json))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print('❌ Get sales transactions error: $e');
      return [];
    }
  }

  // Get single sales transaction
  Future<SalesTransaction?> getTransaction(int id) async {
    try {
      final response = await _apiClient.get('/api/sales/transactions/$id');

      if (response.statusCode == 200) {
        final data = response.data;
        print('📄 Sales transaction response: $data');

        if (data['data'] != null) {
          return SalesTransaction.fromJson(data['data']);
        }
      }

      return null;
    } catch (e) {
      print('❌ Get sales transaction error: $e');
      return null;
    }
  }
}
