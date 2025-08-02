import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter/foundation.dart';
import '../storage/storage_service.dart';
import '../constants/api_endpoints.dart';

class ApiClient {
  late final Dio _dio;
  
  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    // Pretty logger for debug mode
    if (kDebugMode) {
      _dio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ));
    }
    
    // Auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired, redirect to login
          await StorageService.clearToken();
          // Navigate to login screen
        }
        handler.next(error);
      },
    ));
  }
  
  // GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Koneksi timeout, silakan coba lagi',
          statusCode: null,
          type: ApiExceptionType.timeout,
        );
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        String message = 'Terjadi kesalahan server';
        
        if (error.response?.data != null) {
          final data = error.response!.data;
          if (data is Map<String, dynamic> && data.containsKey('message')) {
            message = data['message'];
          } else if (data is String) {
            message = data;
          }
        }
        
        return ApiException(
          message: message,
          statusCode: statusCode,
          type: _getExceptionType(statusCode),
        );
      
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request dibatalkan',
          statusCode: null,
          type: ApiExceptionType.cancel,
        );
      
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
      default:
        return ApiException(
          message: 'Tidak dapat terhubung ke server',
          statusCode: null,
          type: ApiExceptionType.network,
        );
    }
  }
  
  ApiExceptionType _getExceptionType(int? statusCode) {
    switch (statusCode) {
      case 400:
        return ApiExceptionType.badRequest;
      case 401:
        return ApiExceptionType.unauthorized;
      case 403:
        return ApiExceptionType.forbidden;
      case 404:
        return ApiExceptionType.notFound;
      case 422:
        return ApiExceptionType.validation;
      case 500:
        return ApiExceptionType.server;
      default:
        return ApiExceptionType.unknown;
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiExceptionType type;
  
  const ApiException({
    required this.message,
    required this.statusCode,
    required this.type,
  });
  
  @override
  String toString() => message;
}

enum ApiExceptionType {
  network,
  timeout,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  cancel,
  unknown,
}