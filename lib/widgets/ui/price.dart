import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../l10n/strings.dart';
import '../../services/currency.dart';

enum PriceSize { sm, md, lg, xl }

/// Minglar orasidagi bo'sh joy qatorda uzilmasin.
String nbsp(String s) => s.replaceAll(' ', '\u00A0');

/// "56 000 so'm / dona"; chegirmada eski narx chizilgan holda.
class PriceText extends StatelessWidget {
  final double amount;
  final String currency;
  final double? original;
  final String? per;
  final PriceSize size;
  /// Boshlang'ich narx: "56 000 so'm dan".
  final bool from;
  /// ERP USD narx yonida yuboradigan so'm summasi.
  final double? alt;

  const PriceText({
    super.key,
    required this.amount,
    this.currency = '',
    this.original,
    this.per,
    this.size = PriceSize.md,
    this.from = false,
    this.alt,
  });

  @override
  Widget build(BuildContext context) {
    final amountSize = switch (size) {
      PriceSize.sm => kTextMd,
      PriceSize.md => kTextLg,
      PriceSize.lg => kText2xl,
      PriceSize.xl => text3xl(context),
    };
    final discounted = original != null && original! > amount;
    final percent = discounted && original! > 0 ? ((1 - amount / original!) * 100).round() : 0;
    final perStyle = sans(size == PriceSize.sm ? kTextXs : kTextSm, weight: FontWeight.w500, color: kMuted);
    // "5 000 so'mdan" / "от 5 000 сум".
    final price = money(amount, currency);
    final shown = from ? tr.priceFrom(price, currency.isEmpty || currency == 'UZS') : price;
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: nbsp(shown),
          style: display(amountSize, color: kInk, height: size == PriceSize.xl ? 1.05 : 1.15)
              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        // Unicode "/" oldidan qatorni bo'lmaydi \u2014 nol kenglikdagi bo'shliq unga ruxsat beradi,
        // shunda "/ dona" butunligicha keyingi qatorga o'tadi ("do-na" bo'linmaydi).
        if (per != null) TextSpan(text: ' \u200B/\u00A0$per', style: perStyle),
        if (discounted)
          TextSpan(
            text: ' ${nbsp(money(original, currency))}',
            style: sans(kTextSm, color: kFaint).copyWith(decoration: TextDecoration.lineThrough, decorationColor: kFaint),
          ),
        if (percent > 0 && percent < 100) ...[
          const TextSpan(text: ' '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(kRadiusFull)),
              child: Text('−$percent%', style: display(kTextXs, weight: FontWeight.w800, color: kOnAccent)),
            ),
          ),
        ],
        if (currency == 'USD' && alt != null && alt! > 0)
          TextSpan(
            text: '\n≈ ${money(alt, '')}${per != null ? ' / $per' : ''}',
            style: sans(kTextXs, color: kMuted),
          ),
      ]),
    );
  }
}
