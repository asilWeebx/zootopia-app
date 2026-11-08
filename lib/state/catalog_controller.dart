import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../config/store.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/catalog.dart';
import '../services/groups.dart';
import '../services/push_service.dart';
import '../services/storage.dart';

/// Nega ma'lumot yo'q: kalit rad etilgan (odam tuzatishi kerak) yoki tarmoq.
enum FailureReason { auth, unavailable }

/// Do'kon ma'lumotlari manbai — odatda API; testlarda tayyor katalog.
abstract class StoreSource {
  Future<StoreInfo> info();
  Future<CatalogResponse> catalog(String? customerCode);
  Future<List<int>> topProductIds();
}

class ApiStoreSource implements StoreSource {
  const ApiStoreSource();
  @override
  Future<StoreInfo> info() => ApiService.getInfo();
  @override
  Future<CatalogResponse> catalog(String? customerCode) => ApiService.getCatalog(customerCode: customerCode);
  @override
  Future<List<int>> topProductIds() => ApiService.getTopProductIds(limit: 12);
}

/// Katalog, do'kon va mijoz — saytdagi `store.ts` + `CatalogProvider` +
/// `useCustomer` birlashmasi. Butun katalog bitta so'rovda keladi; sahifalar
/// hammasini shundan hisoblaydi.
class CatalogController extends ChangeNotifier {
  CatalogController({this.source = const ApiStoreSource(), this.persist = true});

  final StoreSource source;
  /// Testlarda false — mijoz qurilmaga saqlanmaydi, push ulanmaydi.
  final bool persist;

  // ── Do'kon ────────────────────────────────────────────────────
  /// ERP tashkiloti ("Zootopia") — futer uchun.
  String organization = Brand.name;
  /// Qoldiq olinadigan ERP filiali ("Крытый магазин").
  String branch = '';
  /// Faqat ERP bannerlari; bosh sahifaning o'z qahramon bloki bor.
  List<StoreBanner> banners = const [];

  // ── Katalog ───────────────────────────────────────────────────
  List<Product> products = const [];
  /// Ta'mlari birlashgan mahsulotlar (`services/groups.dart`).
  GroupIndex groups = GroupIndex.empty;
  /// Har guruhdan bittadan, qolganlari o'zicha — to'r va javonlar shuni ko'rsatadi.
  List<Product> cards = const [];
  List<Category> categories = const [];
  Map<int, String> categoryImages = const {};
  List<Product> topProducts = const [];
  Set<int> topIds = const {};
  bool showImages = true;
  bool showStock = true;

  bool loading = true;
  /// Katalog hech bo'lmasa bir marta yuklandi.
  bool configured = false;
  FailureReason? reason;

  // ── Mijoz ─────────────────────────────────────────────────────
  Customer? customer;
  bool customerReady = false;

  Product? productById(int id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Mahsulot ta'mlar guruhida bo'lsa — o'sha guruh.
  ProductGroup? groupOf(int productId) => groups.byProduct[productId];

  Future<void> init() async {
    if (persist) {
      customer = await Storage.loadCustomer();
      if (customer != null) StorePushService.instance.setCustomer(customer!.customerCode);
    }
    customerReady = true;
    notifyListeners();
    await load();
  }

  int _loadId = 0;

  /// Oxirgi kelgan katalog — til almashganda qayta so'rovsiz qayta quriladi.
  CatalogResponse? _raw;
  List<int> _top = const [];

  /// Do'kon ma'lumoti va katalog. Xato saytni bo'shatmaydi: oldingi katalog
  /// qoladi, umuman bo'lmasa sahifa sababini aytadi.
  Future<void> load() async {
    final id = ++_loadId;
    loading = true;
    notifyListeners();
    final infoFuture = source.info().then<StoreInfo?>((i) => i).catchError((Object _) => null);
    // Ko'p sotilganlar — qo'shimcha; sahifa ular uchun yiqilmasin.
    final topFuture = source.topProductIds().catchError((Object _) => const <int>[]);
    try {
      final raw = await source.catalog(customer?.customerCode);
      final info = await infoFuture;
      final top = await topFuture;
      if (id != _loadId) return;
      _apply(raw, top);
      if (info != null) {
        organization = info.organization.trim().isNotEmpty ? info.organization.trim() : Brand.name;
        branch = info.store.trim();
        banners = info.banners;
      }
      configured = true;
      reason = null;
    } catch (e) {
      if (id != _loadId) return;
      if (!configured) {
        reason = e is StorefrontError && const [401, 403, 500].contains(e.status) ? FailureReason.auth : FailureReason.unavailable;
      }
    }
    loading = false;
    notifyListeners();
  }

  /// Rasm manzillari mutlaq qilinadi, kategoriyalar qayta nomlanib
  /// normallashtiriladi — hamma sahifa bitta daraxtni o'qiydi.
  void _apply(CatalogResponse raw, List<int> topIds) {
    _raw = raw;
    _top = topIds;
    final list = normalizeCategories(relabelCategories([
      for (final p in raw.results)
        p.withMedia(
          name: p.name.trim().isNotEmpty ? p.name.trim() : tr.unnamed,
          image: ApiService.media(p.image),
          images: p.images.map(ApiService.media).where((s) => s.isNotEmpty).toList(),
          variants: [for (final v in p.variants) v.withImage(ApiService.media(v.image).isEmpty ? null : ApiService.media(v.image))],
        ),
    ]));
    products = list;
    groups = buildGroups(list);
    cards = collapseGroups(list, groups);
    categories = buildCategories(list);
    final images = {for (final e in raw.categoryImages.entries) e.key: ApiService.media(e.value)};
    for (final category in categories) {
      if ((images[category.id] ?? '').isEmpty) {
        images[category.id] = productsInCategory(list, category.id).where((p) => p.image.isNotEmpty).firstOrNull?.image ?? '';
      }
    }
    categoryImages = images;
    topProducts = rankTopProducts(topIds, list);
    this.topIds = topIds.toSet();
    showImages = raw.showImages;
    showStock = raw.showStock;
  }

  /// Til almashdi: ombor guruhlari, "Boshqa mahsulotlar" va birlik yorliqlari
  /// yangi tilda qayta quriladi (oxirgi katalogdan, tarmoqsiz).
  void relabel() {
    final raw = _raw;
    if (raw == null) return;
    _apply(raw, _top);
    notifyListeners();
  }

  /// Kirgandan keyin narxlar shu mijozniki bo'ladi.
  Future<void> signIn(Customer next) async {
    customer = next;
    if (persist) {
      await Storage.saveCustomer(next);
      StorePushService.instance.setCustomer(next.customerCode);
    }
    notifyListeners();
    await load();
  }

  Future<void> signOut() async {
    customer = null;
    if (persist) {
      StorePushService.instance.logout();
      await Storage.saveCustomer(null);
    }
    notifyListeners();
    await load();
  }
}
