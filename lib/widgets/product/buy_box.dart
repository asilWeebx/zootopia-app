import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../config/theme.dart';
import '../../l10n/strings.dart';
import '../../models/models.dart';
import '../../screens/navigation.dart';
import '../../services/cart_lines.dart';
import '../../services/currency.dart';
import '../../services/options.dart';
import '../../services/quantity.dart';
import '../../services/units.dart';
import '../../state/scope.dart';
import '../layout/cart_feedback.dart';
import '../ui/button.dart';
import '../ui/price.dart';
import '../ui/stepper.dart';

/// Tez tanlash: ochiq ozuqaning odatiy vaznlari, hafta yoki oyga pauch soni.
const _weightPresets = [0.5, 1.0, 2.0, 3.0, 5.0];
const _piecePresets = [3.0, 5.0, 10.0, 20.0, 30.0];

/// Tanlangan variantning narxi, miqdori va "Savatga qo'shish". Savatdagisi
/// qoldiqdan ayriladi (shu mahsulotning boshqa birliklari ham). Ochiq ozuqa
/// 1 kg dan boshlanadi va yarim kilolab yuradi.
class BuyBox extends StatefulWidget {
  final Product product;
  final BuyOption option;
  final bool showStock;
  final VoidCallback? onAdded;
  const BuyBox({super.key, required this.product, required this.option, required this.showStock, this.onAdded});

  @override
  State<BuyBox> createState() => _BuyBoxState();
}

class _BuyBoxState extends State<BuyBox> {
  double _qty = 1;
  bool _added = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.cart;
    final option = widget.option;
    final product = widget.product;
    final inCart = cart.line(lineKey(product.id, option.key));
    final leftRaw = floorQty(capFor(cart.items, product.id, option) - (inCart?.qty ?? 0), option.decimal);
    final left = leftRaw < 0 ? 0.0 : leftRaw;
    final min = minQty(option.decimal);
    final weighed = isWeighed(option.unitName);
    final finished = option.inStock && cart.ready && left < min;
    final value = _qty.clamp(min, left < min ? min : left).toDouble();
    final presets = (option.decimal ? _weightPresets : _piecePresets).where((n) => n <= left).take(4).toList();
    final low = isLowStock(option);

    final stockColor = !option.inStock ? kMuted : (low ? kWarning : kSuccess);
    final stockText = !option.inStock
        ? tr.notInStock
        : widget.showStock && option.stock.isFinite
            ? tr.stock('${fmtNumber(option.stock)} ${option.unit}${low ? tr.lowSuffix : ''}')
            : tr.inStock;

    return Container(
      padding: const EdgeInsets.all(kSpace5),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(kRadiusXl), boxShadow: kShadowSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PriceText(
            amount: option.curPrice,
            currency: option.currency,
            original: option.originalPrice,
            alt: option.price,
            per: option.unit,
            size: PriceSize.xl,
          ),
          const SizedBox(height: kSpace4),
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: stockColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: stockColor.withValues(alpha: .18), spreadRadius: 4)],
                ),
              ),
              const SizedBox(width: kSpace2 + 2),
              Expanded(child: Text(stockText, style: sans(kTextSm, weight: FontWeight.w600, color: stockColor))),
            ],
          ),
          if (option.inStock && !finished) ...[
            if (weighed) ...[
              const SizedBox(height: kSpace4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: kSpace3, vertical: kSpace2),
                decoration: BoxDecoration(color: kSunSoft, borderRadius: BorderRadius.circular(kRadiusSm)),
                child: Row(
                  children: [
                    const Icon(LucideIcons.scale, size: 16, color: kOnSun),
                    const SizedBox(width: kSpace2),
                    Expanded(
                      child: Text(tr.weighedNote,
                          style: sans(kTextSm, weight: FontWeight.w500, color: kOnSun)),
                    ),
                  ],
                ),
              ),
            ],
            if (presets.length > 1) ...[
              const SizedBox(height: kSpace4),
              Wrap(
                spacing: kSpace2,
                runSpacing: kSpace2,
                children: [
                  for (final n in presets)
                    GestureDetector(
                      onTap: () => setState(() => _qty = n),
                      child: AnimatedContainer(
                        duration: kDuration,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: kSpace4),
                        decoration: BoxDecoration(
                          color: value == n ? kBrand : kSurface,
                          borderRadius: BorderRadius.circular(kRadiusFull),
                          border: Border.all(color: value == n ? kBrand : kBorder, width: 1.5),
                        ),
                        // Wrap ichida chip o'z eniga qisqaradi (alignment uni cho'zib yuboradi).
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            '${fmtNumber(n)} ${option.unit}',
                            style: display(kTextMd, weight: FontWeight.w800, color: value == n ? kOnBrand : kInk),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: kSpace4),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: kSpace3,
              runSpacing: kSpace3,
              children: [
                QtyStepper(
                  value: value,
                  decimal: option.decimal,
                  suffix: option.unit,
                  canDecrease: stepQty(value, -1, max: left, decimal: option.decimal) < value,
                  canIncrease: stepQty(value, 1, max: left, decimal: option.decimal) > value,
                  onStep: (d) => setState(() => _qty = stepQty(value, d, max: left, decimal: option.decimal)),
                  onCommit: (draft) {
                    final next = commitQty(draft, max: left, decimal: option.decimal);
                    if (next != null) setState(() => _qty = next);
                  },
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tr.total, style: sans(kTextXs, color: kMuted, height: 1.2)),
                    Text(
                      money(option.curPrice * value, option.currency),
                      style: display(kTextXl, height: 1.2).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: kSpace4),
            Builder(
              builder: (buttonContext) => AppButton(
                size: ButtonSize.lg,
                block: true,
                icon: _added ? LucideIcons.check : LucideIcons.shoppingBasket,
                iconSize: 20,
                label: _added ? tr.addedToCart : tr.addToCart,
                onPressed: () {
                  context.readCart.add(product, option, value);
                  CartFeedback.fire(buttonContext);
                  setState(() {
                    _added = true;
                    _qty = 1;
                  });
                  _timer?.cancel();
                  _timer = Timer(const Duration(milliseconds: 1800), () {
                    if (mounted) setState(() => _added = false);
                  });
                  widget.onAdded?.call();
                },
              ),
            ),
          ],
          if (finished) ...[
            const SizedBox(height: kSpace4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: kSpace4, vertical: kSpace3),
              decoration: BoxDecoration(color: kSurfaceMuted, borderRadius: BorderRadius.circular(kRadiusMd)),
              child: Text(tr.allInCartLong, style: sans(kTextSm)),
            ),
          ],
          if (inCart != null) ...[
            const SizedBox(height: kSpace4),
            GestureDetector(
              onTap: openCartPage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: kSpace4, vertical: kSpace3),
                decoration: BoxDecoration(color: kBrandSoft, borderRadius: BorderRadius.circular(kRadiusMd)),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: kSpace2,
                  children: [
                    Text.rich(TextSpan(children: [
                      TextSpan(text: '${tr.inCart} ', style: sans(kTextSm, color: kBrand)),
                      TextSpan(text: '${fmtNumber(inCart.qty)} ${unitLabel(inCart.unit)}', style: sans(kTextSm, weight: FontWeight.w700, color: kBrand)),
                    ])),
                    Text(tr.openCart, style: sans(kTextSm, weight: FontWeight.w700, color: kBrand)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
