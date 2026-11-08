import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../models/models.dart';
import '../services/cart_lines.dart';
import '../services/options.dart';
import '../services/storage.dart';

/// Savat holati. Mantiq — `cart_lines.dart` reduserlarida; bu yer natijani
/// saqlaydi va ekranlarga xabar beradi. Har amaldan keyin savat katalog
/// bilan qayta tekshiriladi (saytdagi `useCart`).
class CartController extends ChangeNotifier {
  CartController({required this.products, this.persist = true});

  /// Joriy katalog — narx va qoldiq cheklovlari uchun.
  final List<Product> Function() products;
  /// Testlarda false — qurilma xotirasiga yozilmaydi.
  final bool persist;

  List<CartItem> _items = const [];
  bool _ready = false;

  List<CartItem> get items => _items;
  bool get ready => _ready;
  /// Alohida qatorlar — sarlavha belgisi uchun: 2 kg ozuqa va 10 pauch ikki xil.
  int get count => _items.length;

  Future<void> load() async {
    if (persist) _items = await Storage.loadCart();
    _ready = true;
    _items = revalidateCart(_items, products());
    notifyListeners();
  }

  void _apply(List<CartItem> next) {
    final checked = revalidateCart(next, products());
    if (identical(checked, _items)) return;
    _items = checked;
    notifyListeners();
    if (persist) Storage.saveCart(checked);
  }

  CartItem? line(String key) => _items.where((x) => x.key == key).firstOrNull;

  void add(Product p, BuyOption option, double qty) => _apply(addLine(_items, p, option, qty));
  void setQty(String key, double qty) => _apply(setLineQty(_items, key, qty));
  void remove(String key) => _apply(removeLine(_items, key));
  void clear() {
    if (_items.isEmpty) return;
    _items = const [];
    notifyListeners();
    if (persist) Storage.saveCart(const []);
  }

  /// Yangi katalog kelganda saqlangan qatorlarni yangilaydi (kirish yoki ERP o'zgarishi).
  void syncProducts() => _apply(_items);
}
