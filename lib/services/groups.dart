import '../config/groups.dart';
import '../models/models.dart';
import 'options.dart';

// Do'kon har ta'mni o'z ERP mahsuloti qilib yozadi ("Мяу с Рыбой в Соусе
// 85гр"). Ilova ularni tanlovli bitta mahsulot qilib ko'rsatadi ("Мяу 85гр").
// Bu faqat ko'rinish: har ta'm o'z qoldig'i, narxi, artikuli va sahifasi bilan
// haqiqiy mahsulot bo'lib qoladi — savat va buyurtmalar guruhni bilmaydi.
//
// Qaysilari birlashishi — `config/groups.dart`. Saytdagi
// `src/lib/shop/groups.ts`ning nusxasi.

class PackSize {
  /// Nomdagidek: "85гр", "6*15гр", "1.5кг".
  final String text;
  final double amount;
  final String unit;
  const PackSize(this.text, this.amount, this.unit);
}

class GroupMember {
  final Product product;
  /// Brend va o'lchamsiz nom: "С рыбой в соусе".
  final String label;
  final PackSize? size;
  const GroupMember(this.product, this.label, this.size);
}

class ProductGroup {
  final String key;
  /// "Мяу 85гр"; o'lcham o'zi tanlov bo'lsa — o'lchamsiz.
  final String title;
  final GroupKind kind;
  /// Avval omborda borlari, keyin nom bo'yicha; birinchisi guruh yuzi.
  final List<GroupMember> members;
  /// Ikkinchi tanlov ("5 л", "10 л"), kichigi birinchi; o'lcham bitta bo'lsa bo'sh.
  final List<PackSize> sizes;
  const ProductGroup({required this.key, required this.title, required this.kind, required this.members, required this.sizes});
}

class GroupIndex {
  final List<ProductGroup> groups;
  final Map<int, ProductGroup> byProduct;
  const GroupIndex(this.groups, this.byProduct);
  static const empty = GroupIndex([], {});
}

final _size = RegExp(
  r'(?<![\p{L}\d.,*/-])(\d+(?:[.,]\d+)?(?:\*\d+)?)\s*(кг|kg|гр|gr|г|g|мл|ml|л|l|шт)(?!\p{L})',
  caseSensitive: false,
  unicode: true,
);
const _units = {'кг': 'кг', 'kg': 'кг', 'гр': 'гр', 'gr': 'гр', 'г': 'гр', 'g': 'гр', 'мл': 'мл', 'ml': 'мл', 'л': 'л', 'l': 'л', 'шт': 'шт'};

/// Sarlavha shu so'zlardan biri bilan tugasa g'alati o'qiladi — ular ta'm bilan qoladi: "С говядиной".
const _linkingWords = {'с', 'c', 'со', 'в', 'и', 'для', 'на', 'из', 'with'};

final _spellings = [
  for (final brand in kSpelledBrands)
    for (final spelling in brand.spellings) (spelling: spelling, name: brand.name),
]..sort((a, b) => b.spelling.length - a.spelling.length);

final _spaces = RegExp(r'\s+');

class _ParsedName {
  final String brandKey;
  final String brand;
  /// Nomning qolgani, so'zlarda.
  final List<String> words;
  final PackSize? size;
  const _ParsedName(this.brandKey, this.brand, this.words, this.size);
}

List<String> _split(String text) => text.split(' ').where((w) => w.isNotEmpty).toList();

