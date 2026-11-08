// Saytdagi `tests/groups.test.ts` — ta'mlar ilovada ham saytdagidek birlashishi kerak.
import 'package:flutter_test/flutter_test.dart';
import 'package:online_store_app/config/groups.dart';
import 'package:online_store_app/l10n/strings.dart';
import 'package:online_store_app/models/models.dart';
import 'package:online_store_app/services/catalog.dart';
import 'package:online_store_app/services/groups.dart';

import 'fixtures.dart';

// Nomlar va bo'limlar jonli Zootopia katalogidan (2026-11-07).
typedef Section = ({int id, String name, int? parentId, String? parentName});
const Section wetCat = (id: 601, name: 'Влажный корм', parentId: 573, parentName: 'Для Кошек');
const Section wetDog = (id: 701, name: 'Влажный корм', parentId: 574, parentName: 'Для Собак');
const Section dryCat = (id: 602, name: 'Сухой корм', parentId: 573, parentName: 'Для Кошек');
const Section treats = (id: 603, name: 'Лакомства', parentId: 573, parentName: 'Для Кошек');
const Section litter = (id: 604, name: 'Наполнители', parentId: 573, parentName: 'Для Кошек');
const Section canned = (id: 605, name: 'Консерва', parentId: 573, parentName: 'Для Кошек');
const Section aquarium = (id: 580, name: 'Аквариум', parentId: null, parentName: null);

var _nextId = 1000;

Product item(String name, Section section, {List<ProductUnit>? units, double stock = 100, bool inStock = true, bool hasVariants = false, List<ProductVariant> variants = const []}) =>
    product(
      id: _nextId++,
      name: name,
      categoryId: section.id,
      categoryName: section.name,
      categoryParentId: section.parentId,
      categoryParentName: section.parentName,
      units: units ?? [unit('Dona', 5000)],
      stock: stock,
      inStock: inStock,
      hasVariants: hasVariants,
      variants: variants,
    );

ProductGroup? groupOf(List<Product> products, String name) {
  final found = products.firstWhere((p) => p.name == name);
  return buildGroups(products).byProduct[found.id];
}

List<String>? labels(ProductGroup? group) => group?.members.map((m) => m.label).toList();

