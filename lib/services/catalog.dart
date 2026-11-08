import '../config/catalog.dart';
import '../config/pets.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import 'options.dart';
import 'pets.dart';

/// Hech qachon kategoriya berilmagan mahsulotlar uchun soxta yuqori
/// kategoriya. ERP id'lari musbat, shuning uchun to'qnashmaydi.
const kUncategorizedId = -1;

/// "Boshqa mahsulotlar" / "Другие товары".
String get kUncategorizedName => tr.uncategorized;

/// JS'dagi `Array.sort` kabi barqaror tartiblash (Dart'nikida kafolat yo'q).
List<T> stableSorted<T>(Iterable<T> items, int Function(T a, T b) compare) {
  final indexed = items.indexed.toList();
  indexed.sort((a, b) {
    final c = compare(a.$2, b.$2);
    return c != 0 ? c : a.$1 - b.$1;
  });
  return [for (final (_, item) in indexed) item];
}

int _soldOutLast(Product a, Product b) => (isOutOfStock(a) ? 1 : 0) - (isOutOfStock(b) ? 1 : 0);

/// `normalizeCategories`dan keyin mahsulotda kategoriya id faqat nomli kategoriyada bo'lsa bor.
bool isUncategorized(Product p) => p.categoryId == null || p.categoryId == 0;

/// `config/catalog.dart`ni qo'llaydi: ERP ildiz guruhidagi mahsulotlar bu
/// "kategoriya"ni yo'qotadi, ombor nomlari xaridor yorlig'ini oladi.
/// `normalizeCategories`dan oldin ishlaydi — daraxt natijadan quriladi.
List<Product> relabelCategories(List<Product> products) {
  bool isRoot(String? name) => name != null && kRootCategory.hasMatch(name.trim());
  final labels = tr.categoryLabels;
  String? label(String? name) => name == null ? null : (labels[name.trim()] ?? name);
  return [
    for (final p in products)
      () {
        var id = p.categoryId, name = p.categoryName, parentId = p.categoryParentId, parentName = p.categoryParentName;
        if (isRoot(parentName)) {
          parentId = null;
          parentName = null;
        }
        if (isRoot(name)) {
          id = parentId;
          name = parentName;
          parentId = null;
          parentName = null;
        }
        return p.withCategory(categoryId: id, categoryName: label(name), categoryParentId: parentId, categoryParentName: label(parentName));
      }(),
  ];
}

/// Har mahsulotning kategoriya maydonlarini do'kon ko'rsatadigan ikki darajaga
/// keltiradi: yuqori kategoriya va uning ostida ko'pi bilan bitta subkategoriya.
///
/// API kategoriya daraxtini bermaydi — faqat mahsulot kategoriyasi va uning
/// ota-kategoriyasi, to'liqligi kafolatlanmagan. Shuning uchun:
///  - bir qatorda yo'q nom boshqa qatordan olinadi;
///  - nomsiz kategoriya mahsulotlarini eng yaqin nomli ajdodiga, u ham
///    bo'lmasa "Boshqa mahsulotlar"ga beradi;
///  - ota-kategoriyasi noma'lum kategoriya yuqori darajaga chiqadi;
///  - chuqurrog'i yuqori kategoriyasi ostiga oraliq nomlar bilan tushadi
///    ("Mushuklar › Quruq ozuqa").
List<Product> normalizeCategories(List<Product> products) {
  final names = <int, String>{};
  final parents = <int, int>{};
  void learnName(int? id, String? name) {
    final trimmed = name?.trim();
    if (id != null && id != 0 && trimmed != null && trimmed.isNotEmpty && !names.containsKey(id)) names[id] = trimmed;
  }

  for (final p in products) {
    learnName(p.categoryId, p.categoryName);
    learnName(p.categoryParentId, p.categoryParentName);
    final id = p.categoryId, parentId = p.categoryParentId;
    if (id != null && id != 0 && parentId != null && parentId != 0 && parentId != id && !parents.containsKey(id)) {
      parents[id] = parentId;
    }
  }

  /// `id`dan ildizgacha nomli kategoriyalar, eng yaqini birinchi.
  List<(int, String)> namedChain(int id) {
    final chain = <(int, String)>[];
    final seen = <int>{};
    int? current = id;
    while (current != null) {
      seen.add(current);
      final name = names[current];
      if (name != null) chain.add((current, name));
      var up = parents[current];
      // ERP ma'lumotidagi halqa — shu yerda kesiladi.
      if (up != null && seen.contains(up)) {
        parents.remove(current);
        up = null;
      }
      current = up;
    }
    return chain;
  }

  return [
    for (final p in products)
      () {
        final anchor = (p.categoryId != null && p.categoryId != 0) ? p.categoryId : p.categoryParentId;
        final chain = (anchor != null && anchor != 0) ? namedChain(anchor) : const <(int, String)>[];
        if (chain.isEmpty) {
          return p.withCategory(categoryId: null, categoryName: null, categoryParentId: null, categoryParentName: null);
        }
        final top = chain.last;
        if (chain.length == 1) {
          return p.withCategory(categoryId: top.$1, categoryName: top.$2, categoryParentId: null, categoryParentName: null);
        }
        return p.withCategory(
          categoryId: chain.first.$1,
          categoryName: chain.sublist(0, chain.length - 1).reversed.map((c) => c.$2).join(' › '),
          categoryParentId: top.$1,
          categoryParentName: top.$2,
        );
      }(),
  ];
}