_ParsedName? _parseName(String name) {
  final clean = name.replaceAll(_spaces, ' ').trim();
  final match = _size.firstMatch(clean);
  PackSize? size;
  var text = clean;
  if (match != null) {
    final value = match[1]!.replaceAll(',', '.');
    final unit = _units[match[2]!.toLowerCase()]!;
    final amount = value.split('*').fold<double>(1, (total, part) => total * double.parse(part));
    size = PackSize('$value$unit', amount, unit);
    text = '${clean.substring(0, match.start)} ${clean.substring(match.end)}'.replaceAll(_spaces, ' ').trim();
  }
  final lower = text.toLowerCase();

  for (final s in _spellings) {
    if (lower == s.spelling || lower.startsWith('${s.spelling} ')) {
      return _ParsedName(s.name.toLowerCase(), s.name, _split(text.substring(s.spelling.length).trim()), size);
    }
  }

  final words = _split(text);
  if (words.isEmpty) return null;
  final skip = words.length > 1 && kNotBrands.contains(words[0].toLowerCase()) ? 1 : 0;
  final brand = words[skip];
  if (kLineOnlyBrands.contains(brand.toLowerCase())) return null;
  return _ParsedName(brand.toLowerCase(), brand, words.sublist(skip + 1), size);
}

/// ERP bo'limi, `normalizeCategories` oldiga qo'ygan ota bo'limlarsiz.
String _sectionName(Product p) => (p.categoryName ?? '').split('›').last.trim();

/// Hamma joyda bir xil tartib (saytdagi `compareText`).
int compareText(String a, String b) =>
    a.toLowerCase().replaceAll('ё', 'е').compareTo(b.toLowerCase().replaceAll('ё', 'е')).sign;

String _sentenceCase(String text) {
  final lower = text.toLowerCase();
  return lower.isEmpty ? lower : lower[0].toUpperCase() + lower.substring(1);
}

/// Hamma nomlar boshida nechta so'z umumiy — har nomga o'zidan nimadir qoldirib.
int _sharedWordCount(List<List<String>> names) {
  final first = names.first;
  var count = 0;
  while (count < first.length &&
      names.every((words) => words.length > count && words[count].toLowerCase() == first[count].toLowerCase())) {
    count++;
  }
  while (count > 0 && (names.any((words) => words.length == count) || _linkingWords.contains(first[count - 1].toLowerCase()))) {
    count--;
  }
  return count;
}

/// Brend bitta yozilishda: eng ko'p ishlatilgani, config nomlamagan bo'lsa.
String _commonSpelling(List<String> spellings) {
  final counts = <String, int>{};
  for (final s in spellings) {
    counts[s] = (counts[s] ?? 0) + 1;
  }
  return counts.entries.reduce((best, next) => next.value > best.value ? next : best).key;
}

/// JS'dagi `Array.sort` kabi barqaror.
List<T> _stable<T>(List<T> items, int Function(T a, T b) compare) {
  final indexed = items.indexed.toList()
    ..sort((a, b) {
      final c = compare(a.$2, b.$2);
      return c != 0 ? c : a.$1 - b.$1;
    });
  return [for (final (_, item) in indexed) item];
}

class _Candidate {
  final Product product;
  final _ParsedName parsed;
  const _Candidate(this.product, this.parsed);
}

ProductGroup _toGroup(String key, GroupKind kind, List<_Candidate> candidates) {
  final shared = _sharedWordCount([for (final c in candidates) c.parsed.words]);
  final bySize = <String, PackSize>{};
  for (final c in candidates) {
    final size = c.parsed.size;
    if (size != null) bySize[size.text] = size;
  }
  final sizes = _stable(bySize.values.toList(), (a, b) => a.amount.compareTo(b.amount));
  final sizeIsAChoice = sizes.length > 1;
  final brand = _commonSpelling([for (final c in candidates) c.parsed.brand]);
  final title = [
    brand,
    ...candidates.first.parsed.words.take(shared),
    if (!sizeIsAChoice && sizes.isNotEmpty) sizes.first.text,
  ].where((s) => s.isNotEmpty).join(' ');

  final members = _stable(
    [
      for (final c in candidates)
        GroupMember(
          c.product,
          _sentenceCase(c.parsed.words.skip(shared).join(' ').isNotEmpty ? c.parsed.words.skip(shared).join(' ') : c.product.name),
          c.parsed.size,
        ),
    ],
    (a, b) {
      final out = (isOutOfStock(a.product) ? 1 : 0) - (isOutOfStock(b.product) ? 1 : 0);
      if (out != 0) return out;
      final label = compareText(a.label, b.label);
      if (label != 0) return label;
      return (a.size?.amount ?? 0).compareTo(b.size?.amount ?? 0);
    },
  );

  return ProductGroup(key: key, title: title, kind: kind, members: members, sizes: sizeIsAChoice ? sizes : const []);
}

