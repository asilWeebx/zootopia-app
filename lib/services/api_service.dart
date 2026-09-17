import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/models.dart';

class ApiService {
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-Storefront-Key': AppConfig.storefrontKey,
  };

  static String _url(String path) => '${AppConfig.apiUrl}$path';

  static Future<Map<String, dynamic>> _get(String path) async {
    final r = await http.get(Uri.parse(_url(path)), headers: _headers);
    if (r.statusCode != 200) {
      try {
        final body = jsonDecode(utf8.decode(r.bodyBytes));
        throw Exception(body['error'] ?? body['detail'] ?? 'Xatolik: ${r.statusCode}');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Xatolik: ${r.statusCode}');
      }
    }
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final r = await http.post(Uri.parse(_url(path)), headers: _headers, body: jsonEncode(body));
    final data = jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode >= 400) throw Exception(data['error'] ?? 'Xatolik');
    return data;
  }

  static Future<StoreInfo> getInfo() async {
    final data = await _get('/storefront/info/');
    return StoreInfo.fromJson(data);
  }

  static Future<List<Product>> getProducts({String? customerCode}) async {
    final q = customerCode != null ? '?customer_code=${Uri.encodeComponent(customerCode)}' : '';
    final data = await _get('/storefront/products/$q');
    final raw = data['results'];
    final list = raw is List ? raw : <dynamic>[];
    return list.map((p) => Product.fromJson(p as Map<String, dynamic>)).toList();
  }

  static Future<Customer> login(String code) async {
    final data = await _post('/storefront/login/', {'code': code});
    return Customer.fromJson(data);
  }

  /// App Store 5.1.1(v): hisobni o'chirish — server tomonda nofaol qilinadi,
  /// mijoz endi kira olmaydi. Xarid/qarz yozuvlari do'konda saqlanadi.
  static Future<void> deleteAccount(String code) async {
    await _post('/storefront/delete-account/', {'code': code});
  }

  /// FCM push token'ini ro'yxatga oladi (mijoz kirganda).
  static Future<void> registerDevice(String code, String token, String platform) async {
    await _post('/storefront/devices/', {'code': code, 'token': token, 'platform': platform});
  }

  /// Token'ni o'chiradi (chiqishda / hisob o'chirilganda).
  static Future<void> unregisterDevice(String token) async {
    final r = await http.delete(Uri.parse(_url('/storefront/devices/')),
        headers: _headers, body: jsonEncode({'token': token}));
    if (r.statusCode >= 400) throw Exception('unregister failed');
  }

  static Future<CustomerData> getCustomerData(String code) async {
    final data = await _get('/storefront/customer/?code=${Uri.encodeComponent(code)}');
    return CustomerData.fromJson(data);
  }

  static Future<OnlineOrder> submitOrder({
    required String name,
    required String phone,
    String? note,
    required List<CartItem> cart,
    String? customerCode,
    String deliveryType = 'courier', // 'courier' | 'pickup'
    String paymentMethod = 'cash', // 'cash' | 'card'
    String? address,
    String? landmark,
    double? latitude,
    double? longitude,
  }) async {
    final data = await _post('/storefront/orders/', {
      'customer_name': name,
      'phone': phone,
      if (note != null && note.isNotEmpty) 'note': note,
      if (customerCode != null) 'customer_code': customerCode,
      'delivery_type': deliveryType,
      'payment_method': paymentMethod,
      if (address != null && address.isNotEmpty) 'address': address,
      if (landmark != null && landmark.isNotEmpty) 'landmark': landmark,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'items': cart.map((c) => {
        'product_id': c.productId,
        if (c.variantId != null) 'variant_id': c.variantId,
        // unit_id faqat haqiqiy (>0) bo'lsa yuboriladi — 0/null server FK 500 sabab bo'ladi.
        if (c.unitId != null && c.unitId! > 0) 'unit_id': c.unitId,
        'qty': c.qty,
      }).toList(),
    });
    return OnlineOrder.fromJson(data);
  }

  static String mediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return AppConfig.apiUrl.replaceAll(RegExp(r'/api/?$'), '') + path;
  }
}
