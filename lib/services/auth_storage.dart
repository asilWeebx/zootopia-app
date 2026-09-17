import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AuthStorage {
  static const _key = 'customer_v1';

  static Future<void> save(Customer c) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode({
      'name': c.name,
      'customer_code': c.code,
      'phone': c.phone,
      'debt': c.debt,
      'credit': c.credit,
    }));
  }

  static Future<Customer?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return Customer.fromJson(jsonDecode(raw));
    } catch (_) { return null; }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
