import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../widgets/layout/mobile_nav.dart';
import 'account_screen.dart';
import 'calculator_screen.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'navigation.dart';

/// Tablar qatlami: har tab o'z sahifasi — birinchi ochilganda quriladi va
/// holatini saqlaydi, almashganda yangisi yengil paydo bo'ladi. Asosiy tabda
/// o'z navigatori bor — katalog uning ustida, pastki menyu ko'rinib turadi.
/// Android'dagi "orqaga": katalogdan bosh sahifaga, boshqa tabdan Asosiyga,
/// keyin ilovadan chiqadi.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  final _visited = <AppTab>{currentTab.value};
  late final _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 220), value: 1);

  @override
  void initState() {
    super.initState();
    currentTab.addListener(_onTab);
  }

  @override
  void dispose() {
    currentTab.removeListener(_onTab);
    _fade.dispose();
    super.dispose();
  }

  void _onTab() {
    // Yashirin tabdagi maydon klaviaturani ushlab qolmasin.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _visited.add(currentTab.value));
    if (!MediaQuery.of(context).disableAnimations) _fade.forward(from: 0);
  }

  Widget _tab(AppTab tab) => switch (tab) {
        AppTab.home => _HomeTab(enabled: currentTab.value == AppTab.home),
        AppTab.calculator => const CalculatorScreen(),
        AppTab.cart => const CartScreen(),
        AppTab.account => const AccountScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final current = currentTab.value;
    final media = MediaQuery.of(context);
    final showNav = media.viewInsets.bottom == 0;
    final fade = CurvedAnimation(parent: _fade, curve: kEase);
    return PopScope(
      canPop: current == AppTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && currentTab.value != AppTab.home) currentTab.value = AppTab.home;
      },
      child: ColoredBox(
        color: kBg,
        child: Stack(
          children: [
            Positioned.fill(
              child: FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, .012), end: Offset.zero).animate(fade),
                  child: IndexedStack(
                    index: current.index,
                    children: [
                      for (final tab in AppTab.values)
                        _visited.contains(tab) ? TickerMode(enabled: tab == current, child: _tab(tab)) : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: kSpace3,
              right: kSpace3,
              bottom: kSpace2 + media.padding.bottom,
              child: IgnorePointer(
                ignoring: !showNav,
                child: AnimatedSlide(
                  offset: showNav ? Offset.zero : const Offset(0, 1.6),
                  duration: const Duration(milliseconds: 240),
                  curve: kEase,
                  child: AnimatedOpacity(
                    opacity: showNav ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Material(type: MaterialType.transparency, child: MobileNav()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asosiy tab: bosh sahifa va ustida ochiladigan katalog — o'z navigatori bilan.
class _HomeTab extends StatelessWidget {
  /// Faqat ko'rinib turganda "orqaga" katalogni yopadi.
  final bool enabled;
  const _HomeTab({required this.enabled});

  @override
  Widget build(BuildContext context) => NavigatorPopHandler(
        enabled: enabled,
        onPopWithResult: (_) => homeNavigatorKey.currentState?.maybePop(),
        child: Navigator(
          key: homeNavigatorKey,
          onGenerateInitialRoutes: (_, _) => [
            MaterialPageRoute<void>(settings: const RouteSettings(name: '/'), builder: (_) => const HomeScreen()),
          ],
        ),
      );
}
