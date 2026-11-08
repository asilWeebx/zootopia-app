import 'package:flutter/widgets.dart';

import 'cart_controller.dart';
import 'catalog_controller.dart';
import 'feeding_controller.dart';

/// Bitta holat manbasini daraxtga beradi; `of` — o'zgarganda qayta chiziladi,
/// `read` — faqat amal uchun (tinglamaydi).
class Scope<T extends Listenable> extends InheritedNotifier<T> {
  const Scope({super.key, required T value, required super.child}) : super(notifier: value);

  static T of<T extends Listenable>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Scope<T>>()!.notifier!;

  static T read<T extends Listenable>(BuildContext context) =>
      context.getInheritedWidgetOfExactType<Scope<T>>()!.notifier!;
}

/// Savatga qo'shishda telefon tebransinmi (Kabinetda yoqiladi).
class HapticsPreference extends ValueNotifier<bool> {
  HapticsPreference() : super(false);
}

extension ScopeContext on BuildContext {
  CatalogController get catalog => Scope.of<CatalogController>(this);
  CartController get cart => Scope.of<CartController>(this);
  FeedingController get feeding => Scope.of<FeedingController>(this);
  HapticsPreference get haptics => Scope.of<HapticsPreference>(this);

  CatalogController get readCatalog => Scope.read<CatalogController>(this);
  CartController get readCart => Scope.read<CartController>(this);
  FeedingController get readFeeding => Scope.read<FeedingController>(this);
  HapticsPreference get readHaptics => Scope.read<HapticsPreference>(this);
}
