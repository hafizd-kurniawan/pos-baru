import '../../core/constants/api_endpoints.dart';
import '../../core/models/sale_transaction.dart';
import '../../core/network/api_client.dart';

class SaleTransactionService {
  final ApiClient _apiClient;

  SaleTransactionService({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<List<SaleTransaction>> getSaleTransactions({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final response = await _apiClient.get(
      ApiEndpoints.sales,
      queryParameters: queryParams,
    );

    final responseData = response.data;
    final listData = responseData['data'] as List?;

    if (listData != null) {
      return listData.map((json) => SaleTransaction.fromJson(json)).toList();
    }
    return [];
  }

  Future<SaleTransaction> getSaleTransactionById(int id) async {
    final response = await _apiClient.get(ApiEndpoints.saleById(id));

    final responseData = response.data;
    final saleData = responseData['data'] ?? responseData;

    return SaleTransaction.fromJson(saleData);
  }

  Future<SaleTransaction> createSaleTransaction(
      CreateSaleTransactionRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.sales,
      data: request.toJson(),
    );

    final responseData = response.data;
    final saleData = responseData['data'] ?? responseData;

    return SaleTransaction.fromJson(saleData);
  }

  Future<Map<String, dynamic>> generateInvoice(int saleId) async {
    final response = await _apiClient.get(ApiEndpoints.generateInvoice(saleId));

    final responseData = response.data;
    return responseData['data'] ?? responseData;
  }

  Future<void> printInvoice(int saleId) async {
    await _apiClient.post(ApiEndpoints.printInvoice(saleId));
  }
}
