import '../../../core/models/customer.dart';
import '../../../core/network/api_client.dart';

class CustomerService {
  final ApiClient _apiClient;

  CustomerService({required ApiClient apiClient}) : _apiClient = apiClient;

  // Search customer by phone number
  Future<Customer?> searchCustomerByPhone(String phone) async {
    try {
      final response = await _apiClient.get('/api/customers/phone/$phone');

      if (response.statusCode == 200) {
        final data = response.data;
        print('🔍 Customer Search Response: $data');

        if (data['data'] != null && data['data']['customer'] != null) {
          print('🔍 Customer Data: ${data['data']['customer']}');
          return Customer.fromJson(data['data']['customer']);
        }
      } else if (response.statusCode == 404) {
        // Customer not found
        print('🔍 Customer not found: 404');
        return null;
      }

      throw Exception('Failed to search customer');
    } catch (e) {
      print('🔍 Customer Search Error: $e');
      // For now, return null if customer not found (API not implemented yet)
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        return null;
      }
      throw Exception('Error searching customer: $e');
    }
  }

  // Create new customer
  Future<Customer> createCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
  }) async {
    try {
      final data = {
        'name': name,
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        if (address != null && address.isNotEmpty) 'address': address,
      };

      final response = await _apiClient.post('/api/customers', data: data);

      if (response.statusCode == 201) {
        return Customer.fromJson(response.data['data']);
      }

      throw Exception('Failed to create customer');
    } catch (e) {
      throw Exception('Error creating customer: $e');
    }
  }

  // Get all customers (for dropdown/selection)
  Future<List<Customer>> getAllCustomers() async {
    try {
      final response = await _apiClient.get('/api/customers');

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> customersJson = data['data'] ?? [];
        return customersJson.map((json) => Customer.fromJson(json)).toList();
      }

      throw Exception('Failed to load customers');
    } catch (e) {
      throw Exception('Error loading customers: $e');
    }
  }
}
