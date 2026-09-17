class ProductVariant {
  final int id;
  final String name;
  final String sku;
  final double price;
  final double? stock;
  final bool inStock;
  final String currency;
  final double curPrice;

  ProductVariant({
    required this.id, required this.name, required this.sku,
    required this.price, this.stock, required this.inStock,
    this.currency = '', double? curPrice,
  }) : curPrice = curPrice ?? price;

  factory ProductVariant.fromJson(Map<String, dynamic> j) => ProductVariant(
    id: j['id'] ?? 0,
    name: j['name'] ?? '',
    sku: j['sku'] ?? '',
    price: double.tryParse('${j['price'] ?? 0}') ?? 0,
    stock: j['stock'] != null ? double.tryParse('${j['stock']}') : null,
    inStock: j['in_stock'] ?? true,
    currency: j['currency'] ?? '',
    curPrice: j['cur_price'] != null ? double.tryParse('${j['cur_price']}') : null,
  );
}

class ProductUnit {
  final int unitId;
  final String unitName;
  final double price;
  final double multiplier;
  final String currency;   // '' = so'm, 'USD' = dollar
  final double curPrice;   // asl valyutadagi narx (display uchun)

  ProductUnit({required this.unitId, required this.unitName, required this.price, required this.multiplier, this.currency = '', double? curPrice}) : curPrice = curPrice ?? price;

  factory ProductUnit.fromJson(Map<String, dynamic> j) => ProductUnit(
    unitId: j['unit_id'] ?? 0,
    unitName: j['unit_name'] ?? 'dona',
    price: double.tryParse('${j['price'] ?? 0}') ?? 0,
    multiplier: double.tryParse('${j['multiplier'] ?? 1}') ?? 1,
    currency: j['currency'] ?? '',
    curPrice: j['cur_price'] != null ? double.tryParse('${j['cur_price']}') : null,
  );
}

class Product {
  final int id;
  final String name;
  final String? image;
  final int? categoryId;
  final String? categoryName;
  final int? categoryParentId;
  final String? categoryParentName;
  final String? description;
  final String stockType;
  final double stock;
  final bool inStock;
  final bool hasVariants;
  final List<ProductVariant> variants;
  final List<ProductUnit> units;

  Product({
    required this.id, required this.name, this.image,
    this.categoryId, this.categoryName, this.categoryParentId, this.categoryParentName,
    this.description,
    required this.stockType, required this.stock,
    required this.inStock, required this.hasVariants,
    required this.variants, required this.units,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'],
    name: j['name'] ?? '',
    image: j['image'],
    categoryId: j['category_id'],
    categoryName: j['category_name'],
    categoryParentId: j['category_parent_id'],
    categoryParentName: j['category_parent_name'],
    description: j['description'],
    stockType: j['stock_type'] ?? 'untracked',
    stock: double.tryParse('${j['stock'] ?? 0}') ?? 0,
    inStock: j['in_stock'] ?? true,
    hasVariants: j['has_variants'] ?? false,
    variants: (j['variants'] as List? ?? []).map((v) => ProductVariant.fromJson(v)).toList(),
    units: (j['units'] as List? ?? []).map((u) => ProductUnit.fromJson(u)).toList(),
  );
}

class Category {
  final int id;
  final String name;
  final int? parentId; // null bo'lsa — yuqori (top) kategoriya
  Category({required this.id, required this.name, this.parentId});
}

// Og'irlik/o'lchov birlikmi (kg, gramm) — kasr miqdor bilan sotiladi
bool isWeightUnit(String? name) {
  final n = (name ?? '').trim().toLowerCase();
  return RegExp(r'kilogram|kilogramm|gramm|\bkg\b|\bg\b').hasMatch(n);
}

// Kasr miqdor qabul qiladigan birlikmi — og'irlik (kg), maydon (m²),
// hajm (m³), uzunlik (metr), suyuqlik (litr). "dona" va qadoq birliklari
// faqat butun bo'ladi.
bool allowsFraction(String? name) {
  final n = (name ?? '').trim().toLowerCase();
  return RegExp(
    r'kilogram|kilogramm|gramm|\bkg\b|\bg\b'        // og'irlik
    r'|kvadrat|kub|\bm2\b|\bm3\b|m²|m³'              // maydon/hajm
    r'|metr|santimetr|\bsm\b|millimetr|\bmm\b'       // uzunlik
    r'|litr|millilitr|\bml\b',                        // suyuqlik
  ).hasMatch(n);
}

// O'zbekiston telefon raqamini normallashtirish — ko'p mijoz +998 ni yozmaydi,
// tizim o'zi qo'shib qo'yadi. '+' bilan boshlansa tegilmaydi.
String normalizeUzPhone(String raw) {
  final v = raw.trim();
  if (v.isEmpty) return '';
  if (v.startsWith('+')) return v;
  final digits = v.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('998')) return '+$digits';
  if (digits.length == 9) return '+998$digits';
  return v;
}

