import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../services/push_service.dart';
import '../config/theme.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import 'cart_sheet.dart';
import 'checkout_screen.dart';
import 'customer_portal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Product> _products = [];
  List<Category> _cats = [];
  StoreInfo? _info;
  bool _loading = true;
  bool _firstLoad = true;
  bool _splashVisible = true;
  String _error = '';

  int? _selTop;   // tanlangan yuqori (top) kategoriya
  int? _selSub;   // tanlangan sub-kategoriya (null = top ichidagi barchasi)
  String _search = '';
  bool _searchOpen = false;
  int _navActive = 0;

  List<CartItem> _cart = [];
  Customer? _customer;
  Set<int> _favs = {};

  final _searchCtrl = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() { super.initState(); _init(); }

  @override
  void dispose() { super.dispose(); }

  void _triggerOrb(Offset from) {
    final overlay = Overlay.of(context);
    final size = MediaQuery.of(context).size;
    final bottom = MediaQuery.of(context).padding.bottom;
    // Savatcha = 5 tabdan 3-si (index 2) → to'liq kenglikdagi panelda ~50%
    final to = Offset(size.width * 0.5, size.height - bottom - 46);

    final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    final posAnim = Tween<Offset>(begin: from, end: to)
        .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
    final fadeAnim = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: ctrl, curve: const Interval(0.65, 1.0)));
    final scaleAnim = Tween<double>(begin: 1.0, end: 0.25)
        .animate(CurvedAnimation(parent: ctrl, curve: const Interval(0.65, 1.0)));

    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => Positioned(
        left: posAnim.value.dx - 20,
        top: posAnim.value.dy - 20,
        child: Opacity(
          opacity: fadeAnim.value,
          child: Transform.scale(
            scale: scaleAnim.value,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: kAccent,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: kAccent.withAlpha(120), blurRadius: 16, spreadRadius: 2)],
              ),
              child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    ));

    overlay.insert(entry);
    ctrl.forward().then((_) { entry.remove(); ctrl.dispose(); });
    HapticFeedback.lightImpact();
  }

  Future<void> _init() async {
    final saved = await AuthStorage.load();
    if (saved != null && mounted) setState(() => _customer = saved);
    if (saved != null) StorePushService.instance.setCustomer(saved.code);
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList('fav_ids') ?? [];
    if (mounted) setState(() => _favs = favList.map(int.parse).toSet());
    await Future.wait([
      _load(),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);
    if (mounted) _hideSplash();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final info = await ApiService.getInfo();
      final products = await ApiService.getProducts(customerCode: _customer?.code);
      // Kategoriya daraxti: leaf (o'z parent'i bilan) + parent kategoriyalar
      final map = <int, Category>{};
      for (final p in products) {
        if (p.categoryId != null && p.categoryName != null) {
          map[p.categoryId!] = Category(id: p.categoryId!, name: p.categoryName!, parentId: p.categoryParentId);
        }
        if (p.categoryParentId != null && p.categoryParentName != null) {
          map.putIfAbsent(p.categoryParentId!, () => Category(id: p.categoryParentId!, name: p.categoryParentName!));
        }
      }
      if (mounted) setState(() {
        _info = info; _products = products;
        _cats = map.values.toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = friendlyError(e); });
    }
  }

  void _hideSplash() {
    // Fade out after data is ready
    setState(() => _splashVisible = false);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _firstLoad = false);
    });
  }

  // Yuqori (top) kategoriyalar — parent'i yo'q bo'lganlar
  List<Category> get _topCats => _cats.where((c) => c.parentId == null).toList();
  // Tanlangan top ichidagi sub-kategoriyalar
  List<Category> get _subCats => _selTop == null ? [] : _cats.where((c) => c.parentId == _selTop).toList();


  List<Product> get _filtered {
    var list = _products;
    if (_selSub != null) {
      list = list.where((p) => p.categoryId == _selSub).toList();
    } else if (_selTop != null) {
      list = list.where((p) => p.categoryId == _selTop || p.categoryParentId == _selTop).toList();
    }
    if (_search.isNotEmpty) list = list.where((p) => p.name.toLowerCase().contains(_search.toLowerCase())).toList();
    return list;
  }

  int get _cartCount => _cart.length;

  // ── Sevimlilar ──────────────────────────────────────────────
  List<Product> get _favProducts => _products.where((p) => _favs.contains(p.id)).toList();
  List<Product> get _gridItems => _navActive == 3 ? _favProducts : _filtered;
  Future<void> _toggleFav(int id) async {
    setState(() { if (!_favs.remove(id)) _favs.add(id); });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('fav_ids', _favs.map((e) => e.toString()).toList());
  }

  void _addToCart(Product p, ProductUnit unit, [Offset? fromPos, double addQty = 1]) {
    final key = '${p.id}_${unit.unitId}';
    final mult = unit.multiplier > 0 ? unit.multiplier : 1;
    final weight = allowsFraction(unit.unitName);
    // kg tovarda qoldiq kasr bo'lishi mumkin — floor qilmaymiz
    final maxQty = p.stockType == 'tracked'
        ? (weight ? p.stock / mult : (p.stock / mult).floorToDouble())
        : 9999.0;
    if (maxQty <= 0) return;
    setState(() {
      final idx = _cart.indexWhere((c) => c.key == key);
      if (idx >= 0) {
        if (_cart[idx].qty < maxQty) _cart[idx].qty = (_cart[idx].qty + addQty).clamp(0.0, maxQty);
      } else {
        _cart.add(CartItem(key: key, productId: p.id, unitId: unit.unitId,
          unitName: unit.unitName, name: p.name, image: p.image,
          price: unit.price, currency: unit.currency, curPrice: unit.curPrice, qty: addQty.clamp(0.0, maxQty), maxQty: maxQty, weight: weight));
      }
    });
    if (fromPos != null) _triggerOrb(fromPos);
  }

  void _addVariantToCart(Product p, ProductVariant variant, double qty) {
    final key = '${p.id}_v${variant.id}';
    final maxQty = variant.stock?.floorToDouble() ?? 9999.0;
    if (maxQty <= 0) return;
    setState(() {
      final idx = _cart.indexWhere((c) => c.key == key);
      if (idx >= 0) {
        _cart[idx].qty = (_cart[idx].qty + qty).clamp(1.0, maxQty);
      } else {
        _cart.add(CartItem(
          key: key, productId: p.id, variantId: variant.id,
          unitName: 'dona', name: p.name, variantName: variant.name,
          image: p.image, price: variant.price, currency: variant.currency, curPrice: variant.curPrice, qty: qty, maxQty: maxQty,
        ));
      }
    });
  }

  void _setQty(String key, double qty) => setState(() {
    if (qty <= 0) { _cart.removeWhere((c) => c.key == key); return; }
    final idx = _cart.indexWhere((c) => c.key == key);
    if (idx >= 0) _cart[idx].qty = qty.clamp(0.0, _cart[idx].maxQty);
  });

  void _remove(String key) => setState(() => _cart.removeWhere((c) => c.key == key));

  void _openCart() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => CartSheet(
          items: _cart,
          setQty: (key, qty) { _setQty(key, qty); setSheet(() {}); },
          remove: (key) { _remove(key); setSheet(() {}); },
          onCheckout: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => CheckoutScreen(cart: _cart, customer: _customer, onSuccess: (order) {
              setState(() => _cart.clear());
            }),
          )),
        ),
      ),
    );
  }

  void _openDetail(Product p) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ProductDetailScreen(
        product: p, cart: _cart,
        onAdd: _addToCart,
        onAddVariant: _addVariantToCart,
      ),
    ));
  }

  void _openCategoryDrawer() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryDrawer(
        allCats: _cats, selTop: _selTop, selSub: _selSub,
        onSelect: (top, sub) { setState(() { _selTop = top; _selSub = sub; _navActive = 0; }); },
      ),
    );
  }

  void _onNavTap(int idx) {
    if (idx == 0) {
      setState(() { _navActive = 0; _selTop = null; _selSub = null; _search = ''; _searchCtrl.clear(); _searchOpen = false; });
    } else if (idx == 1) {
      _openCategoryDrawer();
    } else if (idx == 2) {
      _openCart();
    } else if (idx == 3) {
      setState(() { _navActive = 3; _searchOpen = false; });
    } else if (idx == 4) {
      _openProfile();
    }
  }

  void _openProfile() {
    if (_customer != null) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CustomerPortalScreen(customer: _customer!,
          onLogout: () { StorePushService.instance.logout(); AuthStorage.clear(); setState(() => _customer = null); _load(); })));
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => _LoginScreen(onLogin: (c) async { AuthStorage.save(c); setState(() => _customer = c); StorePushService.instance.setCustomer(c.code); await _load(); })));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kBg,
      body: Stack(children: [
        RefreshIndicator(
          onRefresh: _load,
          color: kAccent,
          strokeWidth: 2.5,
          child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          // Header — logo + Zootopiya + savat
          SliverAppBar(
            pinned: true, floating: true, backgroundColor: kBg,
            surfaceTintColor: kBg,
            elevation: 0, titleSpacing: 20,
            bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: const Divider(height: 1, color: kBorder)),
            title: Row(mainAxisSize: MainAxisSize.min, children: [
              ClipOval(child: Image.asset('assets/logo_icon.png', width: 34, height: 34, fit: BoxFit.cover)),
              const SizedBox(width: 9),
              const Text('Zootopiya', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kAccent, letterSpacing: -.3)),
            ]),
            actions: [
              Padding(padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: _openCart,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(width: 40, height: 40, child: Stack(clipBehavior: Clip.none, children: [
                    const Center(child: Icon(Icons.shopping_cart_outlined, color: kAccent, size: 25)),
                    if (_cartCount > 0)
                      Positioned(right: 0, top: 2, child: Container(
                        constraints: const BoxConstraints(minWidth: 17), height: 17,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(color: const Color(0xFFE0912A), borderRadius: BorderRadius.circular(9), border: Border.all(color: kBg, width: 1.5)),
                        child: Center(child: Text(_cartCount > 9 ? '9+' : '$_cartCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
                      )),
                  ])),
                )),
            ],
          ),

          // Qidiruv paneli — rasmdagidek (doimiy)
          if (_navActive != 3)
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
              child: Container(
                height: 46,
                decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
                child: Row(children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search_rounded, color: kTextSub, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(fontSize: 14, color: kText),
                    decoration: const InputDecoration(
                      hintText: 'Mahsulot yoki kategoriya qidiring...',
                      hintStyle: TextStyle(color: kTextMuted, fontSize: 14),
                      border: InputBorder.none, isCollapsed: true,
                    ),
                  )),
                  if (_search.isNotEmpty)
                    GestureDetector(onTap: () { _searchCtrl.clear(); setState(() => _search = ''); },
                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.close_rounded, size: 18, color: kTextSub))),
                ]),
              ),
            )),

          // Top kategoriya chiplar (sevimlilar rejimida yashiriladi)
          if (_navActive != 3 && _topCats.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: _CatBarDelegate(
                cats: _topCats, selId: _selTop, accentActive: true,
                onSelect: (id) => setState(() { _selTop = id; _selSub = null; }),
              ),
            ),

          // Sub-kategoriya chiplar (tanlangan top'da sub bo'lsa)
          if (_navActive != 3 && _subCats.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: _CatBarDelegate(
                cats: _subCats, selId: _selSub, accentActive: false,
                onSelect: (id) => setState(() => _selSub = id),
              ),
            ),

          // Title
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Flexible(child: Text(_navActive == 3 ? 'Sevimlilar' : 'Mahsulotlar',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kText))),
              const SizedBox(width: 10),
              if (!_loading) Text('${_gridItems.length} ta',
                style: const TextStyle(fontSize: 15, color: kTextMuted, fontWeight: FontWeight.w400)),
            ]),
          )),

          // Grid
          if (_loading && _navActive != 3)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((_, i) => _SkeletonCard(), childCount: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 20, childAspectRatio: .58),
              ),
            )
          else if (_error.isNotEmpty && _navActive != 3)
            SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(40),
              child: Column(children: [
                const Text('😕', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(_error, style: const TextStyle(color: kTextMuted, fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextButton(onPressed: _load, child: const Text('Qayta urinish', style: TextStyle(color: kAccentDark))),
              ]))))
          else if (_gridItems.isEmpty)
            SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(60),
              child: Column(children: [
                Text(_navActive == 3 ? '🤍' : '🔍', style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(_navActive == 3 ? "Sevimlilar bo'sh" : 'Mahsulot topilmadi',
                  style: const TextStyle(color: kTextMuted, fontSize: 15, fontWeight: FontWeight.w600)),
                if (_navActive == 3) ...[
                  const SizedBox(height: 6),
                  const Text('Mahsulotdagi 🤍 belgisini bosing', style: TextStyle(color: kTextMuted, fontSize: 13)),
                ],
              ]))))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => ProductCard(
                    product: _gridItems[i], cart: _cart,
                    onAdd: _addToCart, onDetail: _openDetail, onOrb: _triggerOrb,
                    onSetQty: (p, unit, qty) => _setQty('${p.id}_${unit.unitId}', qty),
                    isFav: _favs.contains(_gridItems[i].id),
                    onFav: () => _toggleFav(_gridItems[i].id),
                  ),
                  childCount: _gridItems.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 16, childAspectRatio: .58),
              ),
            ),
        ])),

        // Bottom Nav
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: BottomNav(active: _navActive, cartCount: _cartCount, favCount: _favs.length, onTap: _onNavTap),
        ),

        // Full-screen loading (first launch only)
        if (_firstLoad)
          AnimatedOpacity(
            opacity: _splashVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 420),
            child: const _LoadingScreen(),
          ),
      ]),
    );
  }
}

