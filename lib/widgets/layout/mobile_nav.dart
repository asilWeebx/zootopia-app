import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../config/theme.dart';
import '../../l10n/strings.dart';
import '../../screens/navigation.dart';
import '../../state/scope.dart';
import 'cart_feedback.dart';
import 'page.dart';

class _Item {
  final AppTab tab;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _Item(this.tab, this.label, this.icon, this.activeIcon);
}

List<_Item> get _items => [
      _Item(AppTab.home, tr.navHome, LucideIcons.house300, LucideIcons.house),
      _Item(AppTab.calculator, tr.navCalculator, LucideIcons.calculator300, LucideIcons.calculator),
      _Item(AppTab.cart, tr.navCart, LucideIcons.shoppingBasket300, LucideIcons.shoppingBasket),
      _Item(AppTab.account, tr.navAccount, LucideIcons.user300, LucideIcons.user),
    ];

void _onTap(AppTab tab) {
  if (tab == AppTab.home) {
    goHome();
  } else {
    showTab(tab);
  }
}

/// Pastki suzuvchi menyu: to'q yashil tabletka, ochiq tab xantal fonda nomi
/// bilan, qolganlari faqat belgi.
class MobileNav extends StatelessWidget {
  const MobileNav({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.cart;
    return ValueListenableBuilder<AppTab>(
      valueListenable: currentTab,
      builder: (context, current, _) => Container(
        height: kMobileNavHeight,
        padding: const EdgeInsets.all(kSpace2),
        decoration: BoxDecoration(
          color: kDark,
          borderRadius: BorderRadius.circular(kRadiusXl),
          boxShadow: const [BoxShadow(color: Color(0x421F2B24), blurRadius: 30, offset: Offset(0, 10))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, item) in _items.indexed) ...[
              if (i > 0) const SizedBox(width: kSpace1),
              Expanded(
                flex: item.tab == current ? 19 : 10,
                child: _NavButton(
                  item: item,
                  active: item.tab == current,
                  badge: item.tab == AppTab.cart && cart.ready ? cart.count : 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _Item item;
  final bool active;
  final int badge;
  const _NavButton({required this.item, required this.active, required this.badge});

  @override
  Widget build(BuildContext context) {
    final color = active ? kOnSun : kOnDark;
    Widget icon = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(active ? item.activeIcon : item.icon, size: 22, color: color),
        if (badge > 0) Positioned(top: -7, right: -10, child: CountBadge(badge, border: active ? kSun : kDark)),
      ],
    );
    if (item.tab == AppTab.cart) icon = CartTarget(child: BouncingCartIcon(child: icon));
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTap(item.tab),
        child: AnimatedContainer(
          duration: kDuration,
          curve: kEase,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(color: active ? kSun : Colors.transparent, borderRadius: BorderRadius.circular(22)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              if (active) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(item.label, maxLines: 1, style: display(13.5, weight: FontWeight.w800, color: kOnSun, height: 1.2)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