// Xatoni foydalanuvchiga sodda qilib beradi (texnik tafsilotlarsiz)
String friendlyError(Object e) {
  final s = e.toString().toLowerCase();
  if (s.contains('socketexception') ||
      s.contains('failed host lookup') ||
      s.contains('network is unreachable') ||
      s.contains('connection refused') ||
      s.contains('connection closed') ||
      s.contains('connection reset') ||
      s.contains('clientexception') ||
      s.contains('timeoutexception') ||
      s.contains('handshake')) {
    return 'Internet aloqasi yo\'q. Ulanishni tekshirib, qayta urinib ko\'ring.';
  }
  return 'Nimadir xato ketdi. Qayta urinib ko\'ring.';
}

// Miqdorni ko'rsatish: butun bo'lsa "2", kasr bo'lsa "0.5"
String fmtQty(num n) {
  final d = n.toDouble();
  if (d == d.roundToDouble()) return d.toInt().toString();
  return d.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

class CartItem {
  final String key;
  final int productId;
  final int? unitId;
  final int? variantId;
  final String unitName;
  final String name;
  final String variantName;
  final String? image;
  final double price;
  final String currency;
  final double curPrice;
  double qty;            // kg tovarda kasr bo'lishi mumkin
  final double maxQty;
  final bool weight;     // og'irlik (kg) tovar

  CartItem({
    required this.key, required this.productId,
    this.unitId, this.variantId,
    required this.unitName, required this.name,
    this.variantName = '', this.image,
    required this.price, required this.qty, required this.maxQty,
    this.currency = '', double? curPrice,
    this.weight = false,
  }) : curPrice = curPrice ?? price;
}

class StoreInfo {
  final String store;
  StoreInfo({required this.store});
  factory StoreInfo.fromJson(Map<String, dynamic> j) => StoreInfo(store: j['store'] ?? "Do'kon");
}

class Customer {
  final String name;
  final String code;
  final String? phone;
  final double debt;
  final double credit;

  Customer({required this.name, required this.code, this.phone, required this.debt, required this.credit});

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
    name: j['name'] ?? '',
    code: j['customer_code'] ?? j['code'] ?? '',
    phone: j['phone'],
    debt: double.tryParse('${j['debt'] ?? 0}') ?? 0,
    credit: double.tryParse('${j['credit'] ?? 0}') ?? 0,
  );
}

class SaleItem {
  final String productName;
  final double quantity;
  final String unitName;
  final double price;

  SaleItem({required this.productName, required this.quantity, required this.unitName, required this.price});

  factory SaleItem.fromJson(Map<String, dynamic> j) => SaleItem(
    productName: j['product_name'] ?? j['name'] ?? '',
    quantity: double.tryParse('${j['quantity'] ?? j['qty'] ?? 0}') ?? 0,
    unitName: j['unit_name'] ?? j['unit'] ?? 'dona',
    price: double.tryParse('${j['price'] ?? 0}') ?? 0,
  );
}