/// Tekis kategoriya ro'yxati — ERP'ning o'z ro'yxati tartibida
/// (`kCategoryOrder`). API tartib bermaydi, mahsulotlari esa taxminan eng
/// yangisi birinchi keladi — kelgan tartibda sanash har yangi mahsulotda
/// bo'limlarni aralashtirardi. Ro'yxatda yo'q bo'limlar undan keyin, id
/// bo'yicha. Kategoriyasiz mahsulotlar oxiridagi soxta umumiy kategoriyaga
/// ("Boshqa mahsulotlar") yig'iladi.
List<Category> buildCategories(List<Product> products) {
  final map = <int, Category>{};
  var hasUncategorized = false;
  for (final p in products) {
    if (p.categoryId != null && p.categoryId != 0 && (p.categoryName ?? '').isNotEmpty) {
      map[p.categoryId!] = Category(
        id: p.categoryId!,
        name: p.categoryName!,
        parentId: (p.categoryParentId == null || p.categoryParentId == 0) ? null : p.categoryParentId,
      );
    } else if (isUncategorized(p)) {
      hasUncategorized = true;
    }
    final parentId = p.categoryParentId;
    if (parentId != null && parentId != 0 && (p.categoryParentName ?? '').isNotEmpty && !map.containsKey(parentId)) {
      map[parentId] = Category(id: parentId, name: p.categoryParentName!);
    }
  }
  if (hasUncategorized) map[kUncategorizedId] = Category(id: kUncategorizedId, name: kUncategorizedName);
  return stableSorted(map.values, (a, b) {
    if (a.id == kUncategorizedId) return 1;
    if (b.id == kUncategorizedId) return -1;
    final c = categoryRank(a.name) - categoryRank(b.name);
    return c != 0 ? c : a.id - b.id;
  });
}

/// Yuqori kategoriyalar, `buildCategories` tartibida.
List<Category> topCategories(List<Category> categories) => categories.where((c) => c.parentId == null).toList();

List<Product> productsInCategory(List<Product> products, int categoryId) {
  if (categoryId == kUncategorizedId) return products.where(isUncategorized).toList();
  return products.where((p) => p.categoryId == categoryId || p.categoryParentId == categoryId).toList();
}

/// Tartiblash va "o'xshash"larni narx yaqinligi bo'yicha qo'yish uchun taxminiy narx.
double approxPrice(Product p) {
  final groups = optionPriceGroups(productOptions(p));
  return groups.isEmpty ? double.infinity : groups.first.option.price;
}

/// ERP joriy narxdan yuqori eski narx yuboradimi.
bool isDiscounted(Product p) =>
    p.discountPercent > 0 ||
    productOptions(p).any((o) => o.originalPrice != null && o.originalPrice! > o.curPrice);

