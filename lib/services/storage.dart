import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import 'cart_lines.dart';

/// Qurilmada saqlanadigan narsalar: savat, mijoz, kalkulyator javoblari va
/// tebranish va til sozlamasi (saytdagi localStorage kalitlari bilan bir xil nomlar).
class Storage {
  static const _cartKey = 'zt_cart_v1';
  static const _customerKey = 'zt_customer_v1';
  static const _feedingKey = 'zt_feeding_v1';
  static const _hapticsKey = 'zt_haptics';
  static const _langKey = 'zt_lang';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<Object?> _readJson(String key) async {
    try {
      final raw = (await _prefs).getString(key);
      return raw == null ? null : jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeJson(String key, Object? value) async {
    try {
      final prefs = await _prefs;
      if (value == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, jsonEncode(value));
      }
    } catch (_) {
      // Saqlash — qulaylik; xotiradagi qiymat baribir ishlaydi.
    }
  }

  static Future<List<CartItem>> loadCart() async => sanitizeStoredCart(await _readJson(_cartKey));
  static Future<void> saveCart(List<CartItem> items) => _writeJson(_cartKey, items.map((i) => i.toJson()).toList());

  /// Ilovaning oldingi versiyasi mijozni shu kalitda saqlagan.
  static const _legacyCustomerKey = 'customer_v1';

  static Future<Customer?> loadCustomer() async {
    var saved = await _readJson(_customerKey);
    if (saved is! Map) {
      // Yangilangan ilovada mijoz qaytadan kirishga majbur bo'lmasin.
      saved = await _readJson(_legacyCustomerKey);
      if (saved is Map) {
        await _writeJson(_customerKey, saved);
        try {
          await (await _prefs).remove(_legacyCustomerKey);
        } catch (_) {}
      }
    }
    if (saved is! Map) return null;
    final c = Customer(Map<String, dynamic>.from(saved));
    return c.customerCode.isNotEmpty ? c : null;
  }

  static Future<void> saveCustomer(Customer? c) => _writeJson(_customerKey, c?.raw);

  static Future<Object?> loadFeeding() => _readJson(_feedingKey);
  static Future<void> saveFeeding(Map<String, dynamic> profile) => _writeJson(_feedingKey, profile);

  static Future<bool> loadHaptics() async {
    try {
      return (await _prefs).getString(_hapticsKey) == '1';
    } catch (_) {
      return false;
    }
  }

  static Future<void> saveHaptics(bool on) async {
    try {
      await (await _prefs).setString(_hapticsKey, on ? '1' : '0');
    } catch (_) {}
  }

  /// Tanlangan til; hali tanlanmagan bo'lsa — rus tili.
  static Future<AppLang> loadLang() async {
    try {
      final saved = (await _prefs).getString(_langKey);
      return AppLang.values.where((l) => l.name == saved).firstOrNull ?? AppLang.ru;
    } catch (_) {
      return AppLang.ru;
    }
  }

  static Future<void> saveLang(AppLang lang) async {
    try {
      await (await _prefs).setString(_langKey, lang.name);
    } catch (_) {}
  }
}
