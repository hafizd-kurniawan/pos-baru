import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

class TransactionService {
  final ApiClient _apiClient;

  TransactionService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Print invoice for a transaction
  Future<void> printInvoice(int transactionId, String type) async {
    try {
      // For now, simulate print functionality since backend doesn't have print endpoint yet
      await Future.delayed(Duration(milliseconds: 500));

      // TODO: Implement actual print API when backend is ready
      // String endpoint;
      // if (type == 'sales') {
      //   endpoint = ApiEndpoints.printInvoice(transactionId);
      // } else {
      //   endpoint = '/api/transactions/purchase/$transactionId/print';
      // }
      // final response = await _apiClient.post(endpoint);

      print('🖨️ Mock print invoice for transaction $transactionId');
    } catch (e) {
      throw Exception('Error printing invoice: $e');
    }
  }

  /// Generate PDF for a transaction
  Future<String> generatePDF(int transactionId, String type) async {
    try {
      // For now, simulate PDF generation since backend doesn't have PDF endpoint yet
      await Future.delayed(Duration(milliseconds: 800));

      // TODO: Implement actual PDF API when backend is ready
      // String endpoint;
      // if (type == 'sales') {
      //   endpoint = ApiEndpoints.generateInvoice(transactionId);
      // } else {
      //   endpoint = '/api/transactions/purchase/$transactionId/pdf';
      // }
      // final response = await _apiClient.get(endpoint);

      print('📄 Mock PDF generation for transaction $transactionId');
      return 'Invoice-$transactionId-${DateTime.now().millisecondsSinceEpoch}.pdf';
    } catch (e) {
      throw Exception('Error generating PDF: $e');
    }
  }

  /// Update payment status for a transaction
  Future<void> updatePaymentStatus({
    required int transactionId,
    required String type,
    required String paymentStatus,
    double? paidAmount,
    String? paymentMethod,
    String? notes,
  }) async {
    try {
      String endpoint;
      if (type == 'sales') {
        endpoint = ApiEndpoints.updateSalesPayment(transactionId);
      } else {
        endpoint = ApiEndpoints.updatePurchasePayment(transactionId);
      }

      final data = {
        'payment_status': paymentStatus,
        if (paidAmount != null) 'paid_amount': paidAmount,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (notes != null) 'notes': notes,
      };

      final response = await _apiClient.patch(endpoint, data: data);

      if (response.statusCode != 200) {
        throw Exception('Failed to update payment status');
      }
    } catch (e) {
      throw Exception('Error updating payment status: $e');
    }
  }
}