// ── Loading Screen ─────────────────────────────────────────────────────────
class _LoadingScreen extends StatefulWidget {
  const _LoadingScreen();
  @override
  State<_LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<_LoadingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: kBg,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ScaleTransition(
            scale: _pulse,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: kAccent.withAlpha(60), blurRadius: 30, spreadRadius: 4)],
              ),
              child: ClipOval(child: Image.asset('assets/logo_icon.png', fit: BoxFit.cover)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Zootopiya', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kAccent)),
          const SizedBox(height: 12),
          _DotsLoader(),
        ]),
      ),
    );
  }
}

class _DotsLoader extends StatefulWidget {
  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
          final delay = i / 3;
          final t = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
          final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.3, 1.0);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 7, height: 7,
            decoration: BoxDecoration(
              color: kAccent.withOpacity(opacity),
              shape: BoxShape.circle,
            ),
          );
        }));
      },
    );
  }
}

// ── Category Bar delegate ──────────────────────────────────────────────────
class _CatBarDelegate extends SliverPersistentHeaderDelegate {
  final List<Category> cats;
  final int? selId;
  final ValueChanged<int?> onSelect;
  final bool accentActive; // true = top qatori, false = sub qatori (yumshoq)
  _CatBarDelegate({required this.cats, this.selId, required this.onSelect, this.accentActive = true});

