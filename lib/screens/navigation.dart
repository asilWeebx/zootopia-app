// Ilova bo'ylab o'tishlar. To'rt tab (Asosiy, Hisoblash, Savat, Kabinet) —
// har biri o'z sahifasi, almashganda holatini saqlaydi. Katalog Asosiy tab
// ichida ochiladi (pastki menyu ko'rinib turadi, orqaga — bosh sahifaga).
// Mahsulot, rasmiylashtirish, maxfiylik va kabinet bo'limlari tablar ustida
// ochiladi; boshqa tabga o'tilsa ular yopiladi.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../services/catalog.dart';
import 'account_screen.dart';
import 'catalog_screen.dart';
import 'checkout_screen.dart';
import 'privacy_screen.dart';
import 'product_screen.dart';

enum AppTab { home, calculator, cart, account }

final navigatorKey = GlobalKey<NavigatorState>();

/// Asosiy tabning o'z navigatori: bosh sahifa va uning ustidagi katalog.
final homeNavigatorKey = GlobalKey<NavigatorState>();

/// Ochiq tab — pastki menyu va tablar qatlami shunga qaraydi.
final currentTab = ValueNotifier<AppTab>(AppTab.home);

/// "Asosiy" bosh sahifada qayta bosilsa — tepaga aylantirish uchun.
final homeScrollTop = ValueNotifier<int>(0);

/// Yangi ilova (va har test) bosh sahifadan boshlanadi.
void resetNavigation() => currentTab.value = AppTab.home;

NavigatorState get _nav => navigatorKey.currentState!;

Route<T> _page<T>(String name, WidgetBuilder builder) =>
    MaterialPageRoute<T>(settings: RouteSettings(name: name), builder: builder);

/// Tablar ustidagi sahifalarni yopib, tabni ko'rsatadi.
void showTab(AppTab tab) {
  _nav.popUntil((route) => route.isFirst);
  currentTab.value = tab;
}

void goHome() {
  final home = homeNavigatorKey.currentState;
  if (currentTab.value == AppTab.home && !_nav.canPop()) {
    if (home != null && home.canPop()) {
      home.popUntil((route) => route.isFirst);
    } else {
      homeScrollTop.value++;
    }
    return;
  }
  showTab(AppTab.home);
}

/// Katalog sahifasi (`/catalog?pet=cat`) Asosiy tab ichida. [focusSearch] —
/// qidiruv maydoni klaviatura bilan ochiladi. Ustida katalog bo'lsa — almashtiradi.
void openCatalogPage([CatalogFilters filters = const CatalogFilters(), bool focusSearch = false]) {
  showTab(AppTab.home);
  final home = homeNavigatorKey.currentState;
  if (home == null) return;
  final route = _page<void>('/catalog', (_) => CatalogScreen(initial: filters, focusSearch: focusSearch));
  var onCatalog = false;
  home.popUntil((r) {
    onCatalog = r.settings.name == '/catalog';
    return true;
  });
  if (onCatalog) {
    home.pushReplacement(route);
  } else {
    home.push(route);
  }
}

/// Qidiruv — katalogning o'z maydoni, klaviatura ochilgan holda.
void openSearch() => openCatalogPage(const CatalogFilters(), true);

/// [optionKey] berilsa sahifa o'sha variant tanlangan holda ochiladi (`/product/9201?o=v501`).
void openProduct(Product p, {String? optionKey}) => openProductId(p.id, optionKey: optionKey);

void openProductId(int id, {String? optionKey}) =>
    _nav.push(_page('/product', (_) => ProductScreen(productId: id, initialOption: optionKey)));

void openCalculator() => showTab(AppTab.calculator);
void openAccount() => showTab(AppTab.account);
void openCartPage() => showTab(AppTab.cart);
void openCheckout() => _nav.push(_page('/checkout', (_) => const CheckoutScreen()));
void openPrivacy() => _nav.push(_page('/privacy', (_) => const PrivacyScreen()));

/// Kabinetning "Xaridlar", "Buyurtmalar", "To'lovlar" bo'limlari — kabinet yuklagan ma'lumot bilan.
void openAccountSection(AccountSection section, CustomerAccount data) =>
    _nav.push(_page('/account/${section.name}', (_) => AccountSectionScreen(section: section, data: data)));

/// "Orqaga": oldingi sahifa bo'lsa unga, aks holda `fallback`ga.
void goBack(VoidCallback fallback) {
  if (_nav.canPop()) {
    _nav.pop();
  } else {
    fallback();
  }
}

/// Telefon, email va tashqi havolalar.
Future<void> openExternal(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    // Qurilmada mos ilova yo'q — jim qoladi.
  }
}
