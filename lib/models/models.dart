// dukonline.uz Storefront API turlari — Zootopia do'konining jonli
// javoblaridan olingan (saytdagi `src/lib/storefront/types.ts`).
//
// API'da mahsulot, kategoriya yoki sahifalash endpointi yo'q: butun katalog
// bitta javobda keladi, qolgan hamma narsa undan hisoblanadi.

double _num(Object? v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

double? _numOrNull(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _intOrNull(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String _str(Object? v) => v is String ? v : (v == null ? '' : '$v');

/// Mahsulot sotiladigan bir usul ("Kilogram", "Dona", "Quti"). `multiplier` —
/// shu birlikdan bittasi asosiy birlikdan nechtasini oladi (24 talik quti).
class ProductUnit {
  /// Mahsulotning o'z asosiy birligida null — buyurtmada yuborilmaydi.
  final int? unitId;
  final String unitName;
  final double multiplier;
  final double price;
  final double? originalPrice;
  /// Bo'sh — do'konning asosiy valyutasi (so'm).
  final String currency;
  /// Mahsulotning o'z `currency`sidagi narx.
  final double curPrice;
  final double? curOriginalPrice;
  final bool? isBase;

  const ProductUnit({
    required this.unitId,
    required this.unitName,
    required this.multiplier,
    required this.price,
    this.originalPrice,
    this.currency = '',
    required this.curPrice,
    this.curOriginalPrice,
    this.isBase,
  });

  factory ProductUnit.fromJson(Map<String, dynamic> j) => ProductUnit(
        unitId: _intOrNull(j['unit_id']),
        unitName: _str(j['unit_name']),
        multiplier: _num(j['multiplier'], 1),
        price: _num(j['price']),
        originalPrice: _numOrNull(j['original_price']),
        currency: _str(j['currency']),
        curPrice: _numOrNull(j['cur_price']) ?? _num(j['price']),
        curOriginalPrice: _numOrNull(j['cur_original_price']),
        isBase: j['is_base'] is bool ? j['is_base'] as bool : null,
      );
}

/// Mahsulotning bir ta'mi, o'lchami yoki rangi (mol go'shti / tovuq, 400 g / 2 kg).
class ProductVariant {
  final int id;
  final String name;
  final String sku;
  final String? image;
  final double price;
  final double? originalPrice;
  final String currency;
  final double curPrice;
  final double? curOriginalPrice;
  /// Asosiy birlikda; qoldiq hisoblanmasa null.
  final double? stock;
  final bool inStock;

  const ProductVariant({
    required this.id,
    required this.name,
    this.sku = '',
    this.image,
    required this.price,
    this.originalPrice,
    this.currency = '',
    required this.curPrice,
    this.curOriginalPrice,
    this.stock,
    this.inStock = true,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> j) => ProductVariant(
        id: _intOrNull(j['id']) ?? 0,
        name: _str(j['name']),
        sku: _str(j['sku']),
        image: j['image'] is String ? j['image'] as String : null,
        price: _num(j['price']),
        originalPrice: _numOrNull(j['original_price']),
        currency: _str(j['currency']),
        curPrice: _numOrNull(j['cur_price']) ?? _num(j['price']),
        curOriginalPrice: _numOrNull(j['cur_original_price']),
        stock: _numOrNull(j['stock']),
        inStock: j['in_stock'] != false,
      );

  ProductVariant withImage(String? image) => ProductVariant(
        id: id, name: name, sku: sku, image: image, price: price, originalPrice: originalPrice,
        currency: currency, curPrice: curPrice, curOriginalPrice: curOriginalPrice, stock: stock, inStock: inStock,
      );
}

class Product {
  final int id;
  final String name;
  final String sku;
  final String description;
  final int? categoryId;
  final String? categoryName;
  final int? categoryParentId;
  final String? categoryParentName;
  /// Asosiy rasm.
  final String image;
  /// Butun galereya, asosiy rasm birinchi.
  final List<String> images;
  /// `tracked` — qoldiq kamayadi; boshqalari doim sotiladi.
  final String stockType;
  /// Asosiy birlikda (`multiplier: 1` bo'lgan birlik).
  final double stock;
  final bool inStock;
  final bool hasVariants;
  final List<ProductVariant> variants;
  final List<ProductUnit> units;
  final double discountPercent;
  /// ERP'da kiritilgan erkin xususiyatlar; hozircha kelmaydi.
  final Map<String, String> attributes;

  const Product({
    required this.id,
    required this.name,
    this.sku = '',
    this.description = '',
    this.categoryId,
    this.categoryName,
    this.categoryParentId,
    this.categoryParentName,
    this.image = '',
    this.images = const [],
    this.stockType = 'tracked',
    this.stock = 0,
    this.inStock = true,
    this.hasVariants = false,
    this.variants = const [],
    this.units = const [],
    this.discountPercent = 0,
    this.attributes = const {},
  });

  factory Product.fromJson(Map<String, dynamic> j) {
    final attrs = <String, String>{};
    final rawAttrs = j['attributes'];
    if (rawAttrs is Map) {
      rawAttrs.forEach((k, v) {
        final value = v == null ? '' : '$v'.trim();
        if (value.isNotEmpty) attrs['$k'] = value;
      });
    }
    return Product(
      id: _intOrNull(j['id']) ?? 0,
      name: _str(j['name']),
      sku: _str(j['sku']),
      description: _str(j['description']),
      categoryId: _intOrNull(j['category_id']),
      categoryName: j['category_name'] as String?,
      categoryParentId: _intOrNull(j['category_parent_id']),
      categoryParentName: j['category_parent_name'] as String?,
      image: _str(j['image']),
      images: (j['images'] as List? ?? const []).whereType<String>().toList(),
      stockType: j['stock_type'] is String ? j['stock_type'] as String : 'untracked',
      stock: _num(j['stock']),
      inStock: j['in_stock'] != false,
      hasVariants: j['has_variants'] == true,
      variants: (j['variants'] as List? ?? const [])
          .whereType<Map>()
          .map((v) => ProductVariant.fromJson(Map<String, dynamic>.from(v)))
          .toList(),
      units: (j['units'] as List? ?? const [])
          .whereType<Map>()
          .map((u) => ProductUnit.fromJson(Map<String, dynamic>.from(u)))
          .toList(),
      discountPercent: _num(j['discount_percent']),
      attributes: attrs,
    );
  }

  /// Kategoriya maydonlari qayta yoziladi (`relabelCategories`, `normalizeCategories`).
  Product withCategory({
    required int? categoryId,
    required String? categoryName,
    required int? categoryParentId,
    required String? categoryParentName,
  }) =>
      Product(
        id: id, name: name, sku: sku, description: description,
        categoryId: categoryId, categoryName: categoryName,
        categoryParentId: categoryParentId, categoryParentName: categoryParentName,
        image: image, images: images, stockType: stockType, stock: stock, inStock: inStock,
        hasVariants: hasVariants, variants: variants, units: units,
        discountPercent: discountPercent, attributes: attributes,
      );

  Product withMedia({required String name, required String image, required List<String> images, required List<ProductVariant> variants}) => Product(
        id: id, name: name, sku: sku, description: description,
        categoryId: categoryId, categoryName: categoryName,
        categoryParentId: categoryParentId, categoryParentName: categoryParentName,
        image: image, images: images, stockType: stockType, stock: stock, inStock: inStock,
        hasVariants: hasVariants, variants: variants, units: units,
        discountPercent: discountPercent, attributes: attributes,
      );
}

class CatalogResponse {
  final List<Product> results;
  final bool showStock;
  final bool showImages;
  /// Kategoriya id → rasm.
  final Map<int, String> categoryImages;

  const CatalogResponse({required this.results, this.showStock = true, this.showImages = true, this.categoryImages = const {}});

  factory CatalogResponse.fromJson(Map<String, dynamic> j) {
    final images = <int, String>{};
    for (final c in (j['category_images'] as List? ?? const []).whereType<Map>()) {
      final id = _intOrNull(c['id']);
      final image = c['image'];
      if (id != null && image is String && image.isNotEmpty) images[id] = image;
    }
    return CatalogResponse(
      results: (j['results'] as List? ?? const [])
          .whereType<Map>()
          .map((p) => Product.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      showStock: j['show_stock'] != false,
      showImages: j['show_images'] != false,
      categoryImages: images,
    );
  }
}

/// ERP'dagi banner — o'z matni bilan rasm.
class StoreBanner {
  final String image;
  final String title;
  /// 'left' | 'right'.
  final String align;
  const StoreBanner({required this.image, this.title = '', this.align = 'left'});
}

class StoreInfo {
  /// "Zootopia".
  final String organization;
  /// "Крытый магазин" — qoldiq olinadigan filial.
  final String store;
  final String currency;
  final List<StoreBanner> banners;
  const StoreInfo({required this.organization, required this.store, this.currency = '', this.banners = const []});

  factory StoreInfo.fromJson(Map<String, dynamic> j, String Function(String) resolve) => StoreInfo(
        organization: _str(j['organization']),
        store: _str(j['store']),
        currency: _str(j['currency']),
        banners: normalizeBanners(j['banners'] as List? ?? const [], resolve),
      );
}

final _imageExt = RegExp(r'\.(avif|gif|jpe?g|png|webp)(\?|$)', caseSensitive: false);

/// ERP bannerlari oddiy URL yoki rasmi turli kalitlardagi obyekt bo'lib keladi.
List<StoreBanner> normalizeBanners(List raw, String Function(String) resolve) {
  final out = <StoreBanner>[];
  for (final banner in raw) {
    if (banner is String) {
      if (banner.trim().isNotEmpty) out.add(StoreBanner(image: resolve(banner)));
      continue;
    }
    if (banner is! Map) continue;
    String? image;
    for (final key in ['image_url', 'image', 'url', 'photo', 'file']) {
      final v = banner[key];
      if (v is String && v.trim().isNotEmpty) {
        image = v;
        break;
      }
    }
    image ??= banner.values.whereType<String>().where(_imageExt.hasMatch).firstOrNull;
    if (image == null) continue;
    out.add(StoreBanner(
      image: resolve(image),
      title: banner['title'] is String ? banner['title'] as String : '',
      align: banner['align'] == 'right' ? 'right' : 'left',
    ));
  }
  return out;
}

/// Mahsulot qatorlaridan tuzilgan kategoriya; `parentId` null — yuqori daraja.
class Category {
  final int id;
  final String name;
  final int? parentId;
  const Category({required this.id, required this.name, this.parentId});
}

class Customer {
  /// Serverdan kelgan yozuv — keyingi kirishgacha qurilmada shunday saqlanadi.
  final Map<String, dynamic> raw;
  const Customer(this.raw);

  String get customerCode => _str(raw['customer_code'] ?? raw['code']);
  String get code => _str(raw['code']);
  String get name => _str(raw['name']);
  String get customerName => _str(raw['customer_name']);
  String get phone => _str(raw['phone']);
  String get phoneNumber => _str(raw['phone_number']);
  double get debt => _num(raw['debt']);
  double get credit => _num(raw['credit']);
  Map<String, double> get currencyDebts => _balances(raw['currency_debts']);
  Map<String, double> get currencyCredits => _balances(raw['currency_advances']);

  /// Ism, bo'lmasa kod.
  String get displayName => name.isNotEmpty ? name : (customerName.isNotEmpty ? customerName : customerCode);

  static Map<String, double> _balances(Object? v) {
    if (v is! Map) return const {};
    return {for (final e in v.entries) '${e.key}': _num(e.value)};
  }
}

class CustomerSaleItem {
  final String name;
  final double qty;
  final String unit;
  final double price;
  const CustomerSaleItem({required this.name, required this.qty, required this.unit, required this.price});

  factory CustomerSaleItem.fromJson(Map<String, dynamic> j) => CustomerSaleItem(
        name: _str(j['name'] ?? j['product_name']),
        qty: _num(j['qty'] ?? j['quantity']),
        unit: _str(j['unit'] ?? j['unit_name']),
        price: _num(j['price']),
      );
}

class PaymentPart {
  final String method;
  final double amount;
  const PaymentPart(this.method, this.amount);
}

class CustomerSale {
  final String receiptNumber;
  final String createdAt;
  final double total;
  final double? paid;
  final double? debt;
  final String debtCurrency;
  final double? debtCurrencyAmount;
  final double? debtRate;
  final List<PaymentPart> paymentBreakdown;
  final String paymentMethod;
  final List<CustomerSaleItem> items;

  const CustomerSale({
    required this.receiptNumber,
    required this.createdAt,
    required this.total,
    this.paid,
    this.debt,
    this.debtCurrency = '',
    this.debtCurrencyAmount,
    this.debtRate,
    this.paymentBreakdown = const [],
    this.paymentMethod = '',
    this.items = const [],
  });

  factory CustomerSale.fromJson(Map<String, dynamic> j) => CustomerSale(
        receiptNumber: _str(j['receipt_number']),
        createdAt: _str(j['created_at'] ?? j['date']),
        total: _num(j['total']),
        paid: _numOrNull(j['paid']),
        debt: _numOrNull(j['debt']),
        debtCurrency: _str(j['debt_currency']),
        debtCurrencyAmount: _numOrNull(j['debt_currency_amount']),
        debtRate: _numOrNull(j['debt_rate']),
        paymentBreakdown: (j['payment_breakdown'] as List? ?? const [])
            .whereType<Map>()
            .map((p) => PaymentPart(_str(p['method']), _num(p['amount'])))
            .toList(),
        paymentMethod: _str(j['payment_method']),
        items: (j['items'] as List? ?? const [])
            .whereType<Map>()
            .map((i) => CustomerSaleItem.fromJson(Map<String, dynamic>.from(i)))
            .toList(),
      );
}

class CustomerOrder {
  final String orderNo;
  final String createdAt;
  final double total;
  final String status;
  const CustomerOrder({required this.orderNo, required this.createdAt, required this.total, required this.status});

  factory CustomerOrder.fromJson(Map<String, dynamic> j) => CustomerOrder(
        orderNo: _str(j['order_no']),
        createdAt: _str(j['created_at']),
        total: _num(j['total'] ?? j['total_amount']),
        status: _str(j['status']),
      );
}

class CustomerPayment {
  final double amount;
  final String currency;
  final String createdAt;
  final String note;
  const CustomerPayment({required this.amount, this.currency = '', required this.createdAt, this.note = ''});

  factory CustomerPayment.fromJson(Map<String, dynamic> j) => CustomerPayment(
        amount: _num(j['amount']),
        currency: _str(j['currency']),
        createdAt: _str(j['created_at'] ?? j['date']),
        note: _str(j['note']),
      );
}

class CustomerAccount {
  final Customer customer;
  final List<CustomerSale> sales;
  final List<CustomerOrder> onlineOrders;
  final List<CustomerPayment> payments;
  const CustomerAccount({required this.customer, this.sales = const [], this.onlineOrders = const [], this.payments = const []});

  factory CustomerAccount.fromJson(Map<String, dynamic> j) => CustomerAccount(
        customer: Customer(Map<String, dynamic>.from(j['customer'] as Map? ?? const {})),
        sales: (j['sales'] as List? ?? const [])
            .whereType<Map>()
            .map((s) => CustomerSale.fromJson(Map<String, dynamic>.from(s)))
            .toList(),
        onlineOrders: (j['online_orders'] as List? ?? const [])
            .whereType<Map>()
            .map((o) => CustomerOrder.fromJson(Map<String, dynamic>.from(o)))
            .toList(),
        payments: (j['payments'] as List? ?? const [])
            .whereType<Map>()
            .map((p) => CustomerPayment.fromJson(Map<String, dynamic>.from(p)))
            .toList(),
      );
}

/// Savatning bir qatori: mahsulotning bir variantidan (ta'm/o'lcham yoki
/// birlik) ma'lum miqdor.
///
///   key: `${productId}_${optionKey}`   masalan `8551_base`, `9160_u12`, `9201_v501`
class CartItem {
  final String key;
  final int productId;
  final int? variantId;
  /// Faqat asosiy bo'lmagan birlik uchun (pauchlar qutisi).
  final int? unitId;
  /// Mahsulot sahifasidagi variantga qaytaradi (`base`, `u12`, `v501`).
  final String optionKey;
  /// Qaysi qoldiqdan oladi; bir pool'dagi qatorlar qoldiqni bo'lishadi.
  final String pool;
  /// Bu birlikdan bittasi asosiy birlikdan nechtasini oladi.
  final double multiplier;

  final String name;
  /// Ta'm/o'lcham yoki birlik nomi; mahsulotda bitta variant bo'lsa bo'sh.
  final String optionLabel;
  final String sku;
  final String image;

  /// Qator birligida.
  final double qty;
  /// Qoldiqdan kelgan chegara; qoldiq hisoblanmasa `kUnlimited`.
  final double maxQty;
  /// "kg", "dona", "quti".
  final String unit;
  /// Kasr (1.5 kg) buyurtma qilish mumkinmi.
  final bool decimal;

  /// So'mda.
  final double price;
  /// Variantning o'z valyutasi; bo'sh — so'm.
  final String currency;
  /// `currency`dagi narx.
  final double curPrice;

  const CartItem({
    required this.key,
    required this.productId,
    this.variantId,
    this.unitId,
    required this.optionKey,
    required this.pool,
    required this.multiplier,
    required this.name,
    this.optionLabel = '',
    this.sku = '',
    this.image = '',
    required this.qty,
    required this.maxQty,
    required this.unit,
    required this.decimal,
    required this.price,
    this.currency = '',
    required this.curPrice,
  });

  CartItem copyWith({double? qty, double? maxQty}) => CartItem(
        key: key, productId: productId, variantId: variantId, unitId: unitId, optionKey: optionKey,
        pool: pool, multiplier: multiplier, name: name, optionLabel: optionLabel, sku: sku, image: image,
        qty: qty ?? this.qty, maxQty: maxQty ?? this.maxQty, unit: unit, decimal: decimal,
        price: price, currency: currency, curPrice: curPrice,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'product_id': productId,
        'variant_id': variantId,
        'unit_id': unitId,
        'option_key': optionKey,
        'pool': pool,
        'multiplier': multiplier,
        'name': name,
        'option_label': optionLabel,
        'sku': sku,
        'image': image,
        'qty': qty,
        'max_qty': maxQty,
        'unit': unit,
        'decimal': decimal,
        'price': price,
        'currency': currency,
        'cur_price': curPrice,
      };

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        key: _str(j['key']),
        productId: _intOrNull(j['product_id']) ?? 0,
        variantId: _intOrNull(j['variant_id']),
        unitId: _intOrNull(j['unit_id']),
        optionKey: _str(j['option_key']),
        pool: _str(j['pool']),
        multiplier: _num(j['multiplier'], 1),
        name: _str(j['name']),
        optionLabel: _str(j['option_label']),
        sku: _str(j['sku']),
        image: _str(j['image']),
        qty: _num(j['qty']),
        maxQty: _num(j['max_qty']),
        unit: _str(j['unit']),
        decimal: j['decimal'] == true,
        price: _num(j['price']),
        currency: _str(j['currency']),
        curPrice: _num(j['cur_price']),
      );
}

/// `POST /storefront/orders/` qatori.
class OrderItemPayload {
  final int productId;
  final int? variantId;
  /// Faqat asosiy bo'lmagan birlik uchun; asosiy birlik — sukut.
  final int? unitId;
  /// Tanlangan birlikda (yoki `unitId` bo'lmasa asosiy birlikda).
  final double qty;
  const OrderItemPayload({required this.productId, this.variantId, this.unitId, required this.qty});

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        if (variantId != null && variantId != 0) 'variant_id': variantId,
        if (unitId != null && unitId != 0) 'unit_id': unitId,
        'qty': qty,
      };
}