  @override
  double get minExtent => accentActive ? 50 : 46;
  @override
  double get maxExtent => accentActive ? 50 : 46;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: kBg,
      child: Column(children: [
        Expanded(child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: accentActive ? 9 : 7),
          children: [
            _Chip('Barchasi', selId == null, () => onSelect(null)),
            ...cats.map((c) => _Chip(c.name, selId == c.id, () => onSelect(c.id))),
          ],
        )),
        const Divider(height: 1, color: kBorder),
      ]),
    );
  }

  Widget _Chip(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: accentActive ? 16 : 14),
      decoration: BoxDecoration(
        // Aktiv = yashil (top to'q, sub yumshoq)
        color: active ? (accentActive ? kAccent : kAccentBg) : kSurface,
        border: Border.all(
          color: active ? kAccent : kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(child: Text(label,
        style: TextStyle(
          fontSize: accentActive ? 13 : 12.5,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          color: active ? (accentActive ? Colors.white : kAccentDark) : const Color(0xFF555555)))),
    ),
  );

  @override
  bool shouldRebuild(_CatBarDelegate old) => old.selId != selId || old.cats != cats || old.accentActive != accentActive;
}

// ── Category Drawer (expandable — parent → sub) ─────────────────────────────
const _dcCoral     = Color(0xFF6B8E4E); // leaf green
const _dcCoralDark = Color(0xFF3E5C42);
const _dcActiveBg  = Color(0xFFEDF3E6);
const _dcText      = Color(0xFF2C4230);
const _dcMuted     = Color(0xFFB8B0AD);

