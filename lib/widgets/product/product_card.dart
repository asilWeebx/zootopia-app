import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../config/theme.dart';
import '../../l10n/strings.dart';
import '../../models/models.dart';
import '../../screens/navigation.dart';
import '../../services/cart_lines.dart';
import '../../services/currency.dart';
import '../../services/groups.dart';
import '../../services/options.dart';
import '../../services/pets.dart';
import '../../services/quantity.dart';
import '../../services/units.dart';
import '../../state/scope.dart';
import '../layout/cart_feedback.dart';
import '../ui/button.dart';
import '../ui/pet_art.dart';
import '../ui/price.dart';
import '../ui/stepper.dart';
import 'quick_buy.dart';

/// Kartadagi ta'm nuqtalari soni.
const _dotsShown = 4;

/// Katalog kartasi: ta'mlar guruhi bo'lsa — guruh kartasi, aks holda mahsulotniki.
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final group = context.catalog.groupOf(product.id);
    return group == null ? _SingleCard(product: product) : _GroupCard(group: group, lead: product);
  }
}

/// Kartaning qolipi: oq quti, hayvon fonidagi kvadrat rasm, ostida matn va
/// pastda butun enli tugma (qator kartalari bir balandlikda — tugmalar bir chiziqda).
class _CardFrame extends StatelessWidget {
  final VoidCallback onTap;
  final Widget media;
  final List<Widget> body;
  final Widget action;
  const _CardFrame({required this.onTap, required this.media, required this.body, required this.action});

  @override
  Widget build(BuildContext context) => Pressable(
        pressedScale: .985,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(kSpace2),
          decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(kRadiusXl), boxShadow: kShadowSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(borderRadius: BorderRadius.circular(kRadiusXl - 6), child: media),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, kSpace2 + 2, 6, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [...body, const Spacer(), const SizedBox(height: kSpace2), action],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

Widget _name(String text) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kTextSm * 1.35 * 2),
      child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: sans(kTextSm, weight: FontWeight.w600, height: 1.35)),
    );

Widget _prices(List<PriceGroup> groups) => Wrap(
      spacing: kSpace2,
      children: [
        for (final g in groups)
          PriceText(amount: g.option.curPrice, currency: g.option.currency, original: g.option.originalPrice, per: g.option.unit, from: g.varies, size: PriceSize.sm),
      ],
    );

/// Kartaning to'liq enli tugmasi (44px).
class _CardButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color fg;
  final IconData? icon;
  final VoidCallback? onTap;
  const _CardButton({required this.label, this.color = kBrand, this.fg = kOnBrand, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: onTap != null,
        child: Pressable(
          onTap: onTap,
          pressedScale: .97,
          child: Opacity(
            opacity: onTap == null ? .55 : 1,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: kSpace2),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(kRadiusFull)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 6)],
                  Flexible(
                    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: display(kTextSm, weight: FontWeight.w800, color: fg)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Badge(this.text, {this.bg = kSurface, this.fg = kWarning});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(kRadiusFull)),
        child: Text(text, style: display(kText2xs, weight: FontWeight.w800, color: fg)),
      );
}

/// "Tortib" — kilolab sotiladigan ozuqa belgisi.
class _Weighed extends StatelessWidget {
  const _Weighed();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xE0FFFFFF), borderRadius: BorderRadius.circular(kRadiusFull)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.scale, size: 14, color: kBrand),
            const SizedBox(width: 4),
            Text(tr.weighedShort, style: sans(kText2xs, weight: FontWeight.w700, color: kBrand)),
          ],
        ),
      );
}

ColorFilter _grayscale(double amount) {
  final a = 1 - amount;
  return ColorFilter.matrix([
    0.2126 + 0.7874 * a, 0.7152 - 0.7152 * a, 0.0722 - 0.0722 * a, 0, 0,
    0.2126 - 0.2126 * a, 0.7152 + 0.2848 * a, 0.0722 - 0.0722 * a, 0, 0,
    0.2126 - 0.2126 * a, 0.7152 - 0.7152 * a, 0.0722 + 0.9278 * a, 0, 0,
    0, 0, 0, 1, 0,
  ]);
}

