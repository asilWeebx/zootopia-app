import '../l10n/strings.dart';
import '../models/models.dart';
import 'currency.dart';
import 'options.dart';
import 'units.dart';

// Sof savat reduserlari: har biri joriy qatorlarni olib keyingisini qaytaradi,
// hech narsa o'zgarmasa — o'sha ro'yxatni. CartController natijani saqlaydi.

/// "Cheksiz"ning saqlanadigan o'rnini bosuvchisi: JSON'da Infinity yo'q.
const kUnlimited = 999999.0;

double _storable(double max) => max.isFinite ? max : kUnlimited;

String lineKey(int productId, String optionKey) => '${productId}_$optionKey';

/// Narx × miqdor, qatorning o'z valyutasida.
double lineTotal(CartItem it) => it.curPrice * it.qty;

/// Qatorlar `groupTotal` qo'shadigan shaklda.
Iterable<TotalInput> totalsInput(List<CartItem> cart) =>
    cart.map((it) => TotalInput(currency: it.currency, price: it.price, curPrice: it.curPrice, qty: it.qty));

/// `pool`dagi boshqa qatorlar egallagan asosiy birliklar.
double _usedInPool(List<CartItem> cart, String pool, String exceptKey) =>
    cart.fold(0, (sum, x) => x.pool == pool && x.key != exceptKey ? sum + x.qty * x.multiplier : sum);

/// `option`dan qator ko'pi bilan qancha ola oladi: qoldig'i, shu qoldiqdagi
/// boshqa qatorlar (mahsulotning boshqa birligi) olganidan tashqari.
double capFor(List<CartItem> cart, int productId, BuyOption option) {
  if (!option.inStock) return 0;
  if (!option.poolStock.isFinite) return double.infinity;
  final free = option.poolStock - _usedInPool(cart, option.pool, lineKey(productId, option.key));
  final v = floorQty(free / option.multiplier, option.decimal);
  return v < 0 ? 0 : v;
}

CartItem _lineFor(Product p, BuyOption option, double qty, double max) {
  final rounded = roundQty(qty, option.decimal);
  return CartItem(
    key: lineKey(p.id, option.key),
    productId: p.id,
    variantId: option.variantId,
    unitId: option.unitId,
    optionKey: option.key,
    pool: option.pool,
    multiplier: option.multiplier,
    name: p.name,
    optionLabel: option.label,
    sku: option.sku,
    image: option.image,
    qty: rounded < max ? rounded : max,
    maxQty: _storable(max),
    unit: option.unit,
    decimal: option.decimal,
    price: option.price,
    currency: option.currency,
    curPrice: option.curPrice,
  );
}

/// `option`dan `qty` qo'shadi — qoldig'idan oshirmay.
List<CartItem> addLine(List<CartItem> cart, Product p, BuyOption option, double qty) {
  final max = capFor(cart, p.id, option);
  if (max < minQty(option.decimal) || !(qty > 0)) return cart;

  final key = lineKey(p.id, option.key);
  final existing = cart.where((x) => x.key == key).firstOrNull;
  if (existing != null) {
    final sum = roundQty(existing.qty + qty, option.decimal);
    final next = sum < max ? sum : max;
    if (next == existing.qty) return cart;
    return [for (final x in cart) x.key == key ? x.copyWith(qty: next, maxQty: _storable(max)) : x];
  }
  return [...cart, _lineFor(p, option, qty, max)];
}

/// Qator miqdorini o'rnatadi (qoldiq bilan cheklab); eng kamidan pasti — o'chiradi.
List<CartItem> setLineQty(List<CartItem> cart, String key, double qty) {
  final item = cart.where((x) => x.key == key).firstOrNull;
  if (item == null) return cart;
  final rounded = roundQty(qty, item.decimal);
  final capped = rounded < item.maxQty ? rounded : item.maxQty;
  if (!(capped >= minQty(item.decimal))) return cart.where((x) => x.key != key).toList();
  if (capped == item.qty) return cart;
  return [for (final x in cart) x.key == key ? x.copyWith(qty: capped) : x];
}

List<CartItem> removeLine(List<CartItem> cart, String key) =>
    cart.any((x) => x.key == key) ? cart.where((x) => x.key != key).toList() : cart;

bool _sameLines(List<CartItem> a, List<CartItem> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final x = a[i].toJson(), y = b[i].toJson();
    for (final k in x.keys) {
      if (x[k] != y[k]) return false;
    }
  }
  return true;
}