class Sale {
  final int id;
  final String receiptNumber;
  final String date;
  final double total;
  final double paid;
  final double debt;
  final String paymentMethod;
  final String status;
  final List<Map<String, dynamic>> paymentBreakdown;
  final List<SaleItem> items;

  Sale({
    required this.id, required this.receiptNumber, required this.date,
    required this.total, required this.paid, required this.debt,
    required this.paymentMethod, required this.status,
    required this.paymentBreakdown, required this.items,
  });

  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
    id: j['id'] ?? 0,
    receiptNumber: j['receipt_number'] ?? '',
    date: j['date'] ?? j['created_at'] ?? '',
    total: double.tryParse('${j['total'] ?? 0}') ?? 0,
    paid: double.tryParse('${j['paid'] ?? 0}') ?? 0,
    debt: double.tryParse('${j['debt'] ?? 0}') ?? 0,
    paymentMethod: j['payment_method'] ?? '',
    status: j['status'] ?? '',
    paymentBreakdown: (j['payment_breakdown'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    items: (j['items'] as List? ?? []).map((i) => SaleItem.fromJson(i)).toList(),
  );
}

// To'lov usuli yorlig'i (o'zbekcha)
String paymentMethodLabel(String m) {
  switch (m) {
    case 'cash': return 'Naqd';
    case 'card': return 'Karta';
    case 'transfer': return "O'tkazma";
    case 'credit': return 'Nasiya';
    case 'mixed': return 'Aralash';
    case 'click': return 'Click';
    case 'payme': return 'Payme';
    case 'uzum': return 'Uzum';
    case 'humo': return 'Humo';
    case 'uzcard': return 'UzCard';
    case 'installment': return "Bo'lib to'lash";
    case 'exchange_credit': return 'Ayirboshlash';
    default: return m.isEmpty ? '—' : m;
  }
}

class OnlineOrder {
  final int id;
  final String orderNo;
  final String status;
  final String? createdAt;
  final String? note;
  final double? totalAmount;

  OnlineOrder({required this.id, required this.orderNo, required this.status, this.createdAt, this.note, this.totalAmount});

  factory OnlineOrder.fromJson(Map<String, dynamic> j) => OnlineOrder(
    id: j['id'] ?? 0,
    orderNo: j['order_no'] ?? j['id']?.toString() ?? '',
    status: j['status'] ?? 'pending',
    createdAt: j['created_at'],
    note: j['note'],
    totalAmount: double.tryParse('${j['total_amount'] ?? j['total'] ?? 0}'),
  );
}

class Payment {
  final double amount;
  final String date;
  final String type;

  Payment({required this.amount, required this.date, required this.type});

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
    amount: double.tryParse('${j['amount'] ?? 0}') ?? 0,
    date: j['date'] ?? j['created_at'] ?? '',
    type: j['payment_type'] ?? j['type'] ?? j['note'] ?? 'naqd',
  );
}

class CustomerData {
  final Customer customer;
  final List<Sale> sales;
  final List<OnlineOrder> orders;
  final List<Payment> payments;
  final double totalSpent;

  CustomerData({required this.customer, required this.sales, required this.orders, required this.payments, required this.totalSpent});

  factory CustomerData.fromJson(Map<String, dynamic> j) {
    final sales = (j['sales'] as List? ?? []).map((s) => Sale.fromJson(s)).toList();
    final totalSpent = sales.fold<double>(0, (s, sale) => s + sale.total);
    return CustomerData(
      customer: Customer.fromJson(j['customer'] ?? {}),
      sales: sales,
      orders: (j['online_orders'] as List? ?? []).map((o) => OnlineOrder.fromJson(o)).toList(),
      payments: (j['payments'] as List? ?? []).map((p) => Payment.fromJson(p)).toList(),
      totalSpent: double.tryParse('${j['total_spent'] ?? 0}') ?? totalSpent,
    );
  }
}