Widget _soldOutLook(Widget image) => Opacity(opacity: .6, child: ColorFiltered(colorFilter: _grayscale(.8), child: image));

/// Rasm va uning ustidagi belgilar.
Widget _media({required Color tint, required Widget image, required List<Widget> badges, Widget? bottomLeft, Widget? bottomRight}) => ColoredBox(
      color: tint,
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          Positioned(top: kSpace2, left: kSpace2, right: kSpace2, child: Wrap(spacing: kSpace1, runSpacing: kSpace1, children: badges)),
          if (bottomLeft != null) Positioned(left: kSpace2, bottom: kSpace2, child: bottomLeft),
          if (bottomRight != null) Positioned(right: kSpace2, bottom: kSpace2, child: bottomRight),
        ],
      ),
    );

int _discount(BuyOption? o) =>
    o?.originalPrice != null && o!.originalPrice! > o.curPrice ? ((1 - o.curPrice / o.originalPrice!) * 100).round() : 0;

/// Ta'mlar guruhi: qadoqlari yelpig'ichdek, rasmida ta'mlar soni, ostida ta'm
/// nuqtalari. Qo'shadigan bitta narsa yo'q — tugma tanlash oynasini ochadi.
class _GroupCard extends StatelessWidget {
  final ProductGroup group;
  final Product lead;
  const _GroupCard({required this.group, required this.lead});

  @override
  Widget build(BuildContext context) {
    final catalog = context.catalog;
    final cart = context.cart;
    final choices = groupChoices(group);
    final frontLabel = group.members.where((m) => m.product.id == lead.id).firstOrNull?.label;
    final behind = [
      for (final m in choices)
        if (m.label != frontLabel && isRenderableImageUrl(m.product.image)) m.product,
    ];
    // Tanlovning birinchi a'zosi uning biror qismi bor bo'lsa omborda: `members` tugaganlarni oxiriga qo'yadi.
    final inStock = choices.where((m) => !isOutOfStock(m.product)).toList();
    final soldOut = inStock.isEmpty;
    final prices = groupPriceGroups(group);
    final pet = primaryPet(lead);
    final tint = petTint(pet);
    final weighed = isWeighed(prices.firstOrNull?.option.unitName);
    final bestseller = group.members.any((m) => catalog.topIds.contains(m.product.id));
    final discount = inStock.map((m) => _discount(memberOption(m.product))).fold(0, (a, b) => a > b ? a : b);
    final inCart = cart.ready ? cart.items.where((x) => group.members.any((m) => m.product.id == x.productId)).length : 0;
    final note = !soldOut && inStock.length < choices.length ? tr.groupLeft(inStock.length) : null;

    Widget image;
    if (catalog.showImages && isRenderableImageUrl(lead.image)) {
      Widget pack(Product p, {required double left, required double top, required double width, required double height, double turn = 0}) =>
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment(left, top),
              widthFactor: width,
              heightFactor: height,
              child: Transform.rotate(
                angle: turn * 3.1415926 / 180,
                child: SafeImage(src: p.image, packshot: true, inset: false, backdrop: tint),
              ),
            ),
          );
      image = Stack(
        children: [
          // Orqadagi qadoqlar 8% chekkadan, 14% tepadan; oldingisi o'rtada, kattaroq.
          if (behind.isNotEmpty) pack(behind[0], left: -.68, top: -.125, width: .5, height: .68, turn: -10),
          if (behind.length > 1) pack(behind[1], left: .68, top: -.125, width: .5, height: .68, turn: 10),
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: const Alignment(0, -.25),
              widthFactor: .56,
              heightFactor: .76,
              child: SafeImage(src: lead.image, packshot: true, inset: false, backdrop: tint, fallback: PetArt(pet: pet)),
            ),
          ),
        ],
      );
    } else {
      image = PetArt(pet: pet);
    }
    if (soldOut) image = _soldOutLook(image);

    return _CardFrame(
      onTap: () => openProduct(lead),
      media: _media(
        tint: tint,
        image: image,
        badges: soldOut
            ? [_Badge(tr.soldOut, bg: kInkSoft, fg: kSurface)]
            : [
                if (bestseller) _Badge(tr.bestseller, bg: kSun, fg: kOnSun),
                if (discount > 0) _Badge('−$discount%', bg: kAccent, fg: kOnAccent),
              ],
        bottomLeft: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
          decoration: BoxDecoration(color: kBrand, borderRadius: BorderRadius.circular(kRadiusFull)),
          child: Text(tr.groupCount(group.kind, choices.length), style: display(kTextXs, weight: FontWeight.w800, color: kOnBrand)),
        ),
        bottomRight: weighed && !soldOut ? const _Weighed() : null,
      ),
      body: [
        if (catalog.showImages) ...[
          _Dots(items: [for (final m in choices) (m.product, m.label)]),
          const SizedBox(height: kSpace2),
        ],
        _name(group.title),
        const SizedBox(height: 2),
        _prices(prices),
        if (note != null) ...[
          const SizedBox(height: 2),
          Text(note, style: sans(kTextXs, color: kMuted)),
        ],
      ],
      action: soldOut
          ? _CardButton(label: tr.details, color: kSurfaceMuted, fg: kInk, onTap: () => openProduct(lead))
          : _CardButton(
              label: inCart > 0 ? tr.inCartVariants(inCart) : tr.groupChoose(group.kind),
              onTap: cart.ready ? () => showGroupQuickBuy(context, group, lead) : null,
            ),
    );
  }
}

