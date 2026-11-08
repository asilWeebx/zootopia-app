import '../models/models.dart';
import 'units.dart';

/// Xaridor mahsulotdan tanlaydigan narsa: bir ta'm/o'lcham (variant) yoki
/// variantsiz mahsulotning bir birligi (kg, dona, quti). Ikkalasi bitta
/// shaklga keltiriladi — tanlagich, karta va savat tarmoqlanmaydi.
class BuyOption {
  /// Mahsulot ichida barqaror: `v<variant id>`, `u<unit id>` yoki `base`.
  final String key;
  final int? variantId;
  /// Faqat asosiy bo'lmagan birlik uchun; asosiy birlik — buyurtma sukuti.
  final int? unitId;
  /// Variant nomi yoki (bir nechta bo'lsa) birlik nomi; aks holda "".
  final String label;
  /// ERP'dagi birlik nomi ("Kilogram").
  final String unitName;
  /// Kasr (1.5 kg) buyurtma qilish mumkinmi.
  final bool decimal;
  /// Bittasi asosiy birlikdan nechtasini oladi (1 quti = 24 dona).
  final double multiplier;
  /// Qaysi qoldiqdan oladi: mahsulot birliklari umumiy qoldiqni, har variant
  /// o'z qoldig'ini.
  final String pool;
  /// Pool qoldig'i asosiy birlikda; hisoblanmasa `double.infinity`.
  final double poolStock;
  final String sku;
  final String image;
  /// So'mda.
  final double price;
  /// `curPrice` kabi `currency`da; chegirma bo'lmasa null.
  final double? originalPrice;
  /// Bo'sh — so'm.
  final String currency;
  final double curPrice;
  /// Shu birlikdan nechta bor; hisoblanmasa `double.infinity`.
  final double stock;
  final bool inStock;

  const BuyOption({
    required this.key,
    this.variantId,
    this.unitId,
    required this.label,
    required this.unitName,
    required this.decimal,
    required this.multiplier,
    required this.pool,
    required this.poolStock,
    required this.sku,
    required this.image,
    required this.price,
    this.originalPrice,
    required this.currency,
    required this.curPrice,
    required this.stock,
    required this.inStock,
  });

  /// Qisqa yorliq joriy tilda: "kg", "dona", "quti" / "кг", "шт", "уп.".
  String get unit => unitLabel(unitName);
}

bool hasVariants(Product p) => p.hasVariants && p.variants.isNotEmpty;

/// Mahsulotning o'z birligi: multiplikatorsiz, bo'lmasa birinchisi.
ProductUnit? baseUnit(Product p) {
  for (final u in p.units) {
    if (u.isBase == true) return u;
  }
  for (final u in p.units) {
    if ((u.multiplier == 0 ? 1 : u.multiplier) == 1) return u;
  }
  return p.units.isEmpty ? null : p.units.first;
}

double _unitStock(double stock, double multiplier, bool decimal) {
  if (!stock.isFinite) return double.infinity;
  final v = floorQty(stock / (multiplier == 0 ? 1 : multiplier), decimal);
  return v < 0 ? 0 : v;
}

final _optionsCache = Expando<List<BuyOption>>();

List<BuyOption> productOptions(Product p) => _optionsCache[p] ??= _buildOptions(p);

