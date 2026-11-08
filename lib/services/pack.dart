import '../l10n/strings.dart';

final _pack = RegExp(r'(\d+(?:[.,]\d+)?)\s*(кг|kg|килограмм|гр|грамм|г|gr|g)(?!\p{L})', caseSensitive: false, unicode: true);
final _kilo = RegExp(r'^(кг|kg|килограмм)$', caseSensitive: false, unicode: true);

/// Nomdagi qadoq hajmi: "Вискас пауч 80гр" → 80 g, "Royal Canin Indoor 2 кг" →
/// 2 000 g. Nomda bo'lmasa null.
int? packGrams(String name) {
  final match = _pack.firstMatch(name);
  if (match == null) return null;
  final value = double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
  if (!(value > 0)) return null;
  final grams = _kilo.hasMatch(match.group(2)!) ? value * 1000 : value;
  return grams.round();
}

/// "80 g", "2 kg", "1.5 kg" (rus tilida "80 г", "2 кг").
String formatGrams(num grams) {
  if (grams < 1000) return '${grams.round()} ${tr.g}';
  final kg = (grams / 100).round() / 10;
  return '${kg == kg.truncateToDouble() ? kg.toInt() : kg.toStringAsFixed(1)} ${tr.kg}';
}
