// Pul formati. Har narx o'z valyutasida: USD — `$50`, qolgani so'm. Bo'sh
// valyuta — do'konning asosiy valyutasi (dukonline'da so'm).

import '../l10n/strings.dart';

/// Minglar orasida bo'sh joy — O'zbekiston savdosidagi odat.
String _withThousands(String value) =>
    value.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');

/// `som(50000) -> "50 000 so'm"` / `"50 000 сум"`.
String som(num? amount) => '${_withThousands(((amount ?? 0).toDouble()).round().toString())} ${tr.som}';

/// `money(50, "USD") -> "$50"`, `money(50000, "") -> "50 000 so'm"`.
String money(num? amount, [String? currency]) {
  if (currency == null || currency.isEmpty || currency == 'UZS') return som(amount);
  final value = (((amount ?? 0).toDouble()) * 100).round() / 100;
  final isInt = value == value.truncateToDouble();
  final whole = isInt ? value.truncate().toString() : value.toStringAsFixed(2).split('.')[0];
  final fraction = isInt ? '' : value.toStringAsFixed(2).split('.')[1];
  final prefix = currency == 'USD' ? r'$' : '$currency ';
  return prefix + _withThousands(whole) + (fraction.isNotEmpty ? '.$fraction' : '');
}

class TotalInput {
  final String currency;
  final double price;
  final double? curPrice;
  final double qty;
  const TotalInput({required this.currency, required this.price, this.curPrice, required this.qty});
}

/// API valyuta kursini bermaydi, shuning uchun jami har valyutada alohida:
/// `"$52  +  300 000 so'm"`.
String groupTotal(Iterable<TotalInput> items) {
  final totals = <String, double>{};
  for (final item in items) {
    final code = item.currency;
    totals[code] = (totals[code] ?? 0) + (item.curPrice ?? item.price) * item.qty;
  }
  if (totals.isEmpty) return som(0);
  return totals.entries.map((e) => money(e.value, e.key)).join('  +  ');
}

/// Butun son "2", kasr "2.5" (ko'pi bilan 2 xona).
String fmtNumber(num value) {
  final rounded = (value * 100).round() / 100;
  final whole = _withThousands(rounded.truncate().abs().toString());
  final sign = rounded < 0 ? '-' : '';
  if (rounded == rounded.truncateToDouble()) return '$sign$whole';
  final fraction = rounded.abs().toStringAsFixed(2).split('.')[1].replaceFirst(RegExp(r'0+$'), '');
  return '$sign$whole.$fraction';
}

/// Kilogrammdagi og'irlik, gramm aniqligida: `"0,345"`, `"2,158"` — har doim
/// uch xona, miqdorlar bir xil ko'rinsin (saytdagi `exactKg`).
String exactKg(num kg) => kg.toDouble().toStringAsFixed(3).replaceAll('.', ',');
