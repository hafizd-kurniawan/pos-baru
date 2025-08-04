import '../../../../core/models/customer.dart';
import '../../../../core/models/user.dart';
import '../../../../core/models/vehicle.dart';

class SaleTransaction {
  final int id;
  final String transactionCode;
  final int vehicleId;
  final int customerId;
  final double sellingPrice;
  final double? downPayment;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime transactionDate;
  final String? notes;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related objects
  final Vehicle? vehicle;
  final Customer? customer;
  final User? salesperson;

  const SaleTransaction({
    required this.id,
    required this.transactionCode,
    required this.vehicleId,
    required this.customerId,
    required this.sellingPrice,
    this.downPayment,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.transactionDate,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.vehicle,
    this.customer,
    this.salesperson,
  });

  factory SaleTransaction.fromJson(Map<String, dynamic> json) {
    return SaleTransaction(
      id: (json['id'] as num).toInt(),
      transactionCode: json['transaction_code'] as String,
      vehicleId: (json['vehicle_id'] as num).toInt(),
      customerId: (json['customer_id'] as num).toInt(),
      sellingPrice: (json['selling_price'] as num).toDouble(),
      downPayment: json['down_payment'] != null
          ? (json['down_payment'] as num).toDouble()
          : null,
      paymentMethod: json['payment_method'] as String,
      paymentStatus: json['payment_status'] as String,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      notes: json['notes'] as String?,
      createdBy: (json['created_by'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      vehicle: json['vehicle'] != null
          ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      customer: json['customer'] != null
          ? Customer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      salesperson: json['salesperson'] != null
          ? User.fromJson(json['salesperson'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_code': transactionCode,
      'vehicle_id': vehicleId,
      'customer_id': customerId,
      'selling_price': sellingPrice,
      'down_payment': downPayment,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'transaction_date': transactionDate.toIso8601String(),
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'vehicle': vehicle?.toJson(),
      'customer': customer?.toJson(),
      'salesperson': salesperson?.toJson(),
    };
  }
}

class CreateSaleTransactionRequest {
  final int vehicleId;
  final int customerId;
  final double sellingPrice;
  final double? downPayment;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime transactionDate;
  final String? notes;

  const CreateSaleTransactionRequest({
    required this.vehicleId,
    required this.customerId,
    required this.sellingPrice,
    this.downPayment,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.transactionDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'customer_id': customerId,
      'selling_price': sellingPrice,
      'down_payment': downPayment,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'transaction_date': transactionDate.toIso8601String(),
      'notes': notes,
    };
  }
}

class VehicleFilter {
  final String? search;
  final int? minYear;
  final int? maxYear;
  final String? brand;
  final String? model;
  final String? type;
  final String? sortBy;
  final String? sortOrder;

  const VehicleFilter({
    this.search,
    this.minYear,
    this.maxYear,
    this.brand,
    this.model,
    this.type,
    this.sortBy,
    this.sortOrder,
  });

  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> params = {};

    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (minYear != null) params['min_year'] = minYear;
    if (maxYear != null) params['max_year'] = maxYear;
    if (brand != null && brand!.isNotEmpty) params['brand'] = brand;
    if (model != null && model!.isNotEmpty) params['model'] = model;
    if (type != null && type!.isNotEmpty) params['type'] = type;
    if (sortBy != null && sortBy!.isNotEmpty) params['sort_by'] = sortBy;
    if (sortOrder != null && sortOrder!.isNotEmpty)
      params['sort_order'] = sortOrder;

    return params;
  }
}
