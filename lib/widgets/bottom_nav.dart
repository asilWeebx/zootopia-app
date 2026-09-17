import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Zootopiya pastki menyu — rasmdagidek 5 ta tab (to'liq kenglikdagi oq panel).
class BottomNav extends StatelessWidget {
  final int active;        // 0 = Bosh sahifa, 3 = Sevimlilar (doimiy rejimlar)
  final int cartCount;
  final int favCount;
  final ValueChanged<int> onTap;
  const BottomNav({super.key, required this.active, required this.cartCount,
    this.favCount = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        border: const Border(top: BorderSide(color: kBorder, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 18, offset: const Offset(0, -3))],
      ),
      padding: EdgeInsets.only(top: 9, left: 6, right: 6, bottom: 8 + bottomPad),
      child: Row(
        children: [
          _NavBtn(icon: Icons.home_rounded,          label: 'Bosh sahifa', idx: 0, active: active, onTap: onTap),
          _NavBtn(icon: Icons.grid_view_rounded,     label: 'Katalog',     idx: 1, active: active, onTap: onTap),
          _NavBtn(icon: Icons.shopping_cart_rounded, label: 'Savatcha',    idx: 2, active: active, onTap: onTap, badge: cartCount),
          _NavBtn(icon: Icons.favorite_rounded,      label: 'Sevimlilar',  idx: 3, active: active, onTap: onTap, badge: favCount, badgeGreen: true),
          _NavBtn(icon: Icons.person_rounded,        label: 'Profil',      idx: 4, active: active, onTap: onTap),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final int idx;
  final int active;
  final int badge;
  final bool badgeGreen;
  final ValueChanged<int> onTap;
  const _NavBtn({required this.icon, required this.label, required this.idx,
    required this.active, required this.onTap, this.badge = 0, this.badgeGreen = false});

  @override
  Widget build(BuildContext context) {
    final isActive = idx == active;
    final color = isActive ? kAccent : kTextMuted;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(idx),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Icon(icon, size: 24, color: color),
            if (badge > 0)
              Positioned(
                top: -5, right: -8,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16, padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: badgeGreen ? kRed : const Color(0xFFE0912A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kSurface, width: 1.5),
                  ),
                  child: Center(child: Text(badge > 9 ? '9+' : '$badge',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
                ),
              ),
          ]),
          const SizedBox(height: 4),
          Text(label, maxLines: 1, overflow: TextOverflow.visible,
            style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: color)),
        ]),
      ),
    );
  }
}