List<BuyOption> _buildOptions(Product p) {
  final tracked = p.stockType == 'tracked';
  final base = baseUnit(p);
  final baseName = (base?.unitName.isNotEmpty ?? false) ? base!.unitName : 'dona';

  if (hasVariants(p)) {
    final decimal = allowsDecimal(baseName);
    return [
      for (final v in p.variants)
        () {
          final poolStock = tracked ? ((v.stock ?? 0) < 0 ? 0.0 : (v.stock ?? 0)) : double.infinity;
          final stock = _unitStock(poolStock, 1, decimal);
          return BuyOption(
            key: 'v${v.id}',
            variantId: v.id,
            label: v.name.trim(),
            unitName: baseName,
            decimal: decimal,
            multiplier: 1,
            pool: 'v${v.id}',
            poolStock: poolStock,
            sku: v.sku.isNotEmpty ? v.sku : p.sku,
            image: (v.image ?? '').isNotEmpty ? v.image! : p.image,
            price: v.price,
            originalPrice: v.currency.isNotEmpty ? v.curOriginalPrice : (v.curOriginalPrice ?? v.originalPrice),
            currency: v.currency,
            curPrice: v.curPrice,
            stock: stock,
            inStock: (!tracked || v.inStock) && stock >= minQty(decimal),
          );
        }(),
    ];
  }

  if (p.units.isEmpty) return const [];
  final several = p.units.length > 1;
  return [
    for (final u in p.units)
      () {
        final decimal = allowsDecimal(u.unitName);
        final multiplier = u.multiplier == 0 ? 1.0 : u.multiplier;
        final poolStock = tracked ? (p.stock < 0 ? 0.0 : p.stock) : double.infinity;
        final stock = _unitStock(poolStock, multiplier, decimal);
        return BuyOption(
          key: u.unitId != null ? 'u${u.unitId}' : 'base',
          unitId: u.unitId,
          label: several ? u.unitName.trim() : '',
          unitName: u.unitName.isNotEmpty ? u.unitName : 'dona',
          decimal: decimal,
          multiplier: multiplier,
          pool: 'p${p.id}',
          poolStock: poolStock,
          sku: p.sku,
          image: p.image,
          price: u.price,
          originalPrice: u.currency.isNotEmpty ? u.curOriginalPrice : (u.curOriginalPrice ?? u.originalPrice),
          currency: u.currency,
          curPrice: u.curPrice,
          stock: stock,
          inStock: (!tracked || p.inStock) && stock >= minQty(decimal),
        );
      }(),
  ];
}

/// So'ralgan variant bo'lsa — u, bo'lmasa omborda borining birinchisi.
BuyOption? defaultOption(List<BuyOption> options, [String? key]) {
  for (final o in options) {
    if (key != null && o.key == key) return o;
  }
  for (final o in options) {
    if (o.inStock) return o;
  }
  return options.isEmpty ? null : options.first;
}

bool isOutOfStock(Product p) => !productOptions(p).any((o) => o.inStock);

class PriceGroup {
  final BuyOption option;
  /// Narxlar har xil — "dan" bilan ko'rsatiladi.
  final bool varies;
  const PriceGroup(this.option, this.varies);
}

/// Karta yoki qidiruv natijasidagi narx. Birliklar hajmi bilan farq qiladi,
/// shuning uchun variantsiz mahsulot asosiy birligini ko'rsatadi ("6 000 so'm /
/// dona", quti emas). Variantlar bitta birlikda, shuning uchun omborda bor eng
/// arzoni — haqiqiy boshlang'ich narx ("45 000 so'm dan"), har valyutada alohida.
List<PriceGroup> optionPriceGroups(List<BuyOption> options) {
  if (!options.any((o) => o.variantId != null)) {
    final base = options.where((o) => o.multiplier == 1).firstOrNull ?? options.firstOrNull;
    return base == null ? const [] : [PriceGroup(base, false)];
  }
  return cheapestByCurrency(options);
}

/// Omborda borlarining (hech biri bo'lmasa hammasining) eng arzoni, har
/// valyutada alohida, va qolganlari qimmatroqmi.
List<PriceGroup> cheapestByCurrency(List<BuyOption> options) {
  final available = options.where((o) => o.inStock).toList();
  final groups = <String, List<BuyOption>>{};
  for (final option in available.isNotEmpty ? available : options) {
    final key = option.currency.isEmpty ? 'UZS' : option.currency;
    (groups[key] ??= []).add(option);
  }
  return [
    for (final group in groups.values)
      PriceGroup(
        group.reduce((min, next) => next.curPrice < min.curPrice ? next : min),
        group.map((o) => o.curPrice).toSet().length > 1,
      ),
  ];
}

/// Oz qoldi: kartada va xarid qutisida belgilashga arziydi (5 kg, 10 pauch).
bool isLowStock(BuyOption option) {
  if (!option.inStock || !option.stock.isFinite) return false;
  return option.stock <= (option.decimal ? 5 : 10);
}

/// Mahsulot rasmlari: asosiysi birinchi, keyin unda yo'q variant rasmlari.
List<String> productGallery(Product p) {
  final photos = <String>[...(p.images.isNotEmpty ? p.images : [p.image])];
  for (final v in p.variants) {
    if ((v.image ?? '').isNotEmpty) photos.add(v.image!);
  }
  final seen = <String>{};
  return [for (final x in photos) if (x.isNotEmpty && seen.add(x)) x];
}