class _CategoryDrawer extends StatefulWidget {
  final List<Category> allCats;
  final int? selTop;
  final int? selSub;
  final void Function(int? top, int? sub) onSelect;
  const _CategoryDrawer({required this.allCats, this.selTop, this.selSub, required this.onSelect});
  @override
  State<_CategoryDrawer> createState() => _CategoryDrawerState();
}

class _CategoryDrawerState extends State<_CategoryDrawer> {
  String _q = '';
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    if (widget.selTop != null) _expanded.add(widget.selTop!);
  }

  List<Category> _childrenOf(int id) => widget.allCats.where((c) => c.parentId == id).toList();
  void _pick(int? top, int? sub) { widget.onSelect(top, sub); Navigator.pop(context); }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    var tops = widget.allCats.where((c) => c.parentId == null).toList();
    if (q.isNotEmpty) {
      tops = tops.where((t) =>
        t.name.toLowerCase().contains(q) ||
        _childrenOf(t.id).any((s) => s.name.toLowerCase().contains(q))).toList();
    }
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(color: kBg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 14),
          decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Katalog', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _dcText)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: _dcCoral.withAlpha(70), blurRadius: 12, spreadRadius: -2)],
              ),
              child: TextField(
                onChanged: (v) => setState(() => _q = v),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _dcText),
                decoration: const InputDecoration(
                  hintText: "Bo'limlarni qidirish...",
                  hintStyle: TextStyle(color: Color(0xFF8E8E93), fontWeight: FontWeight.w400),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ),
          ]),
        ),
        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 40),
          children: [
            _leafCard('Barchasi', widget.selTop == null && widget.selSub == null, () => _pick(null, null), hasSubs: false),
            ...tops.map(_buildTop),
          ],
        )),
      ]),
    );
  }

  Widget _buildTop(Category top) {
    final subs = _childrenOf(top.id);
    final q = _q.trim().toLowerCase();
    if (subs.isEmpty) {
      final active = widget.selTop == top.id && widget.selSub == null;
      return _leafCard(top.name, active, () => _pick(top.id, null), hasSubs: false);
    }
    final expanded = _expanded.contains(top.id) || (q.isNotEmpty && subs.any((s) => s.name.toLowerCase().contains(q)));
    final parentActive = widget.selTop == top.id && widget.selSub == null;
    final visibleSubs = subs.where((s) => q.isEmpty || s.name.toLowerCase().contains(q)).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 18, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // Parent header
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => expanded ? _expanded.remove(top.id) : _expanded.add(top.id)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(children: [
              Expanded(child: Text(top.name,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                  color: parentActive ? _dcCoralDark : _dcText))),
              AnimatedRotation(
                duration: const Duration(milliseconds: 180),
                turns: expanded ? 0.5 : 0,
                child: Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(color: expanded ? _dcCoral : const Color(0xFFF2F2F2), shape: BoxShape.circle),
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 18,
                    color: expanded ? Colors.white : const Color(0xFF9A9A9A)),
                ),
              ),
            ]),
          ),
        ),
        if (expanded) ...[
          const Divider(height: 1, color: Color(0xFFF0EEEC)),
          _subRow("Hammasi", parentActive, () => _pick(top.id, null)),
          ...visibleSubs.map((s) => _subRow(s.name, widget.selSub == s.id, () => _pick(top.id, s.id))),
          const SizedBox(height: 6),
        ],
      ]),
    );
  }

  // Sub-yo'q oddiy karta (Barchasi / bolasi yo'q top)
  Widget _leafCard(String name, bool active, VoidCallback onTap, {required bool hasSubs}) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: active ? _dcActiveBg : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 18, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Expanded(child: Text(name,
          style: TextStyle(fontSize: 15, fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? _dcCoralDark : _dcText))),
        if (active) Container(width: 8, height: 8, decoration: const BoxDecoration(color: _dcCoral, shape: BoxShape.circle)),
      ]),
    ),
  );

  // Sub-kategoriya qatori (chapda coral chiziq bilan)
  Widget _subRow(String name, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      color: active ? _dcActiveBg : Colors.transparent,
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 13),
      child: Row(children: [
        Container(width: 3, height: 16, margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(color: active ? _dcCoral : _dcMuted, borderRadius: BorderRadius.circular(2))),
        Expanded(child: Text(name,
          style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            color: active ? _dcCoralDark : _dcText))),
        if (active) const Icon(Icons.check_rounded, size: 16, color: _dcCoral),
      ]),
    ),
  );
}

