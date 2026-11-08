import '../config/catalog.dart';
import '../config/pets.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import 'options.dart';
import 'pack.dart';
import 'units.dart';

/// Mahsulot turgan ERP bo'limi, ustidagi bo'lim bilan.
String _sectionOf(Product p) =>
    [p.categoryParentName, p.categoryName].whereType<String>().where((s) => s.isNotEmpty).join(' ');

List<PetId> petsNamedIn(String text) => [
      for (final pet in kPets)
        if (pet.match.hasMatch(text) || (pet.addressed?.hasMatch(text) ?? false)) pet.id,
    ];

ProductTypeId? _kindNamedIn(String text) => kProductTypes.where((t) => t.match.hasMatch(text)).firstOrNull?.id;

final _petsCache = Expando<List<PetId>>();

/// Mahsulot kimlar uchun ("для кошек и собак" — ikkalasi). Nomda ochiq
/// aytilgan hayvon birinchi — noto'g'ri bo'limga qo'yilgan molni ham topadi
/// ("REFLEX для собак" "Для Кошек" ostida). Aks holda ERP bo'limi hal qiladi,
/// keyin faqat bir hayvonga ozuqa qiladigan brend.
List<PetId> productPets(Product p) => _petsCache[p] ??= () {
      final named = petsNamedIn(p.name);
      if (named.isNotEmpty) return named;
      final inSection = petsNamedIn(_sectionOf(p));
      if (inSection.isNotEmpty) return inSection;
      return [for (final pet in kPets) if (pet.brands?.hasMatch(p.name) ?? false) pet.id];
    }();

final _typeCache = Expando<(ProductTypeId?,)>();

/// Quruq ozuqa, pauch, vitamin... Avval ERP bo'limi aytadi ("Влажный корм"),
/// keyin nom. Ikkalasi ham aytmasa: tortib sotiladigan ochiq mahsulot — ozuqa,
/// nomida og'irligi bor hayvon qadog'i ham ("Pedigree для взрослых собак 2 кг").
ProductTypeId? productType(Product p) => (_typeCache[p] ??= (() {
      final section = _sectionOf(p);
      final exactSection = kGenericFoodSection.hasMatch(p.categoryName ?? '') ? null : _kindNamedIn(section);
      final found = exactSection ?? _kindNamedIn(p.name) ?? _kindNamedIn(section);
      if (found != null) return found;
      if (kNotFood.hasMatch('$section ${p.name}')) return null;
      if (isWeighed(baseUnit(p)?.unitName)) return ProductTypeId.dry;
      final pack = packGrams(p.name);
      return pack != null && pack >= 200 && productPets(p).isNotEmpty ? ProductTypeId.dry : null;
    }(),)).$1;

enum LifeStage { young, adult, senior }

/// Mushukcha/kuchukcha ozuqasi — young, 7+ — senior, nomda aytilgan bo'lsa
/// adult, aks holda null (istalgan katta hayvon). [name] — mahsulot nomi,
/// variantniki bilan.
LifeStage? lifeStage(String name) {
  if (kLifeStageAnyAge.hasMatch(name)) return null;
  if (kLifeStageYoung.hasMatch(name)) return LifeStage.young;
  if (kLifeStageSenior.hasMatch(name)) return LifeStage.senior;
  if (kLifeStageAdult.hasMatch(name)) return LifeStage.adult;
  return null;
}

/// Sterilizatsiya qilingan hayvon ozuqasi.
bool isSterilizedFood(String name) => kSterilizedWords.hasMatch(name);

/// Mahsulot qaysi hayvon bilan ko'rsatiladi (foni va belgisi): birinchi nomlangani.
PetId primaryPet(Product p) {
  final pets = productPets(p);
  return pets.isEmpty ? PetId.other : pets.first;
}

bool matchesPet(Product p, PetId pet) {
  final pets = productPets(p);
  return pet == PetId.other ? pets.isEmpty : pets.contains(pet);
}

PetDef? findPet(PetId? id) => kPets.where((pet) => pet.id == id).firstOrNull;

ProductTypeDef? findProductType(ProductTypeId? id) => kProductTypes.where((t) => t.id == id).firstOrNull;

/// "Mushuklar" / "Кошки" — joriy tilda.
String petLabel(PetId id) => tr.petLabel(id);

/// "Mushuklar uchun" / "Для кошек".
String petForLabel(PetId id) => tr.petForLabel(id);

/// "Quruq ozuqa" / "Сухой корм".
String typeLabel(ProductTypeId id) => tr.types[id]!;

class PetGroup {
  final PetId id;
  final String label;
  final String forLabel;
  final int count;
  final int available;
  const PetGroup({required this.id, required this.label, required this.forLabel, required this.count, required this.available});
}

/// Katalogda mahsuloti bor hayvonlar, `kPets` tartibida, keyin "Boshqalar".
/// Mahsulotsiz hayvon chiqmaydi — bo'sh "Baliqlar" javoni bo'lmaydi.
List<PetGroup> petGroups(List<Product> products) {
  final groups = <PetGroup>[];
  for (final id in [for (final pet in kPets) pet.id, PetId.other]) {
    final items = products.where((p) => matchesPet(p, id)).toList();
    if (items.isEmpty) continue;
    groups.add(PetGroup(
      id: id,
      label: petLabel(id),
      forLabel: petForLabel(id),
      count: items.length,
      available: items.where((p) => !isOutOfStock(p)).length,
    ));
  }
  return groups;
}

class TypeGroup {
  final ProductTypeId id;
  final String label;
  final int count;
  const TypeGroup(this.id, this.label, this.count);
}

/// `products`dagi mahsulot turlari, ular kelgan ERP bo'limlari tartibida
/// (`buildCategories` kabi). Faqat nomdan topilgan turlar oxirida.
/// `kProductTypes` tartibi — moslash navbati, ko'rsatish uchun emas.
List<TypeGroup> typeGroups(List<Product> products) {
  final counts = <ProductTypeId, int>{};
  final firstSection = <ProductTypeId, int>{};
  for (final p in products) {
    final type = productType(p);
    if (type == null) continue;
    counts[type] = (counts[type] ?? 0) + 1;
    final name = p.categoryName;
    if (name != null && name.isNotEmpty && _kindNamedIn(_sectionOf(p)) == type) {
      final rank = categoryRank(name);
      final seen = firstSection[type];
      firstSection[type] = seen == null || rank < seen ? rank : seen;
    }
  }
  int rank(ProductTypeId id) => firstSection[id] ?? 1 << 30;
  final present = kProductTypes.where((t) => counts.containsKey(t.id)).toList();
  final indexed = present.indexed.toList()
    ..sort((a, b) {
      final c = rank(a.$2.id) - rank(b.$2.id);
      return c != 0 ? c : a.$1 - b.$1;
    });
  return [for (final (_, t) in indexed) TypeGroup(t.id, typeLabel(t.id), counts[t.id]!)];
}
