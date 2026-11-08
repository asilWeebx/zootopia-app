import 'package:flutter/foundation.dart' show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/store.dart';
import 'config/theme.dart';
import 'l10n/strings.dart';
import 'screens/navigation.dart';
import 'screens/shell.dart';
import 'services/push_service.dart';
import 'services/storage.dart';
import 'state/cart_controller.dart';
import 'state/catalog_controller.dart';
import 'state/feeding_controller.dart';
import 'state/scope.dart';
import 'widgets/layout/cart_feedback.dart';
import 'widgets/layout/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  // Shriftlar ilova ichida — litsenziyalari "Litsenziyalar" ro'yxatiga qo'shiladi.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Nunito'], await rootBundle.loadString('assets/fonts/OFL-Nunito.txt'));
    yield LicenseEntryWithLineBreaks(['Onest'], await rootBundle.loadString('assets/fonts/OFL-Onest.txt'));
  });
  // Push init — bloklamaydi (Firebase sozlanmagan bo'lsa jimgina o'chiq).
  StorePushService.instance.init();
  // Til birinchi kadrdan to'g'ri bo'lsin (ochilish shiori ham).
  appLang.value = await Storage.loadLang();
  runApp(buildApp());
}

/// Holat manbalarini yaratib, yuklashni boshlaydi (push'siz — uni `main` ulaydi).
/// `splash: false` — testlarda ochilish animatsiyasisiz.
ZootopiyaApp buildApp({bool splash = true}) {
  resetNavigation();
  final catalog = CatalogController();
  final cart = CartController(products: () => catalog.products);
  final feeding = FeedingController();
  final haptics = HapticsPreference();
  // Yangi katalog kelganda savat narx va qoldiq bo'yicha qayta tekshiriladi.
  catalog.addListener(() {
    if (cart.ready && !catalog.loading) cart.syncProducts();
  });
  cart.load();
  feeding.load();
  Storage.loadHaptics().then((v) => haptics.value = v);
  catalog.init();
  return ZootopiyaApp(catalog: catalog, cart: cart, feeding: feeding, haptics: haptics, splash: splash);
}

class ZootopiyaApp extends StatefulWidget {
  final CatalogController catalog;
  final CartController cart;
  final FeedingController feeding;
  final HapticsPreference haptics;
  final bool splash;
  const ZootopiyaApp({super.key, required this.catalog, required this.cart, required this.feeding, required this.haptics, this.splash = true});

  @override
  State<ZootopiyaApp> createState() => _ZootopiyaAppState();
}

class _ZootopiyaAppState extends State<ZootopiyaApp> {
  @override
  void initState() {
    super.initState();
    appLang.addListener(_onLang);
  }

  @override
  void dispose() {
    appLang.removeListener(_onLang);
    super.dispose();
  }

  /// Til almashdi: katalog yorliqlari va savat qatorlarining birliklari yangi
  /// tilda quriladi, keyin har bir vidjet qayta chiziladi — ochiq tab, katalog
  /// va sahifalar o'z joyida qoladi.
  void _onLang() {
    widget.catalog.relabel();
    if (widget.cart.ready) widget.cart.syncProducts();
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    final ZootopiyaApp(:catalog, :cart, :feeding, :haptics, :splash) = widget;
    return Scope<CatalogController>(
      value: catalog,
      child: Scope<CartController>(
        value: cart,
        child: Scope<FeedingController>(
          value: feeding,
          child: Scope<HapticsPreference>(
            value: haptics,
            child: MaterialApp(
              title: Brand.name,
              debugShowCheckedModeBanner: false,
              theme: buildTheme(),
              navigatorKey: navigatorKey,
              home: const AppShell(),
              // Juda katta tizim shrifti kartalarni sindirmasin.
              builder: (context, child) {
                final media = MediaQuery.of(context);
                return MediaQuery(
                  data: media.copyWith(textScaler: media.textScaler.clamp(maxScaleFactor: 1.2)),
                  child: Stack(
                    children: [
                      child!,
                      const Positioned.fill(child: PawLayer()),
                      if (splash) const Positioned.fill(child: SplashOverlay()),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
