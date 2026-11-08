// O'lchov birliklari ERP'dagi nomi bilan ("Kilogram", "Dona", "dona", "Quti").
// Nomlar ERP'da qo'lda yoziladi, shuning uchun erkin solishtiriladi (o'zbekcha,
// ruscha, qisqartmalar) va sayt biladigan bir necha turga ajratiladi.

import '../l10n/strings.dart';

enum UnitKind { piece, kg, g, l, m, bag, pack, other }

String _normalize(String? name) => (name ?? '')
    .toLowerCase()
    .replaceAll(RegExp("[ʻʼ’‘`']"), '')
    .replaceAll(RegExp(r'[.\s]+'), ' ')
    .trim();

final _patterns = <(UnitKind, RegExp)>[
  (UnitKind.kg, RegExp(r'^(kilogramm?|kg|кг|килограмм?)')),
  (UnitKind.g, RegExp(r'^(gramm?|gr|g|гр|г|грамм?)$')),
  (UnitKind.l, RegExp(r'^(litr|l|литр|л)$')),
  (UnitKind.m, RegExp(r'^(metr|метр|m|м)$')),
  (UnitKind.bag, RegExp(r'^(qop|meshok|мешок|меш)')),
  (UnitKind.pack, RegExp(r'^(pachka|quti|korobka|upakovka|blok|пачка|упак|коробк|блок|уп$)')),
  (UnitKind.piece, RegExp(r'^(dona|shtuk|sht|ta$|шт|штук)')),
];

UnitKind unitKind(String? name) {
  final key = _normalize(name);
  if (key.isEmpty) return UnitKind.piece;
  for (final (kind, pattern) in _patterns) {
    if (pattern.hasMatch(key)) return kind;
  }
  return UnitKind.other;
}

/// Son yoki narxdan keyingi qisqa yorliq joriy tilda: "dona", "kg", "quti" /
/// "шт", "кг", "уп.". Ilova bilmagan birlik ERP'dagi nomi bilan qoladi.
/// Saqlangan yorliqni ("dona", "шт") ham taniydi — savat qatori shu bilan
/// til almashganda yangilanadi.
String unitLabel(String? name) {
  final kind = unitKind(name);
  if (kind != UnitKind.other) return tr.units[kind]!;
  final n = (name ?? '').trim().toLowerCase();
  return n.isEmpty ? tr.units[UnitKind.piece]! : n;
}

/// Ochiq ozuqa tortib sotiladi — kasr miqdorda (0.5 kg) buyurtma qilinadi.
bool isWeighed(String? name) => unitKind(name) == UnitKind.kg;

/// Tortiladigan va o'lchanadigan mahsulot o'ndan birlarda (1.5 kg, 0.3 l),
/// donabay mahsulot faqat butun.
bool allowsDecimal(String? name) {
  final kind = unitKind(name);
  return kind == UnitKind.kg || kind == UnitKind.l || kind == UnitKind.m;
}

/// Eng kam miqdor: 100 g ozuqa yoki bitta dona.
double minQty(bool decimal) => decimal ? 0.1 : 1;

/// − / + tugmalari qadami: ozuqada yarim kilo, qolganida bitta.
double qtyStep(bool decimal) => decimal ? 0.5 : 1;

/// O'lchanadigan — bir xona, donabay — butun.
double roundQty(double value, bool decimal) =>
    decimal ? (value * 10).round() / 10 : (value + 1e-9).floorToDouble();

/// `roundQty` kabi, lekin hech qachon yuqoriga emas: qoldiq ruxsat bergani.
/// 3.25 kg qolgan bo'lsa 3.2 kg buyurtma qilinadi.
double floorQty(double value, bool decimal) =>
    decimal ? (value * 10 + 1e-9).floorToDouble() / 10 : (value + 1e-9).floorToDouble();