/// Saqlangan qatorlarni joriy katalog bilan tekshiradi: narx, nom va rasm
/// yangilanadi; miqdor qoldiq bilan cheklanadi (bir qoldiqni bo'lishadigan
/// qatorlar savat tartibida birga); mahsuloti yoki varianti yo'qolgan yoki
/// tugagan qatorlar tushib qoladi.
List<CartItem> revalidateCart(List<CartItem> cart, List<Product> products) {
  if (products.isEmpty) return cart;
  final byId = {for (final p in products) p.id: p};

  final next = <CartItem>[];
  for (final it in cart) {
    final p = byId[it.productId];
    final option = p == null ? null : productOptions(p).where((o) => o.key == it.optionKey).firstOrNull;
    if (p == null || option == null) continue;
    final max = capFor(next, p.id, option);
    if (max < minQty(option.decimal)) continue;
    next.add(_lineFor(p, option, it.qty, max));
  }
  return _sameLines(next, cart) ? cart : next;
}

/// Saqlangan savatdan faqat to'g'ri qatorlarni oladi (eski versiyadan bo'lishi mumkin).
List<CartItem> sanitizeStoredCart(Object? saved) {
  if (saved is! List) return [];
  final out = <CartItem>[];
  for (final raw in saved) {
    if (raw is! Map) continue;
    final j = Map<String, dynamic>.from(raw);
    if (j['option_key'] is! String || j['product_id'] is! num || j['pool'] is! String) continue;
    final it = CartItem.fromJson(j);
    if (!(it.qty > 0) || !(it.multiplier > 0)) continue;
    out.add(CartItem(
      key: lineKey(it.productId, it.optionKey),
      productId: it.productId,
      variantId: it.variantId,
      unitId: it.unitId,
      optionKey: it.optionKey,
      pool: it.pool,
      multiplier: it.multiplier,
      name: it.name,
      optionLabel: it.optionLabel,
      sku: it.sku,
      image: it.image,
      qty: it.qty,
      maxQty: it.maxQty > 0 ? it.maxQty : kUnlimited,
      unit: it.unit,
      decimal: it.decimal,
      price: it.price,
      currency: it.currency,
      curPrice: it.curPrice,
    ));
  }
  return out;
}

/// `POST /storefront/orders/` oladigan qatorlar: miqdor qatorning o'z birligida.
List<OrderItemPayload> toOrderItems(List<CartItem> cart) => [
      for (final it in cart)
        OrderItemPayload(
          productId: it.productId,
          variantId: (it.variantId ?? 0) != 0 ? it.variantId : null,
          unitId: (it.unitId ?? 0) != 0 ? it.unitId : null,
          qty: it.qty,
        ),
    ];

/// Savatdagi tortiladigan ozuqa kilogrammi ("3.5 kg ozuqa").
double weighedKg(List<CartItem> cart) =>
    (cart.fold<double>(0, (sum, it) => isWeighed(it.unit) ? sum + it.qty : sum) * 10).round() / 10;

/// Katalogdagidan ko'p so'ragan buyurtma qatorlari — xaridor uchun xabar.
/// ERP ham tekshiradi, lekin variantsiz mahsulotda ortiqcha so'rovga oddiy
/// 500 qaytargan, shuning uchun so'rovdan oldin ushlanadi. Bir qoldiqdan
/// oladigan qatorlar (mahsulotning ikki birligi) birga tekshiriladi.
List<String> stockProblems(List<OrderItemPayload> items, List<Product> products) {
  final byId = {for (final p in products) p.id: p};
  final pools = <String, ({Product p, BuyOption option, double used})>{};
  final problems = <String>[];

  for (final item in items) {
    final p = byId[item.productId];
    if (p == null) continue;
    final options = productOptions(p);
    final option = item.variantId != null
        ? options.where((o) => o.variantId == item.variantId).firstOrNull
        : (options.where((o) => o.unitId != null && o.unitId == item.unitId).firstOrNull ??
            options.where((o) => o.unitId == null).firstOrNull ??
            options.firstOrNull);
    if (option == null) {
      problems.add(tr.optionGone(p.name));
      continue;
    }
    final entry = pools[option.pool] ?? (p: p, option: option, used: 0.0);
    pools[option.pool] = (p: entry.p, option: entry.option, used: entry.used + item.qty * option.multiplier);
  }

  for (final e in pools.values) {
    // O'nli yaxlitlash uchun mingdan bir zaxira.
    if (e.used <= e.option.poolStock + 0.001) continue;
    final name = e.option.variantId != null ? '${e.p.name} · ${e.option.label}' : e.p.name;
    final base = e.option.multiplier == 1
        ? e.option
        : (productOptions(e.p).where((o) => o.multiplier == 1).firstOrNull ?? e.option);
    problems.add(e.option.poolStock > 0
        ? tr.overStock(name, '${fmtNumber(e.option.poolStock)} ${base.unit}', '${fmtNumber(e.used)} ${base.unit}')
        : tr.soldOutOf(name));
  }
  return problems;
}