/// Avval o'sha hayvon uchun o'sha turdagi (mushuk ozuqasiga — boshqa mushuk
/// ozuqasi), keyin o'sha hayvon, keyin o'sha kategoriya; har birida narxi
/// yaqini birinchi. Yuklangan katalogdan, API so'rovisiz.
List<Product> similarProducts(Product? p, List<Product> all, [int limit = 8]) {
  if (p == null) return const [];
  final pets = productPets(p);
  final type = productType(p);
  final tiers = <List<Product>>[[], [], []];
  for (final x in all) {
    if (x.id == p.id) continue;
    final xPets = productPets(x);
    final samePet = pets.isNotEmpty ? xPets.any(pets.contains) : xPets.isEmpty;
    final sameCategory = p.categoryId != null && p.categoryId != 0 && x.categoryId == p.categoryId;
    if (samePet && type != null && productType(x) == type) {
      tiers[0].add(x);
    } else if (samePet) {
      tiers[1].add(x);
    } else if (sameCategory) {
      tiers[2].add(x);
    }
  }
  final base = approxPrice(p);
  List<Product> byCloseness(List<Product> list) => stableSorted(list, (a, b) {
        final s = _soldOutLast(a, b);
        if (s != 0) return s;
        final d = (approxPrice(a) - base).abs() - (approxPrice(b) - base).abs();
        return d.isNaN || d == 0 ? 0 : (d < 0 ? -1 : 1);
      });
  return tiers.expand(byCloseness).take(limit).toList();
}

/// Rus harflari lotinda — "royal" "Роял Канин"ni, "viskas" "Вискас"ni topadi.
const _latin = {
  'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo', 'ж': 'j', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k',
  'л': 'l', 'м': 'm', 'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u', 'ф': 'f', 'х': 'x', 'ц': 'ts',
  'ч': 'ch', 'ш': 'sh', 'щ': 'sh', 'ъ': '', 'ы': 'i', 'ь': '', 'э': 'e', 'ю': 'yu', 'я': 'ya', 'ў': "o'", 'қ': 'q',
  'ғ': "g'", 'ҳ': 'h',
};

String transliterate(String text) =>
    text.toLowerCase().replaceAllMapped(RegExp('[а-яёўқғҳ]'), (m) => _latin[m[0]] ?? m[0]!);

final _haystackCache = Expando<String>();

/// Qidiruv matni: nom, artikul, kategoriya, tavsif, variant nomlari, hayvon va
/// mahsulot turi ilova tilidan qat'i nazar ikkala tilda ("mushuk", "кошки",
/// "quruq ozuqa", "сухой корм") va ruscha nomlarning lotincha yozilishi — ERP
/// nomlari ruscha, xaridor ko'pincha lotincha yozadi.
String _haystack(Product p) => _haystackCache[p] ??= () {
      final petIds = productPets(p);
      final type = productType(p);
      final text = [
        p.name,
        p.sku,
        p.categoryName,
        p.categoryParentName,
        p.description,
        for (final v in p.variants) ...[v.name, v.sku],
      ].whereType<String>().where((s) => s.isNotEmpty).join(' ').toLowerCase();
      return [
        text,
        transliterate(text),
        for (final lang in AppLang.values) ...[
          for (final id in petIds) '${stringsFor(lang).petLabel(id)} ${stringsFor(lang).petForLabel(id)}',
          if (type != null) stringsFor(lang).types[type]!,
        ],
      ].join(' ').toLowerCase();
    }();

/// O'zbekcha tutuq belgilari har xil (o‘, o', oʻ) — qidiruv ularni bitta deb biladi.
String _foldApostrophes(String value) => value.replaceAll(RegExp('[ʻʼ’‘`]'), "'");

final _longCyrillic = RegExp(r'^[а-яё]{5,}$');
final _finalVowel = RegExp(r'[аеёиоуыэюяйь]$');

