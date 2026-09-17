import 'package:flutter/material.dart';
import '../models/models.dart';

// ── Zootopiya palitra (yashil + krem) ──────────────────────────────
const kAccent     = Color(0xFF3E5C42); // to'q o'rmon yashili
const kAccentDark = Color(0xFF2C4230);
const kAccentBg   = Color(0x143E5C42); // 8% yashil fon
const kBg         = Color(0xFFF5F0E4); // krem fon
const kSurface    = Color(0xFFFFFFFF);
const kImgBg      = Color(0xFFF7F2E6); // mahsulot rasm foni (bej)
const kBorder     = Color(0xFFE8E2D2); // iliq chegara
const kText       = Color(0xFF1F2A20); // to'q yashil-kulrang matn
const kTextSub    = Color(0xFF7A7466);
const kTextMuted  = Color(0xFFB3AC9C);
const kGreen      = Color(0xFF22C55E);
const kRed        = Color(0xFFEF4444);

String somFormat(double n) {
  final s = n.round().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return "${buf.toString()} so'm";
}

// Valyutaga mos narx: USD → "$28", aks holda → "28,000 so'm"
String moneyFormat(double n, [String currency = '']) {
  if (currency.isEmpty || currency == 'UZS') return somFormat(n);
  final v = (n * 100).round() / 100;
  final intPart = v.truncate();
  final s = intPart.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  var out = buf.toString();
  if (v != intPart.toDouble()) {
    final cents = ((v - intPart).abs() * 100).round();
    out += '.${cents.toString().padLeft(2, '0')}';
  }
  return currency == 'USD' ? '\$$out' : '$currency $out';
}

// Savat jami — valyuta bo'yicha guruhlab ("$52  +  300,000 so'm")
String cartTotalStr(List<CartItem> items) {
  final Map<String, double> t = {};
  for (final it in items) { t[it.currency] = (t[it.currency] ?? 0) + it.curPrice * it.qty; }
  if (t.isEmpty) return somFormat(0);
  return t.entries.map((e) => moneyFormat(e.value, e.key)).join('  +  ');
}

String fmtDate(String iso) {
  try {
    final d = DateTime.parse(iso).toLocal();
    return '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';
  } catch (_) { return iso; }
}
