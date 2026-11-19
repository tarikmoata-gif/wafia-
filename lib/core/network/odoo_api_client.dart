import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";

final odooApiProvider = Provider<OdooApiClient>((ref) => OdooApiClient());

class OdooApiClient {
  static const String baseUrl = "https://your-odoo-domain.com/api/v1";
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  OdooApiClient()
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {"Content-Type": "application/json"},
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: "odoo_auth_token");
        if (token != null && token.isNotEmpty) {
          options.headers["Authorization"] = "Bearer \$token";
        }
        return handler.next(options);
      },
    ));
  }

  Future<void> requestOtp(String phone) async {
    await _dio.post("/auth/otp/request", data: {"phone": phone});
  }

  Future<String> verifyOtp({required String phone, required String code}) async {
    final res = await _dio.post("/auth/otp/verify", data: {
      "phone": phone,
      "code": code,
    });
    final token = res.data["token"] as String;
    await _storage.write(key: "odoo_auth_token", value: token);
    return token;
  }

  Future<void> deleteAccount() async {
    await _dio.delete("/account");
    await _storage.delete(key: "odoo_auth_token");
  }

  Future<Response> postOrder({
    required int productVariantId,
    required double lat,
    required double lng,
    required String district,
    DateTime? scheduledDatetime,
  }) async {
    return _dio.post("/orders", data: {
      "product_variant_id": productVariantId,
      "lat": lat,
      "lng": lng,
      "district": district,
      "scheduled_datetime": scheduledDatetime?.toIso8601String(),
    });
  }

  Future<void> confirmOrderPayment({
    required int orderId,
    required String moyasarPaymentId,
  }) async {
    await _dio.post("/orders/\$orderId/pay", data: {
      "moyasar_payment_id": moyasarPaymentId,
    });
  }

  Future<Map<String, dynamic>> getOrderTracking(int orderId) async {
    final response = await _dio.get("/orders/\$orderId/tracking");
    return response.data as Map<String, dynamic>;
  }
}