void main() {
  // Bu fayldagi kutilgan so'zlar o'zbekcha; rus tili — l10n_test.dart.
  setUp(() => appLang.value = AppLang.uz);

  test('flavours of one brand, section and pack size become one product', () {
    final meow = [item('Мяу с Рыбой в Соусе 85гр', wetCat), item('Мяу Индейка в Соусе 85гр', wetCat), item('Мяу Индейка для стерил. 85гр', wetCat), item('Мяу с Говядиной и овощами 85гр', wetCat)];
    final group = groupOf(meow, 'Мяу с Рыбой в Соусе 85гр');
    expect(group?.title, 'Мяу 85гр');
    expect(group?.kind, GroupKind.flavour);
    expect(labels(group), ['Индейка в соусе', 'Индейка для стерил.', 'С говядиной и овощами', 'С рыбой в соусе']);
    expect(group?.sizes, isEmpty);
  });

  test('a lone product stays a product', () {
    final products = [item('JESSY консерва с курицей для кошек 400гр', canned), item('Мяу Печень в Соусе 85гр', wetCat)];
    expect(buildGroups(products).groups, isEmpty);
  });

  test('different pack sizes stay apart in food', () {
    final products = [item('Felix Говядина в Желе 75гр', wetCat), item('Felix Курица в Желе 75гр', wetCat), item('Felix Суп с Говядиной 48гр', wetCat), item('Felix Суп с Курицей 48гр', wetCat), item('Felix Утка с Ломтиками', wetCat)];
    final index = buildGroups(products);
    expect(index.groups.map((g) => g.title).toList()..sort(), ['Felix 75гр', 'Felix Суп 48гр']);
    expect(index.byProduct[products[4].id], null);
  });

  test('the same section name under another pet is another section', () {
    final products = [item('Club 4 Paws Курица в Соусе 85гр', wetCat), item('Club 4 Paws Лосось в Желе 85гр', wetDog)];
    expect(buildGroups(products).groups, isEmpty);
  });

  test('only food and litter sections combine', () {
    final products = [item('Фильтр WP-850F', aquarium), item('Фильтр WP-950F', aquarium), item('Компрессор WP-200D', aquarium), item('Компрессор WP-400D', aquarium)];
    expect(buildGroups(products).groups, isEmpty);
  });

  test('loose and packed food never mix', () {
    final kg = [unit('Kilogram', 90000)];
    final products = [item('Вискас для кошек с Говядиной', dryCat, units: kg), item('Вискас для кошек с Курицей', dryCat, units: kg), item('Вискас Лосось', dryCat), item('Вискас Индейка', dryCat)];
    final groups = buildGroups(products).groups;
    expect(groups.length, 2);
    expect(groups.firstWhere((g) => g.members.length == 2 && g.members.first.product.units.first.unitName == 'Kilogram').kind, GroupKind.type);
  });

  test('brand spellings and ERP typos land in one group', () {
    final fit = [item('Perfect Fit Лосось в соусе 75гр', wetCat), item('Perfect Индейка Паштет для стерил. 75гр', wetCat)];
    expect(groupOf(fit, 'Perfect Индейка Паштет для стерил. 75гр')?.title, 'Perfect Fit 75гр');
    expect(labels(groupOf(fit, 'Perfect Индейка Паштет для стерил. 75гр')), ['Индейка паштет для стерил.', 'Лосось в соусе']);

    final plan = [item('PRO PLAN Лосось в Соусе 85гр', wetCat), item('RPO PLAN Ягненок в Желе 85гр', wetCat)];
    expect(groupOf(plan, 'RPO PLAN Ягненок в Желе 85гр')?.title, 'PRO PLAN 85гр');

    final royal = [item('ROYAL CANIN BENGAL', dryCat), item('Royal Canin Fussy', dryCat)];
    expect(groupOf(royal, 'Royal Canin Fussy')?.title, 'Royal Canin');
    expect(labels(groupOf(royal, 'Royal Canin Fussy')), ['Bengal', 'Fussy']);

    final club = [item('Клуб 4 лапы  кролик 300гр', dryCat), item('Клуб 4 Лапы Курица для Кошек 300гр', dryCat)];
    expect(groupOf(club, 'Клуб 4 лапы  кролик 300гр')?.title, 'Клуб 4 Лапы 300гр');
  });

  test('a brand of unrelated goods combines only by named line', () {
    final products = [
      item('GimCat cheezies 50gr', treats),
      item('GimCat Duo pasta anti-hairball 50gr', treats),
      item('GimCat snack cream chicken pollo 6*15gr', treats),
      item('GimCat snack cream duo tuna with grass 6*15gr', treats),
      item('GimCat sticks индейка с кроликом', treats),
      item('GimCat sticks лосось с форельом', treats),
      item('TRIXIE fish chicken rools 50гр', treats),
      item('TRIXIE tuna  sandwiches 50гр', treats),
      item('PREMIO CHICKENMINI STICKS 50gr', treats),
      item('PREMIO DUCK HEARTS 50гр', treats),
    ];
    final groups = buildGroups(products).groups;
    expect(groups.map((g) => g.title).toList()..sort(), ['GimCat Snack Cream 6*15гр', 'GimCat Sticks']);
    expect(labels(groups.firstWhere((g) => g.title == 'GimCat Sticks')), ['Индейка с кроликом', 'Лосось с форельом']);
  });

  test('words every flavour shares move into the title', () {
    final pw = [item('PW консерва для кошек с Говядиной 375гр', canned), item('PW консерва для кошек с курицей 375гр', canned)];
    expect(groupOf(pw, 'PW консерва для кошек с курицей 375гр')?.title, 'PW консерва для кошек 375гр');
    expect(labels(groupOf(pw, 'PW консерва для кошек с курицей 375гр')), ['С говядиной', 'С курицей']);

    // "бентонит"ni ham olsak, oddiysi nomsiz qolardi.
    final delecat = [item('DELECAT наполнитель бентонит 3кг', litter), item('DELECAT наполнитель бентонит зеленый 3кг', litter)];
    expect(groupOf(delecat, 'DELECAT наполнитель бентонит 3кг')?.title, 'DELECAT наполнитель 3кг');
    expect(labels(groupOf(delecat, 'DELECAT наполнитель бентонит 3кг')), ['Бентонит', 'Бентонит зеленый']);
  });

  test('a generic first word is not a brand', () {
    final products = [item('Наполнитель TOFU  GREEN TEA 6L', litter), item('Наполнитель TOFU LAVENDER 6L', litter), item('Наполнитель Noblius Bentonit 5L', litter), item('Наполнитель силикагел', litter)];
    final groups = buildGroups(products).groups;
    expect(groups.length, 1);
    expect(groups.first.title, 'TOFU 6л');
    expect(groups.first.kind, GroupKind.scent);
    expect(labels(groups.first), ['Green tea', 'Lavender']);
  });

  test('litter sold in several sizes gets a second choice', () {
    final proline = [
      item('PROLINE LAVENDER SCENTED 10L', litter),
      item('PROLINE LAVENDER SCENTED 5L', litter),
      item('PROLINE LAVENDER SCENTED 20L', litter),
      item('PROLINE UNSCENTED 5L', litter),
      item('PROLINE ACTIVATED CARBON 10L', litter),
    ];
    final group = groupOf(proline, 'PROLINE UNSCENTED 5L');
    expect(group?.title, 'PROLINE');
    expect(group?.kind, GroupKind.scent);
    expect(group?.sizes.map((s) => s.text), ['5л', '10л', '20л']);
    final lavender5 = group?.members.firstWhere((m) => m.product.name == 'PROLINE LAVENDER SCENTED 5L');
    expect(lavender5?.label, 'Lavender scented');
    expect(lavender5?.size?.amount, 5);
  });

  test('a group counts its choices, not its scent-and-size combinations', () {
    final products = [item('PROLINE LAVENDER SCENTED 5L', litter), item('PROLINE LAVENDER SCENTED 10L', litter), item('PROLINE UNSCENTED 5L', litter)];
    final group = groupOf(products, 'PROLINE UNSCENTED 5L')!;
    expect(groupChoices(group).map((m) => m.label), ['Lavender scented', 'Unscented']);

    final flavours = [item('Мяу Индейка 85гр', wetCat), item('Мяу Печень 85гр', wetCat)];
    expect(groupChoices(groupOf(flavours, 'Мяу Индейка 85гр')!).length, 2);
  });

  test('sold-out flavours go last, the rest alphabetically', () {
    final products = [
      item('Вискас Утка Паштет 75гр', wetCat),
      item('Вискас Кролик Паштет 75гр', wetCat, stock: 0, inStock: false),
      item('Вискас Ёж Паштет 75гр', wetCat),
      item('Вискас Говядина Паштет 75гр', wetCat),
    ];
    expect(labels(groupOf(products, 'Вискас Утка Паштет 75гр')), ['Говядина паштет', 'Ёж паштет', 'Утка паштет', 'Кролик паштет']);
  });

  test('a product with real ERP variants is left alone', () {
    const variant = ProductVariant(id: 1, name: 'Tovuq', price: 5000, curPrice: 5000, stock: 4);
    final products = [item('Sheba Утка 75гр', wetCat, hasVariants: true, variants: [variant]), item('Sheba Курица 75гр', wetCat)];
    expect(buildGroups(products).groups, isEmpty);
  });

  test('a list shows each group once, where its first flavour stood', () {
    final a = item('Мяу Индейка в Соусе 85гр', wetCat);
    final b = item('Мяу Печень в Соусе 85гр', wetCat);
    final lone = item('JESSY консерва с курицей для кошек 400гр', canned);
    final index = buildGroups([a, b, lone]);
    expect(collapseGroups([b, lone, a], index), [a, lone]);
  });

  test('a filtered list leads with a flavour that matched', () {
    final a = item('Мяу Индейка в Соусе 85гр', wetCat);
    final b = item('Мяу Печень в Соусе 85гр', wetCat);
    final index = buildGroups([a, b]);
    expect(collapseGroups([b], index), [b]);
  });

  test('search rows know how many flavours of a group matched', () {
    final a = item('Мяу Индейка в Соусе 85гр', wetCat);
    final b = item('Мяу Печень в Соусе 85гр', wetCat);
    final c = item('Felix Курица в Желе 75гр', wetCat);
    final d = item('Felix Индейка в Желе 75гр', wetCat);
    final index = buildGroups([a, b, c, d]);
    final rows = groupWithMatches([a, b, c], index);
    expect(rows.map((r) => (r.product.id, r.matched)), [(a.id, 2), (c.id, 1)]);
  });

  test("the picker's search forgives word endings and Latin typing", () {
    expect(matchesText('Для котят с курицей в желе', 'курица'), true);
    expect(matchesText('С лососем', 'лосось'), true);
    expect(matchesText('Говядина в соусе', 'govyadina'), true);
    expect(matchesText('Говядина в соусе', 'курица'), false);
    expect(matchesText('Говядина в соусе', '  '), true);
  });

  test("a group's price starts at its cheapest flavour in stock", () {
    final cheap = item('Felix Лосось в Желе 75гр', wetCat, units: [unit('Dona', 5000)]);
    final dear = item('Felix Лосось Паштет 75гр', wetCat, units: [unit('Dona', 6000)]);
    final gone = item('Felix Утка в Желе 75гр', wetCat, units: [unit('Dona', 4000)], stock: 0, inStock: false);
    final group = buildGroups([cheap, dear, gone]).groups.first;
    final price = groupPriceGroups(group).first;
    expect(price.option.curPrice, 5000);
    expect(price.varies, true);

    final same = buildGroups([item('Мяу Индейка 85гр', wetCat), item('Мяу Печень 85гр', wetCat)]).groups.first;
    expect(groupPriceGroups(same).first.varies, false);
  });
}