/// Ta'm rasmlari nuqta bo'lib: to'rttagacha hammasi, ko'p bo'lsa uchtasi va
/// "+25" — eng tor kartaga ham sig'adi. Bosilsa o'sha ta'm ochiladi.
class _Dots extends StatelessWidget {
  final List<(Product, String)> items;
  const _Dots({required this.items});

  @override
  Widget build(BuildContext context) {
    final shown = items.length <= _dotsShown ? items.length : _dotsShown - 1;
    final more = items.length - shown;
    final dots = <Widget>[
      for (final (product, label) in items.take(shown))
        Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => openProduct(product),
            child: Opacity(
              opacity: isOutOfStock(product) ? .45 : 1,
              child: Container(
                width: 26,
                height: 26,
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: kSurfaceMuted, shape: BoxShape.circle, border: Border.all(color: kBorder, width: 1.5)),
                child: isRenderableImageUrl(product.image)
                    ? SafeImage(src: product.image, packshot: true, inset: false, backdrop: kSurfaceMuted)
                    : Text(label.isEmpty ? '' : label.characters.first, style: sans(kText2xs, weight: FontWeight.w700, color: kMuted)),
              ),
            ),
          ),
        ),
      if (more > 0) Text('+$more', maxLines: 1, style: sans(kTextXs, color: kMuted)),
    ];
    // Eng tor telefonda (360dp) ham sig'adi: kerak bo'lsa butun qator biroz kichrayadi.
    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, dot) in dots.indexed) ...[if (i > 0) const SizedBox(width: 6), dot],
          ],
        ),
      ),
    );
  }
}

/// Bitta mahsulot. Bitta xarid usuli bo'lsa to'g'ridan-to'g'ri shu yerdan
/// qo'shiladi (1 kg ochiq ozuqa, bitta pauch) va savatda bo'lgach joyida
/// o'zgartiriladi; ERP variantlari yoki bir nechta birligi bo'lsa — tez
/// tanlash oynasi ochiladi.
class _SingleCard extends StatelessWidget {
  final Product product;
  const _SingleCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final catalog = context.catalog;
    final cart = context.cart;
    final options = productOptions(product);
    final variants = hasVariants(product);
    final groups = optionPriceGroups(options);
    final shown = groups.firstOrNull?.option;
    final single = options.length == 1 ? options.first : null;
    final soldOut = !options.any((o) => o.inStock);
    final low = single != null && isLowStock(single);
    final pet = primaryPet(product);
    final tint = petTint(pet);
    final weighed = isWeighed(shown?.unitName);
    final bestseller = catalog.topIds.contains(product.id);
    final discount = _discount(shown);
    final line = single != null && cart.ready ? cart.line(lineKey(product.id, single.key)) : null;
    final inCart = cart.ready ? cart.items.where((x) => x.productId == product.id).length : 0;

