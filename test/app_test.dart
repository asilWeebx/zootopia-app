// Ilova qobig'i: tablar, Asosiy ichidagi katalog, Android'dagi "orqaga",
// til almashishi va eng tor telefon (360dp, katta shrift) — biror qator
// sig'masa test yiqiladi. Ilova sukut bo'yicha rus tilida.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:online_store_app/l10n/strings.dart';
import 'package:online_store_app/main.dart';
import 'package:online_store_app/models/models.dart';
import 'package:online_store_app/screens/navigation.dart';
import 'package:online_store_app/services/options.dart';
import 'package:online_store_app/services/storage.dart';
import 'package:online_store_app/state/cart_controller.dart';
import 'package:online_store_app/state/catalog_controller.dart';
import 'package:online_store_app/state/feeding_controller.dart';
import 'package:online_store_app/state/scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';

class _FakeSource implements StoreSource {
  final List<Product> products;
  final List<int> top;
  const _FakeSource(this.products, this.top);

  @override
  Future<StoreInfo> info() async => const StoreInfo(organization: 'Zootopia', store: '');
  @override
  Future<CatalogResponse> catalog(String? customerCode) async => CatalogResponse(results: products);
  @override
  Future<List<int>> topProductIds() async => top;
}

var _id = 5000;

Product _item(String name, {required int categoryId, required String category, int? parentId, String? parent, List<ProductUnit>? units}) => Product(
      id: _id++,
      name: name,
      categoryId: categoryId,
      categoryName: category,
      categoryParentId: parentId,
      categoryParentName: parent,
      stockType: 'tracked',
      stock: 40,
      units: units ?? [unit('Dona', 5000)],
    );

Product _wetCat(String name) => _item(name, categoryId: 803, category: 'Влажный корм', parentId: 573, parent: 'Для Кошек');
Product _canned(String name) => _item(name, categoryId: 813, category: 'Консерва', parentId: 573, parent: 'Для Кошек');

