import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../l10n/strings.dart';
import '../../services/currency.dart';
import '../../services/options.dart';
import '../ui/pet_art.dart';

/// Ta'm/o'lcham (variant) yoki birlik (dona / quti) chiplari — har birida o'z
/// narxi, bosmasdan solishtirish uchun. O'z rasmi bor variant rasmni
/// ko'rsatadi; tugaganlar ko'rinadi, lekin chizilgan.
class OptionPicker extends StatelessWidget {
  final List<BuyOption> options;
  final String selectedKey;
  final String productImage;
  final ValueChanged<BuyOption> onSelect;
  final bool showStock;

  const OptionPicker({
    super.key,
    required this.options,
    required this.selectedKey,
    required this.productImage,
    required this.onSelect,
    required this.showStock,
  });

  @override
  Widget build(BuildContext context) {
    final variants = options.any((o) => o.variantId != null);
    final photos = variants && options.any((o) => o.image.isNotEmpty && o.image != productImage);
    final base = options.where((o) => o.multiplier == 1).firstOrNull ?? options.first;
    final selected = options.where((o) => o.key == selectedKey).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: variants ? tr.pickerVariant : tr.pickerUnit, style: sans(kTextSm, weight: FontWeight.w600, color: kMuted)),
          if (selected != null) TextSpan(text: ': ${selected.label}', style: sans(kTextSm, weight: FontWeight.w700, color: kInk)),
        ])),
        const SizedBox(height: kSpace3),
        Wrap(
          spacing: kSpace2,
          runSpacing: kSpace2,
          children: [
            for (final option in options)
              Semantics(
                button: true,
                selected: option.key == selectedKey,
                label: option.inStock ? option.label : tr.optionSoldOut(option.label),
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => onSelect(option),
                  child: Opacity(
                    opacity: option.inStock ? 1 : .6,
                    child: AnimatedContainer(
                      duration: kDuration,
                      constraints: const BoxConstraints(minWidth: 120),
                      padding: photos
                          ? const EdgeInsets.fromLTRB(kSpace2, kSpace2, kSpace4, kSpace2)
                          : const EdgeInsets.symmetric(horizontal: kSpace4, vertical: kSpace2),
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(kRadiusMd),
                        border: Border.all(
                          color: option.key == selectedKey ? kBrand : kBorder,
                          width: option.key == selectedKey ? 3 : 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (photos) ...[
                            Container(
                              width: 52,
                              height: 52,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(color: kSurfaceMuted, borderRadius: BorderRadius.circular(kRadiusSm)),
                              child: SafeImage(src: option.image, packshot: true, backdrop: kSurfaceMuted),
                            ),
                            const SizedBox(width: kSpace3),
                          ],
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.label,
                                style: sans(kTextMd, weight: FontWeight.w700).copyWith(
                                  decoration: option.inStock ? null : TextDecoration.lineThrough,
                                ),
                              ),
                              if (!variants && option.multiplier != 1)
                                Text('${fmtNumber(option.multiplier)} ${base.unit}', style: sans(kTextXs, color: kMuted)),
                              Text(
                                '${money(option.curPrice, option.currency)} / ${option.unit}',
                                style: display(kTextSm, weight: FontWeight.w800, color: kInkSoft),
                              ),
                              if (!option.inStock)
                                Text(tr.soldOut, style: sans(kTextXs, color: kMuted))
                              else if (showStock && option.stock.isFinite)
                                Text(tr.optionStock('${fmtNumber(option.stock)} ${option.unit}'), style: sans(kTextXs, color: kMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