    Widget image = catalog.showImages ? SafeImage(src: product.image, packshot: true, backdrop: tint, fallback: PetArt(pet: pet)) : PetArt(pet: pet);
    if (soldOut) image = _soldOutLook(image);

    final String? stockLine;
    if (soldOut) {
      stockLine = null;
    } else if (single != null) {
      stockLine = catalog.showStock && single.stock.isFinite ? tr.stock('${fmtNumber(single.stock)} ${single.unit}') : null;
    } else {
      stockLine = variants ? tr.variants(options.length) : options.map((o) => o.unit).join(' · ');
    }

    return _CardFrame(
      onTap: () => openProduct(product),
      media: _media(
        tint: tint,
        image: image,
        badges: soldOut
            ? [_Badge(tr.soldOut, bg: kInkSoft, fg: kSurface)]
            : [
                if (bestseller) _Badge(tr.bestseller, bg: kSun, fg: kOnSun),
                if (discount > 0) _Badge('−$discount%', bg: kAccent, fg: kOnAccent),
                if (low && !bestseller) _Badge(tr.lowStock),
              ],
        bottomRight: weighed && !soldOut ? const _Weighed() : null,
      ),
      body: [
        if (variants && catalog.showImages) ...[
          _Dots(items: [for (final o in options) (product, o.label)]),
          const SizedBox(height: kSpace2),
        ],
        _name(product.name),
        const SizedBox(height: 2),
        _prices(groups),
        if (stockLine != null) ...[
          const SizedBox(height: 2),
          Text(stockLine, style: sans(kTextXs, weight: low ? FontWeight.w600 : FontWeight.w400, color: low ? kWarning : kMuted)),
        ],
      ],
      action: _action(context, single: single, shown: shown, line: line, inCart: inCart, soldOut: soldOut),
    );
  }

  Widget _action(BuildContext context, {required BuyOption? single, required BuyOption? shown, required CartItem? line, required int inCart, required bool soldOut}) {
    final cart = context.readCart;
    if (soldOut) return _CardButton(label: tr.details, color: kSurfaceMuted, fg: kInk, onTap: () => openProduct(product));
    if (line != null) {
      return SizedBox(
        height: 44,
        child: QtyStepper(
          small: true,
          expand: true,
          value: line.qty,
          decimal: line.decimal,
          suffix: unitLabel(line.unit),
          canIncrease: stepQty(line.qty, 1, max: line.maxQty, decimal: line.decimal) > line.qty,
          onStep: (direction) {
            final next = stepQty(line.qty, direction, max: line.maxQty, decimal: line.decimal);
            if (direction < 0 && next == line.qty) {
              cart.remove(line.key);
            } else {
              cart.setQty(line.key, next);
            }
          },
          onCommit: (draft) {
            final next = commitQty(draft, max: line.maxQty, decimal: line.decimal);
            if (next != null) cart.setQty(line.key, next);
          },
        ),
      );
    }
    final ready = context.cart.ready;
    if (single == null) {
      return _CardButton(
        label: inCart > 0 ? tr.inCartVariants(inCart) : tr.choose,
        onTap: ready && shown != null ? () => showQuickBuy(context, product, shown) : null,
      );
    }
    return Builder(
      builder: (buttonContext) => _CardButton(
        label: single.decimal ? tr.addAmount('1 ${single.unit}') : tr.add,
        color: kAccent,
        fg: kOnAccent,
        icon: LucideIcons.shoppingBasket,
        onTap: !ready
            ? null
            : () {
                cart.add(product, single, 1);
                CartFeedback.fire(buttonContext);
              },
      ),
    );
  }
}
