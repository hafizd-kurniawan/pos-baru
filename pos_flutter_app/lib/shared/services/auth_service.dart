import '../../core/network/api_client.dart';
import '../../core/storage/storage_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/models/user.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: request.toJson(),
    );

    final loginResponse = LoginResponse.fromJson(response.data);
    
    // Save token and user data
    await StorageService.saveToken(loginResponse.token);
    await StorageService.saveUserData(loginResponse.user.toJson());
    
    return loginResponse;
  }

  Future<User> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.profile);
    return User.fromJson(response.data);
  }

  Future<User> register(RegisterRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      data: request.toJson(),
    );
    return User.fromJson(response.data);
  }

  Future<void> changePassword(ChangePasswordRequest request) async {
    await _apiClient.post(
      ApiEndpoints.changePassword,
      data: request.toJson(),
    );
  }

  Future<void> logout() async {
    await StorageService.clearToken();
    await StorageService.clearUserData();
  }

  Future<bool> isAuthenticated() async {
    return await StorageService.hasToken();
  }

  Future<User?> getCurrentUser() async {
    final userData = await StorageService.getUserData();
    if (userData != null) {
      return User.fromJson(userData);
    }
    return null;
  }
}