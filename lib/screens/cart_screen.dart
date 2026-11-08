import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/theme.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/cart_lines.dart';
import '../services/currency.dart';
import '../services/units.dart';
import '../state/scope.dart';
import '../widgets/cart/cart_line.dart';
import '../widgets/layout/page.dart';
import '../widgets/ui/basics.dart';
import '../widgets/ui/button.dart';
import 'navigation.dart';

/// "Jami" paneli balandligi (menyu ustida).
const _totalBarHeight = 76.0;

/// Savat (dizayndagi "E · Savat"): tortiladigan ozuqa va donali mahsulotlar
/// alohida guruhda, pastda menyu ustida "Jami" va "Rasmiylashtirish".
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.cart;
    final items = cart.items;
    final media = MediaQuery.of(context);
    final filled = cart.ready && items.isNotEmpty;

    final List<Widget> body;
    if (!cart.ready) {
      body = const [SliverToBoxAdapter(child: Gutter(child: Pulse(child: SkeletonBox(height: 360))))];
    } else if (items.isEmpty) {
      body = [
        SliverToBoxAdapter(
          child: Gutter(
            child: EmptyState(
              icon: LucideIcons.shoppingBasket,
              title: tr.cartEmpty,
              text: tr.cartEmptyText,
              action: Wrap(
                alignment: WrapAlignment.center,
                spacing: kSpace2,
                runSpacing: kSpace2,
                children: [
                  AppButton(label: tr.catalog, onPressed: () => openCatalogPage()),
                  AppButton(label: tr.calculator, variant: ButtonVariant.secondary, onPressed: openCalculator),
                ],
              ),
            ),
          ),
        ),
      ];
    } else {
      final weighed = items.where((x) => isWeighed(x.unit)).toList();
      final pieces = items.where((x) => !isWeighed(x.unit)).toList();
      body = [
        if (weighed.isNotEmpty) SliverToBoxAdapter(child: _Group(title: tr.weighedGroup, icon: LucideIcons.scale, items: weighed)),
        if (pieces.isNotEmpty) SliverToBoxAdapter(child: _Group(title: tr.productsGroup, icon: LucideIcons.package, items: pieces)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(kGutter + kSpace1, kSpace1, kGutter + kSpace1, 0),
            child: Text(
              tr.cartNote,
              style: sans(kTextXs, color: kMuted, height: 1.45),
            ),
          ),
        ),
      ];
    }

    return TabPage(
      bottom: filled ? _totalBarHeight + kSpace3 : 0,
      overlay: filled
          ? Positioned(
              left: kGutter,
              right: kGutter,
              bottom: kSpace2 + media.padding.bottom + kMobileNavHeight + kSpace3,
              child: _TotalBar(items: items),
            )
          : null,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(kGutter, kSpace2, kGutter - kSpace1, kSpace3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(tr.navCart, style: display(26, height: 1.15)),
                if (filled) ...[
                  const SizedBox(width: kSpace2),
                  Text(tr.lines(items.length), style: sans(13, weight: FontWeight.w600, color: kMuted)),
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: tr.clearCart,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _confirmClear(context),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: kSpace1),
                        alignment: Alignment.center,
                        child: Text(tr.clear, style: sans(13, weight: FontWeight.w600, color: kAccentInk)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        ...body,
      ],
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x801F2B24),
      builder: (ctx) => Dialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusXl)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kSpace6, kSpace6, kSpace6, kSpace5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr.clearQuestion, style: display(kTextXl)),
              const SizedBox(height: kSpace3),
              Text(tr.clearText, style: sans(kTextSm, color: kInkSoft, height: 1.5)),
              const SizedBox(height: kSpace5),
              Row(
                children: [
                  Expanded(child: AppButton(label: tr.no, variant: ButtonVariant.secondary, block: true, onPressed: () => Navigator.pop(ctx, false))),
                  const SizedBox(width: kSpace2),
                  Expanded(child: AppButton(label: tr.clear, variant: ButtonVariant.dark, block: true, onPressed: () => Navigator.pop(ctx, true))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true && context.mounted) context.readCart.clear();
  }
}

class _Group extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<CartItem> items;
  const _Group({required this.title, required this.icon, required this.items});

  @override
  Widget build(BuildContext context) {
    final cart = context.readCart;
    return Gutter(
      extra: const EdgeInsets.only(bottom: kSpace4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(kSpace1, 0, kSpace1, kSpace2),
            child: Row(
              children: [
                Icon(icon, size: 16, color: kBrand),
                const SizedBox(width: 6),
                Text(title, style: sans(13, weight: FontWeight.w700, color: kBrand)),
              ],
            ),
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(24), boxShadow: kShadowSm),
            child: Column(
              children: [
                for (final (i, item) in items.indexed) ...[
                  if (i > 0) const Divider(height: 1, thickness: 1, color: kBorder),
                  CartLine(
                    key: ValueKey(item.key),
                    item: item,
                    onQty: (q) => cart.setQty(item.key, q),
                    onRemove: () => cart.remove(item.key),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Menyu ustida turadigan "Jami" va "Rasmiylashtirish".
class _TotalBar extends StatelessWidget {
  final List<CartItem> items;
  const _TotalBar({required this.items});

  @override
  Widget build(BuildContext context) => Container(
        height: _totalBarHeight,
        padding: const EdgeInsets.fromLTRB(18, kSpace2 + 2, 10, kSpace2 + 2),
        decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(kRadiusXl), boxShadow: kShadowMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr.total, style: sans(kTextXs, color: kMuted)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(groupTotal(totalsInput(items)), style: display(20).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                  ),
                ],
              ),
            ),
            const SizedBox(width: kSpace3),
            Pressable(
              onTap: openCheckout,
              pressedScale: .97,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: kSpace5),
                decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(22)),
                alignment: Alignment.center,
                child: Text(tr.checkout, style: display(15, weight: FontWeight.w800, color: kOnAccent)),
              ),
            ),
          ],
        ),
      );
}
