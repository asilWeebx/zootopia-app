import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../config/pets.dart';
import '../../config/theme.dart';
import '../../l10n/strings.dart';
import '../../models/models.dart';
import '../../screens/navigation.dart';
import '../../services/cart_lines.dart';
import '../../services/currency.dart';
import '../../services/pets.dart';
import '../../services/quantity.dart';
import '../../services/units.dart';
import '../../state/scope.dart';
import '../ui/pet_art.dart';
import '../ui/stepper.dart';

/// Savatning bir qatori: hayvon fonidagi rasm, nomi va birlik narxi, miqdor va
/// jami. Eng kam miqdorda − bosilsa yoki chapga surilsa o'chiradi.
class CartLine extends StatelessWidget {
  final CartItem item;
  final ValueChanged<double> onQty;
  final VoidCallback onRemove;
  const CartLine({super.key, required this.item, required this.onQty, required this.onRemove});

  void _open() => openProductId(item.productId, optionKey: item.optionKey == 'base' ? null : item.optionKey);

  @override
  Widget build(BuildContext context) {
    final max = item.maxQty, decimal = item.decimal;
    final unit = unitLabel(item.unit);
    final product = context.catalog.productById(item.productId);
    final pet = product == null ? PetId.other : primaryPet(product);
    final tint = petTint(pet);
    return Dismissible(
      key: ValueKey('dismiss-${item.key}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: kSpace5),
        color: kDangerSoft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr.remove, style: sans(13, weight: FontWeight.w700, color: kDanger)),
            const SizedBox(width: kSpace2),
            const Icon(LucideIcons.trash2, size: 18, color: kDanger),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _open,
              child: Container(
                width: 80,
                height: 92,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(18)),
                child: SafeImage(src: item.image, packshot: true, backdrop: tint, fallback: PetArt(pet: pet)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 92),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _open,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: sans(13.5, weight: FontWeight.w600, height: 1.3)),
                          const SizedBox(height: 1),
                          Text(
                            [if (item.optionLabel.isNotEmpty) item.optionLabel, '${money(item.curPrice, item.currency)} / $unit'].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: sans(kTextXs, color: kMuted),
                          ),
                          if (item.qty >= item.maxQty && item.maxQty < kUnlimited)
                            Text(tr.onlyLeft('${fmtNumber(item.maxQty)} $unit'), style: sans(kText2xs, weight: FontWeight.w600, color: kWarning)),
                        ],
                      ),
                    ),
                    const SizedBox(height: kSpace2),
                    Row(
                      children: [
                        QtyStepper(
                          outlined: true,
                          value: item.qty,
                          decimal: decimal,
                          suffix: decimal ? unit : null,
                          canIncrease: stepQty(item.qty, 1, max: max, decimal: decimal) > item.qty,
                          onStep: (direction) {
                            final next = stepQty(item.qty, direction, max: max, decimal: decimal);
                            if (direction < 0 && next == item.qty) {
                              onRemove();
                            } else {
                              onQty(next);
                            }
                          },
                          onCommit: (draft) {
                            final next = commitQty(draft, max: max, decimal: decimal);
                            if (next != null) onQty(next);
                          },
                        ),
                        const SizedBox(width: kSpace2),
                        Expanded(
                          child: Text(
                            money(lineTotal(item), item.currency),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            style: display(kTextSm).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