/// Katalogdagi guruhlar. Sof va takrorlanuvchi — har yuklashda bir xil chiqadi.
GroupIndex buildGroups(List<Product> products) {
  final buckets = <String, ({GroupKind kind, List<_Candidate> candidates})>{};
  for (final product in products) {
    final section = _sectionName(product);
    final sectionKind = kGroupedSections[section];
    if (sectionKind == null || product.categoryId == null || product.categoryId == 0 || hasVariants(product)) continue;
    final parsed = _parseName(product.name);
    if (parsed == null) continue;

    final sizeInKey = kSizeChoiceSections.contains(section) && parsed.size != null ? '' : (parsed.size?.text ?? 'none');
    final key = [product.categoryId, parsed.brandKey, sizeInKey, baseUnit(product)?.unitName ?? ''].join('|');
    final bucket = buckets[key] ??= (kind: kScentBrands.contains(parsed.brandKey) ? GroupKind.scent : sectionKind, candidates: []);
    bucket.candidates.add(_Candidate(product, parsed));
  }

  final groups = <ProductGroup>[];
  final byProduct = <int, ProductGroup>{};
  for (final MapEntry(:key, value: bucket) in buckets.entries) {
    if (bucket.candidates.length < 2) continue;
    final group = _toGroup(key, bucket.kind, bucket.candidates);
    groups.add(group);
    for (final member in group.members) {
      byProduct[member.product.id] = group;
    }
  }
  return GroupIndex(groups, byProduct);
}

class GroupedRow {
  /// Qator nima bilan ochiladi: ro'yxatda bo'lgan ta'm yoki mahsulotning o'zi.
  final Product product;
  final ProductGroup? group;
  /// Guruhning nechta ta'mi ro'yxatda edi.
  int matched;
  GroupedRow(this.product, this.group, this.matched);
}

/// Ro'yxatda har guruh bir marta — birinchi ta'mi turgan joyda.
List<GroupedRow> groupWithMatches(List<Product> list, GroupIndex index) {
  final inList = {for (final p in list) p.id};
  final rows = <Object, GroupedRow>{};
  for (final product in list) {
    final group = index.byProduct[product.id];
    final existing = group == null ? null : rows[group];
    if (existing != null) {
      existing.matched++;
    } else {
      final lead = group?.members.where((m) => inList.contains(m.product.id)).firstOrNull?.product ?? product;
      rows[group ?? product] = GroupedRow(lead, group, 1);
    }
  }
  return rows.values.toList();
}

/// To'r ko'rsatadigan mahsulotlar: har guruhdan bittadan, qolganlari o'zicha.
List<Product> collapseGroups(List<Product> list, GroupIndex index) =>
    [for (final row in groupWithMatches(list, index)) row.product];

/// Har tanlovga bitta a'zo: guruh sanaydigan va ko'rsatadigani. Uch o'lchamda sotiladigan hid — bitta hid.
List<GroupMember> groupChoices(ProductGroup group) {
  if (group.sizes.isEmpty) return group.members;
  final seen = <String>{};
  return [for (final m in group.members) if (seen.add(m.label)) m];
}

/// Ta'm kartadan qanday olinadi: asosiy birligida.
BuyOption? memberOption(Product product) {
  final options = productOptions(product);
  return options.where((o) => o.multiplier == 1).firstOrNull ?? options.firstOrNull;
}

/// Guruh kartasidagi narx: omborda bor eng arzon ta'mdan, har valyutada.
List<PriceGroup> groupPriceGroups(ProductGroup group) =>
    cheapestByCurrency([for (final m in group.members) ?memberOption(m.product)]);