// ── Skeleton card ──────────────────────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(12)), height: 140),
    const SizedBox(height: 10),
    Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(6))),
    const SizedBox(height: 6),
    Container(height: 12, width: 80, decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(6))),
  ]);
}

// ── Login Screen ───────────────────────────────────────────────────────────
class _LoginScreen extends StatefulWidget {
  final ValueChanged<Customer> onLogin;
  const _LoginScreen({required this.onLogin});
  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String _err = '';

  Future<void> _go() async {
    if (_ctrl.text.trim().isEmpty) { setState(() => _err = 'ID kiriting'); return; }
    setState(() { _busy = true; _err = ''; });
    try {
      final c = await ApiService.login(_ctrl.text.trim());
      if (mounted) { widget.onLogin(c); Navigator.pop(context); }
    } catch (e) {
      if (mounted) setState(() { _busy = false; _err = friendlyError(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, surfaceTintColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: kTextSub), onPressed: () => Navigator.pop(context))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Kirish', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 8),
          const Text("Do'kondan olgan ID raqamingizni kiriting", style: TextStyle(fontSize: 14, color: kTextSub)),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(border: Border.all(color: kBorder, width: 1.5), borderRadius: BorderRadius.circular(12), color: const Color(0xFFFAFAFA)),
            child: TextField(
              controller: _ctrl, textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 16, fontFamily: 'monospace', letterSpacing: 2, color: kText),
              decoration: const InputDecoration(hintText: 'CUST-XXXXXX', hintStyle: TextStyle(color: kTextMuted, letterSpacing: 1), border: InputBorder.none, contentPadding: EdgeInsets.all(16)),
              onSubmitted: (_) => _go(),
            ),
          ),
          if (_err.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFF5F5), borderRadius: BorderRadius.circular(10)),
              child: Text(_err, style: const TextStyle(color: kRed, fontSize: 13))),
          ],
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _busy ? null : _go,
            child: Container(width: double.infinity, height: 50,
              decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: kAccent.withAlpha(76), blurRadius: 14, offset: const Offset(0, 4))]),
              child: Center(child: _busy
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Text('Kirish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)))),
          ),
        ]),
      ),
    );
  }
}
