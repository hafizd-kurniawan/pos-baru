import 'customer.dart';
import 'vehicle.dart';

class Transaction {
  final int id;
  final String invoiceNumber;
  final String type; // 'purchase' or 'sales'
  final int vehicleId;
  final Vehicle? vehicle;
  final int? customerId;
  final Customer? customer;
  final int? supplierId;
  final String? supplierName;
  final String sourceType;
  final int? sourceId;
  final String? sourceName;
  final double amount;
  final double paidAmount;
  final double remainingAmount;
  final String paymentMethod;
  final String paymentStatus; // 'pending', 'partial', 'paid'
  final String? notes;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Transaction({
    required this.id,
    required this.invoiceNumber,
    required this.type,
    required this.vehicleId,
    this.vehicle,
    this.customerId,
    this.customer,
    this.supplierId,
    this.supplierName,
    required this.sourceType,
    this.sourceId,
    this.sourceName,
    required this.amount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.notes,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Determine transaction type and map fields accordingly
    String transactionType;
    double amount;
    double paidAmount;
    double remainingAmount;

    // Check if this is a purchase or sales transaction based on available fields
    if (json.containsKey('purchase_price')) {
      // This is a purchase transaction
      transactionType = 'purchase';
      amount = (json['purchase_price'] as num?)?.toDouble() ?? 0.0;
      paidAmount = amount; // For now, assume full payment
      remainingAmount = 0.0;
    } else {
      // This is a sales transaction
      transactionType = 'sales';
      amount = (json['selling_price'] as num?)?.toDouble() ?? 0.0;
      double downPayment = (json['down_payment'] as num?)?.toDouble() ?? 0.0;
      remainingAmount = (json['remaining_payment'] as num?)?.toDouble() ?? 0.0;

      // Calculate paid amount based on payment status
      String paymentStatus = json['payment_status'] ?? 'pending';
      if (paymentStatus == 'paid') {
        paidAmount = amount; // Fully paid
      } else if (paymentStatus == 'partial') {
        paidAmount = downPayment;
      } else {
        paidAmount = 0.0; // Pending payment
      }
    }

    return Transaction(
      id: json['id'] ?? 0,
      invoiceNumber: json['invoice_number'] ?? '',
      type: transactionType,
      vehicleId: json['vehicle_id'] ?? 0,
      vehicle:
          json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
      customerId: json['customer_id'],
      customer:
          json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      supplierId: json['supplier_id'],
      supplierName: json['supplier_name'],
      sourceType: json['source_type'] ??
          (transactionType == 'purchase' ? 'supplier' : 'customer'),
      sourceId: json['source_id'] ?? json['customer_id'] ?? json['supplier_id'],
      sourceName: json['source_name'],
      amount: amount,
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'] ?? 'pending',
      notes: json['notes'],
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'])
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'type': type,
      'vehicle_id': vehicleId,
      'vehicle': vehicle?.toJson(),
      'customer_id': customerId,
      'customer': customer?.toJson(),
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'source_type': sourceType,
      'source_id': sourceId,
      'source_name': sourceName,
      'amount': amount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'notes': notes,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get typeDisplay {
    switch (type) {
      case 'purchase':
        return 'Pembelian';
      case 'sales':
        return 'Penjualan';
      default:
        return type;
    }
  }

  String get paymentStatusDisplay {
    switch (paymentStatus) {
      case 'pending':
        return 'Belum Bayar';
      case 'partial':
        return 'Bayar Sebagian';
      case 'paid':
        return 'Lunas';
      default:
        return paymentStatus;
    }
  }

  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case 'cash':
        return 'Tunai';
      case 'transfer':
        return 'Transfer';
      case 'check':
        return 'Cek';
      case 'credit':
        return 'Kredit';
      default:
        return paymentMethod;
    }
  }

  Transaction copyWith({
    int? id,
    String? invoiceNumber,
    String? type,
    int? vehicleId,
    Vehicle? vehicle,
    int? customerId,
    Customer? customer,
    int? supplierId,
    String? supplierName,
    String? sourceType,
    int? sourceId,
    String? sourceName,
    double? amount,
    double? paidAmount,
    double? remainingAmount,
    String? paymentMethod,
    String? paymentStatus,
    String? notes,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      type: type ?? this.type,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicle: vehicle ?? this.vehicle,
      customerId: customerId ?? this.customerId,
      customer: customer ?? this.customer,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, invoiceNumber: $invoiceNumber, type: $type, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class CreatePurchaseTransactionRequest {
  final String sourceType;
  final int? sourceId;
  final int vehicleId;
  final double purchasePrice;
  final String paymentMethod;
  final String paymentStatus;
  final String? notes;

  const CreatePurchaseTransactionRequest({
    required this.sourceType,
    this.sourceId,
    required this.vehicleId,
    required this.purchasePrice,
    required this.paymentMethod,
    required this.paymentStatus,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'source_type': sourceType,
      'source_id': sourceId,
      'vehicle_id': vehicleId,
      'purchase_price': purchasePrice,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'notes': notes,
    };
  }
}

class CreateSalesTransactionRequest {
  final int customerId;
  final int vehicleId;
  final double sellingPrice;
  final String paymentMethod;
  final String paymentStatus;
  final String? notes;

  const CreateSalesTransactionRequest({
    required this.customerId,
    required this.vehicleId,
    required this.sellingPrice,
    required this.paymentMethod,
    required this.paymentStatus,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'vehicle_id': vehicleId,
      'selling_price': sellingPrice,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'notes': notes,
    };
  }
}

class UpdateTransactionPaymentRequest {
  final double paidAmount;
  final String paymentMethod;
  final String? notes;

  const UpdateTransactionPaymentRequest({
    required this.paidAmount,
    required this.paymentMethod,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'paid_amount': paidAmount,
      'payment_method': paymentMethod,
      'notes': notes,
    };
  }
}
