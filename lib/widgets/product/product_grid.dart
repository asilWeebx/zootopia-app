import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/models.dart';
import 'product_card.dart';

/// Ikki ustunli to'r; har qatordagi kartalar eng balandiga tenglashadi (saytdagi grid).
class ProductGrid extends StatelessWidget {
  final List<Product> products;
  const ProductGrid({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < products.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: kSpace3));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: ProductCard(key: ValueKey(products[i].id), product: products[i])),
            const SizedBox(width: kSpace3),
            Expanded(
              child: i + 1 < products.length
                  ? ProductCard(key: ValueKey(products[i + 1].id), product: products[i + 1])
                  : const SizedBox(),
            ),
          ],
        ),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

/// Gorizontal javon: kartalar ~168px (ekranning 47%i), chekkadan chekkagacha suriladi.
class ProductRail extends StatelessWidget {
  final List<Product> products;
  /// Birinchi kartagacha chekka; rangli fon ichida — fon ichkarisigacha.
  final double inset;
  const ProductRail({super.key, required this.products, this.inset = kGutter});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = ((width - kGutter * 2) * .47).clamp(148.0, 190.0);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(inset, kSpace1, inset, kSpace3),
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, p) in products.indexed) ...[
              if (i > 0) const SizedBox(width: kSpace3),
              SizedBox(width: cardWidth, child: ProductCard(key: ValueKey(p.id), product: p)),
            ],
          ],
        ),
      ),
    );
  }
}
