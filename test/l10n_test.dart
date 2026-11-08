// Rus tili (ilovaning sukut tili) va til almashganda saqlangan ma'lumotlar.
import 'package:flutter_test/flutter_test.dart';
import 'package:online_store_app/config/groups.dart';
import 'package:online_store_app/l10n/strings.dart';
import 'package:online_store_app/models/models.dart';
import 'package:online_store_app/services/cart_lines.dart';
import 'package:online_store_app/services/catalog.dart';
import 'package:online_store_app/services/currency.dart';
import 'package:online_store_app/services/options.dart';
import 'package:online_store_app/services/pack.dart';
import 'package:online_store_app/services/specs.dart';
import 'package:online_store_app/services/storage.dart';
import 'package:online_store_app/services/units.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';

Product _forCats(int id, String name, String section) => product(
      id: id,
      name: name,
      categoryId: 803,
      categoryName: section,
      categoryParentId: 573,
      categoryParentName: 'Для Кошек',
      units: [unit('Dona', 5000)],
    );

void main() {
  setUp(() => appLang.value = AppLang.ru);

  test('Russian is the default until the customer picks Uzbek', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await Storage.loadLang(), AppLang.ru);
    await Storage.saveLang(AppLang.uz);
    expect(await Storage.loadLang(), AppLang.uz);
  });

  test('Russian counts take the right plural', () {
    expect([1, 2, 5, 11, 21, 22].map(tr.products), ['1 товар', '2 товара', '5 товаров', '11 товаров', '21 товар', '22 товара']);
    expect(tr.groupCount(GroupKind.flavour, 28), '28 вкусов');
    expect(tr.groupCount(GroupKind.flavour, 4), '4 вкуса');
    expect(tr.lines(3), '3 позиции');
    expect(tr.hintLasts('1 кг', 13), '1 кг ≈ на 13 дней');
  });

  test('units, money and starting prices follow the language', () {
    expect(unitLabel('Dona'), 'шт');
    expect(unitLabel('Kilogram'), 'кг');
    expect(som(50000), '50 000 сум');
    expect(tr.priceFrom(som(5000), true), 'от 5 000 сум');
    expect(formatGrams(80), '80 г');
    expect(formatGrams(1500), '1.5 кг');

    appLang.value = AppLang.uz;
    expect(unitLabel('Dona'), 'dona');
    expect(som(50000), "50 000 so'm");
    expect(tr.priceFrom(som(5000), true), "5 000 so'mdan");
    expect(formatGrams(80), '80 g');
  });

  test('a unit saved in either language is recognised', () {
    for (final (saved, kind) in [
      ('dona', UnitKind.piece),
      ('шт', UnitKind.piece),
      ('kg', UnitKind.kg),
      ('кг', UnitKind.kg),
      ('quti', UnitKind.pack),
      ('уп.', UnitKind.pack),
      ('qop', UnitKind.bag),
      ('мешок', UnitKind.bag),
      ('м', UnitKind.m),
    ]) {
      expect(unitKind(saved), kind, reason: saved);
    }
    expect(isWeighed('кг'), true);
  });

  test('stock-keeping categories, the catch-all and the facts are in Russian', () {
    final products = normalizeCategories(relabelCategories([
      product(id: 1, name: 'Royal Canin 2kg'),
      piece(id: 2, name: 'Игрушка'),
      product(id: 3, name: 'Без раздела', categoryId: null, categoryName: null),
    ]));
    expect(buildCategories(products).map((c) => c.name), ['Поштучно', 'На развес', 'Другие товары']);

    final felix = _forCats(60, 'Felix Кролик в Желе 75гр', 'Влажный корм');
    final specs = productSpecs(felix, productOptions(felix).first);
    expect(specs.map((row) => row.label), ['Для кого', 'Раздел', 'Продажа', 'Фасовка', 'Артикул']);
    expect(specs.first.value, 'Кошки');
    expect(specs[2].value, 'Поштучно (шт)');
  });

  test('search understands both languages whatever the app speaks', () {
    final whiskas = _forCats(70, 'Whiskas паштет 85гр', 'Влажный корм');
    for (final lang in AppLang.values) {
      appLang.value = lang;
      for (final query in ['кошки', 'mushuk', 'влажный корм', 'nam ozuqa']) {
        expect(matchesSearch(whiskas, query), true, reason: '$lang: $query');
      }
    }
  });

  test('cart lines take the new language when the catalogue is rebuilt', () {
    appLang.value = AppLang.uz;
    final food = product(id: 80, name: 'Royal Canin Indoor', units: [unit('Kilogram', 140000)]);
    final cart = addLine(const [], food, productOptions(food).first, 1.5);
    expect(cart.single.unit, 'kg');

    appLang.value = AppLang.ru;
    final again = product(id: 80, name: 'Royal Canin Indoor', units: [unit('Kilogram', 140000)]);
    final relabelled = revalidateCart(cart, [again]);
    expect(relabelled.single.unit, 'кг');
    expect(weighedKg(relabelled), 1.5);
    expect(weighedKg(cart), 1.5);
  });

  test('order problems are reported in Russian', () {
    final last = product(id: 90, name: 'Proplan', stock: 1);
    expect(stockProblems(const [OrderItemPayload(productId: 90, qty: 1.5)], [last]).single, 'Proplan: в наличии 1 кг, а в заказе 1.5 кг');
    expect(
      stockProblems(const [OrderItemPayload(productId: 1, qty: 1)], [product(id: 1, name: 'X', stock: 0, inStock: false)]).single,
      'X: нет в наличии',
    );
  });
}