/// Ruscha so'z oxiri o'zgaradi (кошка, кошки, кошек), qidiruv esa so'z
/// bo'lagini qidiradi — besh va undan uzun kirill so'z oxirgi unli yoki
/// yumshatish belgisini yo'qotadi: "кошка" "кошк"ni qidiradi, uchalasida bor.
/// Harf olib tashlash faqat ko'proq topadi.
String _stem(String word) => _longCyrillic.hasMatch(word) ? word.replaceFirst(_finalVowel, '') : word;

List<String> _words(String query) =>
    _foldApostrophes(query.toLowerCase()).trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map(_stem).toList();

bool matchesSearch(Product p, String query) {
  final words = _words(query);
  if (words.isEmpty) return true;
  final hay = _foldApostrophes(_haystack(p));
  return words.every(hay.contains);
}

/// Bitta matn bo'yicha qidiruv — tanlagichdagi ta'm nomi, xuddi shu so'z va yozuv qoidalari bilan.
bool matchesText(String text, String query) {
  final words = _words(query);
  if (words.isEmpty) return true;
  final lower = _foldApostrophes(text.toLowerCase());
  final hay = '$lower ${transliterate(lower)}';
  return words.every(hay.contains);
}

/// Belgi juftlari — ikki matn qanchalik o'xshashini baholash uchun.
Set<String> _bigrams(String value) {
  final normalized = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9а-яёўқғҳ]+', caseSensitive: false), ' ').trim();
  return {for (var i = 0; i < normalized.length - 1; i++) normalized.substring(i, i + 2)};
}

/// Aniq moslik bo'lmaganda: so'rov bilan umumiy so'zi bor mahsulotlar (ko'p
/// umumiy so'z birinchi); u ham bo'lmasa — eng yaqin yozilishlar, xato yozilgan
/// so'z ("proplam") ham nimadir topsin.
List<Product> searchSuggestions(String query, List<Product> all, [int limit = 8]) {
  final words = _words(query);
  if (words.isEmpty) return const [];

  final scored = <(Product, int)>[];
  for (final p in all) {
    final hay = _foldApostrophes(_haystack(p));
    final score = words.where(hay.contains).length;
    if (score > 0) scored.add((p, score));
  }
  if (scored.isNotEmpty) {
    final sorted = stableSorted(scored, (a, b) {
      final s = b.$2 - a.$2;
      return s != 0 ? s : _soldOutLast(a.$1, b.$1);
    });
    return sorted.take(limit).map((s) => s.$1).toList();
  }

  final queryPairs = _bigrams(query);
  if (queryPairs.isEmpty) return const [];
  final close = <(Product, double)>[];
  for (final p in all) {
    final productPairs = _bigrams(_haystack(p));
    final overlap = queryPairs.where(productPairs.contains).length;
    final score = overlap / queryPairs.length;
    if (score >= 0.3) close.add((p, score));
  }
  return stableSorted(close, (a, b) => b.$2.compareTo(a.$2)).take(limit).map((s) => s.$1).toList();
}

enum SortKey { recommended, priceAsc, priceDesc, name }

/// Saralash variantlari joriy tilda.
List<(SortKey, String)> get kSortOptions => [for (final key in SortKey.values) (key, tr.sortOptions[key]!)];

class CatalogFilters {
  final int? categoryId;
  final PetId? pet;
  final ProductTypeId? type;
  final String query;
  final bool inStockOnly;
  final bool saleOnly;
  final SortKey sort;

  const CatalogFilters({
    this.categoryId,
    this.pet,
    this.type,
    this.query = '',
    this.inStockOnly = false,
    this.saleOnly = false,
    this.sort = SortKey.recommended,
  });

  static const _keep = Object();

  CatalogFilters copyWith({
    Object? categoryId = _keep,
    Object? pet = _keep,
    Object? type = _keep,
    String? query,
    bool? inStockOnly,
    bool? saleOnly,
    SortKey? sort,
  }) =>
      CatalogFilters(
        categoryId: identical(categoryId, _keep) ? this.categoryId : categoryId as int?,
        pet: identical(pet, _keep) ? this.pet : pet as PetId?,
        type: identical(type, _keep) ? this.type : type as ProductTypeId?,
        query: query ?? this.query,
        inStockOnly: inStockOnly ?? this.inStockOnly,
        saleOnly: saleOnly ?? this.saleOnly,
        sort: sort ?? this.sort,
      );

