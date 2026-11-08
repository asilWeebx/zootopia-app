import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/strings.dart';

/// Joylashuv xatosi (mijozga ko'rsatiladigan matn bilan).
class GeoException implements Exception {
  final String message;
  GeoException(this.message);
  @override
  String toString() => message;
}

/// Yetkazish joyini aniqlash: GPS + koordinatani manzilga aylantirish.
///
/// Reverse-geocode — OpenStreetMap Nominatim (bepul, kalitsiz). Javob kelmasa
/// null qaytadi, oqim to'xtamaydi (kuryer koordinata bo'yicha boradi).
class GeoService {
  static const LatLng tashkent = LatLng(41.311081, 69.240562);

  static Future<String?> reverseGeocode(double lat, double lng,
      {Duration timeout = const Duration(seconds: 8)}) async {
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2'
          '&lat=$lat&lon=$lng&zoom=18&addressdetails=1&accept-language=${appLang.value == AppLang.ru ? 'ru,uz' : 'uz,ru'}');
      final r = await http.get(uri, headers: {
        'User-Agent': 'dukonline-store-app/1.0 (order delivery location)'
      }).timeout(timeout);
      if (r.statusCode != 200) return null;
      final data = jsonDecode(utf8.decode(r.bodyBytes));
      final addr = data['address'];
      if (addr is Map) {
        final composed = _compose(Map<String, dynamic>.from(addr));
        if (composed != null && composed.isNotEmpty) return composed;
      }
      return data['display_name']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Nominatim javobidan ixcham manzil: ko'cha+uy → mavze → tuman → shahar.
  static String? _compose(Map<String, dynamic> a) {
    String s(String k) => (a[k]?.toString() ?? '').trim();
    String first(List<String> keys) {
      for (final k in keys) {
        if (s(k).isNotEmpty) return s(k);
      }
      return '';
    }

    final street = [
      first(['road', 'pedestrian', 'footway']),
      s('house_number'),
    ].where((e) => e.isNotEmpty).join(' ');
    final area = first(['residential', 'quarter', 'neighbourhood', 'suburb', 'hamlet']);
    final district = first(['city_district', 'county', 'district']);
    final city = first(['city', 'town', 'village', 'state']);

    final seen = <String>{};
    final out = <String>[];
    for (final p in [street, area, district, city]) {
      final t = p.trim();
      if (t.isNotEmpty && seen.add(t.toLowerCase())) out.add(t);
    }
    return out.isEmpty ? null : out.join(', ');
  }

  /// Joriy GPS joylashuvi. Ruxsat/xizmat yo'q bo'lsa [GeoException].
  static Future<LatLng> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw GeoException(tr.geoOff);
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      throw GeoException(tr.geoDenied);
    }
    if (perm == LocationPermission.deniedForever) {
      throw GeoException(tr.geoBlocked);
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LatLng(pos.latitude, pos.longitude);
  }
}
