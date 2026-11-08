import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../l10n/strings.dart';
import '../models/models.dart';

class StorefrontError implements Exception {
  final String message;
  final int status;
  const StorefrontError(this.message, this.status);
  @override
  String toString() => message;
}

/// API'ga yetib bo'lmadi (internet yo'q, vaqt tugadi).
class NetworkError implements Exception {
  const NetworkError();
  @override
  String toString() => tr.network;
}

class ApiService {
  /// api.dukonline.uz User-Agent'siz so'rovlarga 403 qaytaradi.
  static const _userAgent = 'dukonline-store-app/1.0 (zootopiya)';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Storefront-Key': AppConfig.storefrontKey,
        'User-Agent': _userAgent,
      };

  static Uri _url(String path) => Uri.parse('${AppConfig.apiUrl}$path');

  /// Media manzillari mutlaq (CDN) yoki API hostiga nisbatan keladi.
  static String media(String? url) {
    if (url == null || url.isEmpty) return '';
    if (RegExp(r'^(https?:|data:|blob:)').hasMatch(url)) return url;
    return AppConfig.apiUrl.replaceFirst(RegExp(r'/api/?$'), '') + url;
  }

  static Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response r;
    try {
      r = await request().timeout(const Duration(seconds: 25));
    } on SocketException {
      throw const NetworkError();
    } on TimeoutException {
      throw const NetworkError();
    } on http.ClientException {
      throw const NetworkError();
    } on HandshakeException {
      throw const NetworkError();
    }
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      body = null;
    }
    if (r.statusCode < 200 || r.statusCode >= 300) {
      final error = body is Map ? (body['error'] ?? body['detail']) : null;
      throw StorefrontError(error is String && error.isNotEmpty ? error : tr.apiStatus(r.statusCode), r.statusCode);
    }
    return body;
  }

  static Future<dynamic> _get(String path) => _send(() => http.get(_url(path), headers: _headers));

  static Future<dynamic> _post(String path, Map<String, dynamic> body) =>
      _send(() => http.post(_url(path), headers: _headers, body: jsonEncode(body)));

  /// Do'kon nomi, valyuta va ERP'ga yuklangan bannerlar.
  static Future<StoreInfo> getInfo() async =>
      StoreInfo.fromJson(Map<String, dynamic>.from(await _get('/storefront/info/') as Map), media);

  /// Butun katalog bitta javobda. `customerCode` — shu mijozning narxlari.
  static Future<CatalogResponse> getCatalog({String? customerCode}) async {
    final query = customerCode != null && customerCode.isNotEmpty
        ? '?customer_code=${Uri.encodeComponent(customerCode)}'
        : '';
    return CatalogResponse.fromJson(Map<String, dynamic>.from(await _get('/storefront/products/$query') as Map));
  }

  /// Ko'p sotilganlar — katalog bilan solishtiriladigan id'lar.
  static Future<List<int>> getTopProductIds({int limit = 12}) async {
    final data = await _get('/storefront/top-products/?limit=$limit');
    final ids = data is Map ? data['product_ids'] : null;
    return ids is List ? ids.whereType<num>().map((n) => n.toInt()).toList() : const [];
  }

  /// Do'konda berilgan mijoz kodini mijoz yozuviga almashtiradi.
  static Future<Customer> login(String code) async =>
      Customer(Map<String, dynamic>.from(await _post('/storefront/login/', {'code': code}) as Map));

  /// Kirgan mijozning qarzi, balansi va xaridlar tarixi.
  static Future<CustomerAccount> getCustomer(String code) async => CustomerAccount.fromJson(
      Map<String, dynamic>.from(await _get('/storefront/customer/?code=${Uri.encodeComponent(code)}') as Map));

  /// Buyurtma raqamini qaytaradi.
  static Future<String> createOrder(Map<String, dynamic> payload) async {
    final data = await _post('/storefront/orders/', payload);
    final no = data is Map ? (data['order_no'] ?? data['id']) : null;
    return no == null ? '' : '$no';
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
    await _send(() => http.delete(_url('/storefront/devices/'), headers: _headers, body: jsonEncode({'token': token})));
  }
}
