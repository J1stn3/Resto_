import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/dining_table.dart';
import '../models/order.dart';

class ApiClient {
  ApiClient(this._prefs) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = _prefs.getString(AppConfig.tokenKey);
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) {
        if (e.response?.statusCode == 401) {
          _prefs.remove(AppConfig.tokenKey);
          _prefs.remove(AppConfig.userKey);
        }
        handler.next(e);
      },
    ));
  }

  final SharedPreferences _prefs;
  late final Dio _dio;

  Future<T> _unwrap<T>(Future<Response> future, T Function(dynamic) parse) async {
    try {
      final res = await future;
      final body = res.data as Map<String, dynamic>;
      if (body['success'] != true) {
        throw ApiException(body['message'] as String? ?? 'Request failed');
      }
      return parse(body['data']);
    } on DioException catch (e) {
      throw ApiException(_dioErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final loginId = email.trim().toLowerCase();
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': loginId,
        'username': loginId, // backward-compatible with older backend builds
        'password': password,
      });
      final body = res.data as Map<String, dynamic>;
      if (body['success'] != true) {
        throw ApiException(body['message'] as String? ?? 'Login failed');
      }
      final data = body['data'] as Map<String, dynamic>;
      await _prefs.setString(AppConfig.tokenKey, data['token'] as String);
      return data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.response == null) {
        throw ApiException(
          'Cannot reach API server.\n'
          'Start backend: cd resto_pos_system\\backend then npm run dev',
        );
      }
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw ApiException(data['message'] as String);
      }
      throw ApiException(e.message ?? 'Request failed');
    }
  }

  String _dioErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'] as String?;
      final detail = data['error'] as String?;
      if (message != null && detail != null && detail != message) {
        return '$message ($detail)';
      }
      if (message != null) return message;
    }
    if (e.type == DioExceptionType.connectionError || e.response == null) {
      return 'Cannot reach API server. Start backend: npm.cmd run dev';
    }
    return e.message ?? 'Request failed';
  }

  Future<User> getMe() async =>
      _unwrap(_dio.get('/auth/me'), (d) => User.fromJson(d as Map<String, dynamic>));

  Future<Map<String, dynamic>> getPaymentSummary(String orderId) async =>
      _unwrap(_dio.get('/orders/$orderId/payment-summary'), (d) => d as Map<String, dynamic>);

  Future<void> logout() async {
    try { await _dio.post('/auth/logout'); } catch (_) {}
    await _prefs.remove(AppConfig.tokenKey);
    await _prefs.remove(AppConfig.userKey);
  }

  String? get token => _prefs.getString(AppConfig.tokenKey);

  Future<List<Category>> getCategories({bool activeOnly = true}) async =>
      _unwrap(_dio.get('/categories', queryParameters: {'active_only': activeOnly}),
          (d) => (d as List).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList());

  Future<List<Product>> getProducts({String? categoryId, String? search}) async {
    final params = <String, dynamic>{'per_page': 100};
    if (categoryId != null) params['category_id'] = categoryId;
    if (search != null) params['search'] = search;
    return _unwrap(_dio.get('/products', queryParameters: params),
        (d) => (d as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList());
  }

  Future<List<DiningTable>> getTables() async =>
      _unwrap(_dio.get('/tables'),
          (d) => (d as List).map((e) => DiningTable.fromJson(e as Map<String, dynamic>)).toList());

  Future<List<Order>> getOrders({String? status}) async {
    final params = <String, dynamic>{'per_page': 50};
    if (status != null) params['status'] = status;
    return _unwrap(_dio.get('/orders', queryParameters: params),
        (d) => (d as List).map((e) => Order.fromJson(e as Map<String, dynamic>)).toList());
  }

  Future<Order> getOrder(String id) async =>
      _unwrap(_dio.get('/orders/$id'), (d) => Order.fromJson(d as Map<String, dynamic>));

  Future<Order> createOrder(Map<String, dynamic> body) async =>
      _unwrap(_dio.post('/orders', data: body), (d) => Order.fromJson(d as Map<String, dynamic>));

  Future<void> updateOrderStatus(String orderId, String status, {String? notes}) async {
    await _unwrap(_dio.patch('/orders/$orderId/status', data: {'status': status, if (notes != null) 'notes': notes}), (_) => null);
  }

  Future<void> processPayment(String orderId, String method, double amount, {String? reference}) async {
    await _unwrap(_dio.post('/orders/$orderId/payments',
        data: {'payment_method': method, 'amount': amount, if (reference != null) 'reference_number': reference}), (_) => null);
  }

  Future<List<Order>> getKitchenOrders() async =>
      _unwrap(_dio.get('/kitchen/orders'),
          (d) => (d as List).map((e) => Order.fromJson(e as Map<String, dynamic>)).toList());

  Future<void> updateItemStatus(String orderId, String itemId, String status) async {
    await _unwrap(_dio.patch('/kitchen/orders/$orderId/items/$itemId/status', data: {'status': status}), (_) => null);
  }

  Future<Map<String, dynamic>> getDashboardStats() async =>
      _unwrap(_dio.get('/admin/dashboard/stats'), (d) => d as Map<String, dynamic>);

  Future<Map<String, dynamic>> getIncomeReport(String period) async =>
      _unwrap(_dio.get('/admin/reports/income', queryParameters: {'period': period}), (d) => d as Map<String, dynamic>);

  Future<List<Map<String, dynamic>>> getSalesReport(String period) async =>
      _unwrap(_dio.get('/admin/reports/sales', queryParameters: {'period': period}),
          (d) => (d as List).cast<Map<String, dynamic>>());

  Future<List<Map<String, dynamic>>> getOrdersReport() async =>
      _unwrap(_dio.get('/admin/reports/orders'), (d) => (d as List).cast<Map<String, dynamic>>());

  Future<List<User>> getUsers({int page = 1, String? search}) async =>
      _unwrap(_dio.get('/admin/users', queryParameters: {'page': page, 'per_page': 20, if (search != null) 'search': search}),
          (d) => (d as List).map((e) => User.fromJson(e as Map<String, dynamic>)).toList());

  Future<List<Category>> getAdminCategories({int page = 1}) async =>
      _unwrap(_dio.get('/admin/categories', queryParameters: {'page': page, 'per_page': 50}),
          (d) => (d as List).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList());

  Future<List<Product>> getAdminProducts({int page = 1, String? search}) async =>
      _unwrap(_dio.get('/admin/products', queryParameters: {'page': page, 'per_page': 50, if (search != null) 'search': search}),
          (d) => (d as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList());

  Future<List<DiningTable>> getAdminTables() async =>
      _unwrap(_dio.get('/admin/tables', queryParameters: {'per_page': 50}),
          (d) => (d as List).map((e) => DiningTable.fromJson(e as Map<String, dynamic>)).toList());

  Future<void> createUser(Map<String, dynamic> data) async =>
      _unwrap(_dio.post('/admin/users', data: data), (_) => null);

  Future<void> updateUser(String id, Map<String, dynamic> data) async =>
      _unwrap(_dio.put('/admin/users/$id', data: data), (_) => null);

  Future<void> deleteUser(String id) async =>
      _unwrap(_dio.delete('/admin/users/$id'), (_) => null);

  Future<void> createCategory(Map<String, dynamic> data) async =>
      _unwrap(_dio.post('/admin/categories', data: data), (_) => null);

  Future<void> updateCategory(String id, Map<String, dynamic> data) async =>
      _unwrap(_dio.put('/admin/categories/$id', data: data), (_) => null);

  Future<void> deleteCategory(String id) async =>
      _unwrap(_dio.delete('/admin/categories/$id'), (_) => null);

  Future<void> createProduct(Map<String, dynamic> data) async =>
      _unwrap(_dio.post('/admin/products', data: data), (_) => null);

  Future<void> updateProduct(String id, Map<String, dynamic> data) async =>
      _unwrap(_dio.put('/admin/products/$id', data: data), (_) => null);

  Future<void> deleteProduct(String id) async =>
      _unwrap(_dio.delete('/admin/products/$id'), (_) => null);

  Future<void> createTable(Map<String, dynamic> data) async =>
      _unwrap(_dio.post('/admin/tables', data: data), (_) => null);

  Future<void> updateTable(String id, Map<String, dynamic> data) async =>
      _unwrap(_dio.put('/admin/tables/$id', data: data), (_) => null);

  Future<void> deleteTable(String id) async =>
      _unwrap(_dio.delete('/admin/tables/$id'), (_) => null);
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