/// Haqiqiy shriftlar — matn eni ilovadagidek bo'lsin.
Future<void> _loadFonts() async {
  for (final (family, files) in [
    ('Nunito', ['Regular', 'SemiBold', 'Bold', 'ExtraBold', 'Black']),
    ('Onest', ['Regular', 'Medium', 'SemiBold', 'Bold']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(rootBundle.load('assets/fonts/$family-$file.ttf'));
    }
    await loader.load();
  }
}

void main() {
  final felix = [
    for (final flavour in ['Кролик в Желе', 'Курица в Желе', 'Лосось в Желе', 'Ягненок в Желе', 'Говядина в Желе', 'Утка в Желе'])
      _wetCat('Felix $flavour 75гр'),
  ];
  final pw = [for (final flavour in ['с Говядиной', 'с Курицей', 'с Лососем', 'с Тунцом']) _canned('PW консерва для кошек $flavour 375гр')];
  final royal = _item('Royal Canin kitten', categoryId: 802, category: 'Сухой корм', parentId: 573, parent: 'Для Кошек', units: [unit('Kilogram', 140000)]);
  final dog = _item('Proplan для собак с курицей', categoryId: 806, category: 'Сухой корм', parentId: 579, parent: 'Для Собак', units: [unit('Kilogram', 90000)]);
  final filter = _item('Фильтр WP-850F', categoryId: 580, category: 'Аквариум', units: [unit('Dona', 70000)]);
  final products = [...felix, ...pw, royal, dog, filter];

  late CatalogController catalog;
  late CartController cart;

  Future<void> pumpApp(WidgetTester tester) async {
    await _loadFonts();
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    resetNavigation();
    appLang.value = AppLang.ru;
    SharedPreferences.setMockInitialValues({});
    catalog = CatalogController(source: _FakeSource(products, [felix.first.id, pw.first.id, royal.id, dog.id, filter.id]), persist: false);
    cart = CartController(products: () => catalog.products, persist: false);
    final feeding = FeedingController(persist: false);
    await cart.load();
    await feeding.load();
    await tester.pumpWidget(ZootopiyaApp(catalog: catalog, cart: cart, feeding: feeding, haptics: HapticsPreference(), splash: false));
    await tester.runAsync(catalog.init);
    await tester.pumpAndSettle();
  }

  testWidgets('home, catalog and back on a 360dp phone with large text', (tester) async {
    await pumpApp(tester);
    // Hayvon plitkalari bor, "Кто у вас дома?" sarlavhasi yo'q.
    expect(find.text('Кто у вас дома?'), findsNothing);
    expect(find.text('Кошки'), findsOneWidget);
    expect(find.text('Рыбки'), findsOneWidget);
    expect(find.text('Хиты продаж'), findsOneWidget);
    expect(find.text('ВЫБОР ПОКУПАТЕЛЕЙ'), findsOneWidget);
    // Oltita Felix — bitta karta.
    expect(find.text('Felix 75гр'), findsWidgets);
    expect(find.text('6 вкусов'), findsWidgets);
    expect(find.text('Выбрать вкус'), findsWidgets);

    // Ta'm tanlash oynasi ruscha so'zlar bilan sig'adi.
    await tester.tap(find.text('Выбрать вкус').first);
    await tester.pumpAndSettle();
    expect(find.text('Вкус · 6 вариантов'), findsOneWidget);
    expect(find.text('Добавить в корзину'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Кошки'));
    await tester.pumpAndSettle();
    expect(find.text('Фильтры'), findsOneWidget);
    expect(find.text('Главная'), findsOneWidget, reason: 'katalogda pastki menyu ko‘rinib turadi');
    expect(find.textContaining('В наличии: '), findsWidgets);

    await tester.tap(find.text('Фильтры'));
    await tester.pumpAndSettle();
    expect(find.text('Сначала дешевле'), findsOneWidget);
    expect(find.text('Только в наличии'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Фильтры'), findsOneWidget, reason: 'oyna yopildi, katalog qoldi');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Фильтры'), findsNothing);
    expect(find.text('Хиты продаж'), findsOneWidget);
  });

  testWidgets('product page picks a flavour; back closes it', (tester) async {
    await pumpApp(tester);
    openProductId(felix[2].id);
    await tester.pumpAndSettle();
    expect(find.text('Felix 75гр'), findsOneWidget);
    expect(find.text('Добавить в корзину'), findsOneWidget);
    expect(find.text('Лосось в желе'), findsOneWidget);
    expect(find.text('В наличии: 40 шт'), findsOneWidget);
    // Narx nom ostida, butun enda: nom narxdan yuqorida.
    expect(tester.getTopLeft(find.text('Felix 75гр')).dy, lessThan(tester.getTopLeft(find.textContaining('5\u00A0000')).dy));

    await tester.tap(find.text('Добавить в корзину'));
    await tester.pumpAndSettle();
    expect(cart.items.single.productId, felix[2].id);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Хиты продаж'), findsOneWidget);
  });

  testWidgets('tabs: back from another tab goes home; a cart line swipes away', (tester) async {
    await pumpApp(tester);
    cart.add(royal, productOptions(royal).first, 1.5);
    cart.add(pw.first, productOptions(pw.first).first, 2);
    showTab(AppTab.cart);
    await tester.pumpAndSettle();
    expect(find.text('Корм на развес'), findsOneWidget);
    expect(find.text('Оформить заказ'), findsOneWidget);

    await tester.drag(find.text('Royal Canin kitten'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(cart.items.map((x) => x.productId), [pw.first.id]);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(currentTab.value, AppTab.home);

    showTab(AppTab.calculator);
    await tester.pumpAndSettle();
    expect(find.text('≈ 72 г'), findsOneWidget);
    expect(find.text('≈ 2,158 кг'), findsOneWidget);

    showTab(AppTab.account);
    await tester.pumpAndSettle();
    expect(find.text('Вход по ID клиента'), findsOneWidget);
  });

  testWidgets('checkout fits in Russian', (tester) async {
    await pumpApp(tester);
    cart.add(royal, productOptions(royal).first, 1.5);
    cart.add(pw.first, productOptions(pw.first).first, 2);
    openCheckout();
    await tester.pumpAndSettle();
    expect(find.text('Оформление заказа'), findsOneWidget);
    expect(find.text('Заберу сам'), findsOneWidget);
    expect(find.text('Наличные'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Подтвердить заказ'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('1.5 кг корма'), findsOneWidget);
  });

  testWidgets('switching to Uzbek in Kabinet relabels every tab without a restart', (tester) async {
    await pumpApp(tester);
    cart.add(royal, productOptions(royal).first, 1.5);
    showTab(AppTab.account);
    await tester.pumpAndSettle();
    expect(find.text('Язык'), findsOneWidget);

    await tester.tap(find.text('O‘zbekcha'));
    await tester.pumpAndSettle();
    expect(appLang.value, AppLang.uz);
    expect(await tester.runAsync(Storage.loadLang), AppLang.uz);
    expect(find.text('Til'), findsOneWidget);
    expect(find.text('Mijoz ID bilan kirish'), findsOneWidget);
    expect(find.text('Kabinet'), findsOneWidget);
    expect(cart.items.single.unit, 'kg', reason: 'savat qatori yangi tilda');

    showTab(AppTab.home);
    await tester.pumpAndSettle();
    expect(find.text('Ko‘p sotilganlar'), findsOneWidget);
    expect(find.text('6 xil ta’m'), findsWidgets);
    expect(find.text('Kimingiz bor?'), findsNothing);
    expect(find.text('Mushuklar'), findsWidgets);

    showTab(AppTab.cart);
    await tester.pumpAndSettle();
    expect(find.text('Tortiladigan ozuqa'), findsOneWidget);

    showTab(AppTab.account);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();
    expect(find.text('Вход по ID клиента'), findsOneWidget);
    expect(cart.items.single.unit, 'кг');
  });
}