  /// Telefondagi "Filtrlar" belgisi uchun: nechta toraytiruvchi filtr yoqilgan.
  int get activeCount => [type != null, categoryId != null, inStockOnly, saleOnly].where((x) => x).length;

  /// "Filtrlarni tozalash" — hayvon, qidiruv va tartib qoladi.
  CatalogFilters cleared() => copyWith(type: null, categoryId: null, inStockOnly: false, saleOnly: false);
}

int _naturalCompare(String a, String b) {
  final re = RegExp(r'(\d+|\D+)');
  final pa = re.allMatches(a.toLowerCase()).map((m) => m[0]!).toList();
  final pb = re.allMatches(b.toLowerCase()).map((m) => m[0]!).toList();
  for (var i = 0; i < pa.length && i < pb.length; i++) {
    final na = int.tryParse(pa[i]), nb = int.tryParse(pb[i]);
    final c = (na != null && nb != null) ? na.compareTo(nb) : pa[i].compareTo(pb[i]);
    if (c != 0) return c;
  }
  return pa.length - pb.length;
}

/// Katalog sahifasi ro'yxati. Tugaganlar, yashirilmasa, oxiriga tushadi.
List<Product> filterProducts(List<Product> products, CatalogFilters f) {
  var list = products;
  if (f.categoryId != null) list = productsInCategory(list, f.categoryId!);
  if (f.pet != null) list = list.where((p) => matchesPet(p, f.pet!)).toList();
  if (f.type != null) list = list.where((p) => productType(p) == f.type).toList();
  if (f.query.trim().isNotEmpty) list = list.where((p) => matchesSearch(p, f.query)).toList();
  if (f.inStockOnly) list = list.where((p) => !isOutOfStock(p)).toList();
  if (f.saleOnly) list = list.where(isDiscounted).toList();

  var sorted = list;
  switch (f.sort) {
    case SortKey.priceAsc:
      sorted = stableSorted(list, (a, b) => approxPrice(a).compareTo(approxPrice(b)));
    case SortKey.priceDesc:
      sorted = stableSorted(list, (a, b) => approxPrice(b).compareTo(approxPrice(a)));
    case SortKey.name:
      sorted = stableSorted(list, (a, b) => _naturalCompare(a.name, b.name));
    case SortKey.recommended:
      break;
  }
  return stableSorted(sorted, _soldOutLast);
}

class PetSection {
  final PetId id;
  final String title;
  final List<Product> items;
  const PetSection(this.id, this.title, this.items);
}

/// Bosh sahifa javonlari: har hayvonga bittadan (`kPets` tartibida), keyin
/// hech bir hayvon nomlamaganlar. Omborda hech narsasi yo'q javon chiqmaydi;
/// ikki hayvonga mo'ljallangan mahsulot ikkalasida turadi.
List<PetSection> groupByPet(List<Product> products, List<PetId> petIds) {
  final ids = [...petIds, if (!petIds.contains(PetId.other)) PetId.other];
  return [
    for (final id in ids)
      PetSection(id, petForLabel(id), inStockFirst(products.where((p) => matchesPet(p, id)))),
  ].where((s) => s.items.any((p) => !isOutOfStock(p))).toList();
}

/// Ko'p sotilganlar katalog bilan reyting tartibida; tugaganlari tushib qoladi.
List<Product> rankTopProducts(List<int> ids, List<Product> products) {
  if (ids.isEmpty || products.isEmpty) return const [];
  final byId = {for (final p in products) p.id: p};
  return [
    for (final id in ids)
      if (byId[id] case final p? when !isOutOfStock(p)) p,
  ];
}

/// Tugagan mahsulot hech qachon ro'yxat boshida turmaydi.
List<Product> inStockFirst(Iterable<Product> products) => stableSorted(products, _soldOutLast);
