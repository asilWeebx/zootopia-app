import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/pets.dart';
import '../config/theme.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/cart_lines.dart';
import '../services/currency.dart';
import '../services/feeding.dart';
import '../services/groups.dart';
import '../services/options.dart';
import '../services/pack.dart';
import '../services/pets.dart';
import '../services/quantity.dart';
import '../services/specs.dart';
import '../services/units.dart';
import '../state/scope.dart';
import '../widgets/layout/cart_feedback.dart';
import '../widgets/layout/page.dart';
import '../widgets/product/group_picker.dart';
import '../widgets/product/option_picker.dart';
import '../widgets/ui/basics.dart';
import '../widgets/ui/button.dart';
import '../widgets/ui/lightbox.dart';
import '../widgets/ui/pet_art.dart';
import '../widgets/ui/price.dart';
import 'navigation.dart';

/// Tez tanlash: ochiq ozuqaning odatiy vaznlari.
const _weightPresets = [0.5, 1.0, 2.0, 3.0, 5.0];

/// Mahsulot sahifasi (dizayndagi "F · Mahsulot"): hayvon fonidagi katta rasm,
/// ustiga chiqqan qog'oz varaq — butun enli nomi, ostida narxi, ta'mlari,
/// qoldig'i — va pastda
/// to'q yashil xarid paneli. Ta'mlar guruhidagi mahsulot ochilsa, sahifa shu
/// ta'm tanlangan holda ochiladi (savat qatoridan qaytganda ham).
class ProductScreen extends StatelessWidget {
  final int productId;
  final String? initialOption;
  const ProductScreen({super.key, required this.productId, this.initialOption});

  @override
  Widget build(BuildContext context) {
    final catalog = context.catalog;
    final product = catalog.configured ? catalog.productById(productId) : null;
    if (product == null) {
      return DetailPage(
        title: '',
        slivers: [
          if (!catalog.configured && catalog.loading)
            const SliverToBoxAdapter(child: LoadingSkeleton(cards: 2))
          else
            SliverToBoxAdapter(
              child: Gutter(
                child: EmptyState(
                  icon: LucideIcons.searchX,
                  title: tr.notFoundTitle,
                  text: tr.notFoundText,
                  action: AppButton(label: tr.toCatalog, onPressed: () => openCatalogPage()),
                ),
              ),
            ),
        ],
      );
    }
    return _ProductPage(key: ValueKey(product.id), product: product, group: catalog.groupOf(product.id), initialOption: initialOption);
  }
}

class _ProductPage extends StatefulWidget {
  final Product product;
  final ProductGroup? group;
  final String? initialOption;
  const _ProductPage({super.key, required this.product, required this.group, required this.initialOption});

  @override
  State<_ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<_ProductPage> {
  late int _activeId = widget.product.id;
  late String? _optionKey = defaultOption(productOptions(widget.product), widget.initialOption)?.key;
  double _qty = 1;
  bool _added = false;
  Timer? _addedTimer;

  @override
  void dispose() {
    _addedTimer?.cancel();
    super.dispose();
  }

  Product get _active => widget.group?.members.where((m) => m.product.id == _activeId).firstOrNull?.product ?? widget.product;

  void _selectMember(int id) => setState(() {
        _activeId = id;
        _optionKey = defaultOption(productOptions(_active))?.key;
        _qty = 1;
      });

  @override
  Widget build(BuildContext context) {
    final catalog = context.catalog;
    final cart = context.cart;
    final group = widget.group;
    final active = _active;
    final options = productOptions(active);
    final option = options.where((o) => o.key == _optionKey).firstOrNull ?? defaultOption(options);
    final pets = productPets(active);
    final type = productType(active);
    final pet = primaryPet(active);
    final tint = petTint(pet);
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final heroHeight = (width * 1.0).clamp(330.0, 470.0) + media.padding.top;
    final barSpace = 68 + kSpace2 + media.padding.bottom + kSpace6;
    final subtitle = [if (pets.isNotEmpty) petForLabel(pets.first), if (type != null) typeLabel(type)].join(' · ');
    final feedingSpecies = type == ProductTypeId.dry
        ? pets.where((p) => p == PetId.cat || p == PetId.dog).map((p) => p == PetId.cat ? Species.cat : Species.dog).firstOrNull
        : null;

    // Miqdor: savatdagisi qoldiqdan ayriladi (shu mahsulotning boshqa birliklari ham).
    final inCart = option == null ? null : cart.line(lineKey(active.id, option.key));
    final leftRaw = option == null ? 0.0 : floorQty(capFor(cart.items, active.id, option) - (inCart?.qty ?? 0), option.decimal);
    final left = leftRaw < 0 ? 0.0 : leftRaw;
    final decimal = option?.decimal ?? false;
    final min = minQty(decimal);
    final finished = option != null && option.inStock && cart.ready && left < min;
    final qty = _qty.clamp(min, left < min ? min : left).toDouble();
    final low = option != null && isLowStock(option);

    final String stockText;
    final Color stockColor;
    if (option == null || !option.inStock) {
      stockText = tr.notInStock;
      stockColor = kMuted;
    } else if (catalog.showStock && option.stock.isFinite) {
      stockText = tr.stock('${fmtNumber(option.stock)} ${option.unit}${low ? tr.lowSuffix : ''}');
      stockColor = low ? kWarning : kSuccess;
    } else {
      stockText = tr.inStock;
      stockColor = kSuccess;
    }

    final gallery = group == null ? productGallery(active) : [active.image];
    final heroImages = [
      for (final src in gallery)
        if (src.isNotEmpty) src,
    ];
    final optionImage = option != null && option.variantId != null && option.image.isNotEmpty ? option.image : null;

    final sheet = <Widget>[
      // Nom butun enda, narx uning ostida — uzun nom endi narx yonida siqilmaydi.
      Text(group?.title ?? active.name, style: display(group == null && active.name.length > 34 ? kTextXl + 2 : kText2xl, height: 1.2)),
      if (option != null) ...[const SizedBox(height: kSpace2), _Price(option: option)],
      if (subtitle.isNotEmpty) ...[
        const SizedBox(height: kSpace1),
        Text(subtitle, style: sans(13, color: kMuted)),
      ],
      if (group != null) ...[
        const SizedBox(height: kSpace4),
        FlavourPicker(group: group, activeId: active.id, onSelect: _selectMember),
      ],
      if (option != null && options.length > 1) ...[
        const SizedBox(height: kSpace4),
        OptionPicker(
          options: options,
          selectedKey: option.key,
          productImage: active.image,
          showStock: catalog.showStock,
          onSelect: (next) => setState(() {
            _optionKey = next.key;
            _qty = 1;
          }),
        ),
      ],
      const SizedBox(height: kSpace3),
      Text(stockText, style: sans(kTextXs, weight: FontWeight.w600, color: stockColor)),
      if (inCart != null) ...[
        const SizedBox(height: kSpace2),
        GestureDetector(
          onTap: openCartPage,
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '${tr.inCart} ', style: sans(kTextXs, color: kBrand)),
            TextSpan(text: '${fmtNumber(inCart.qty)} ${unitLabel(inCart.unit)}', style: sans(kTextXs, weight: FontWeight.w700, color: kBrand)),
            TextSpan(text: '  ·  ${tr.openCart}', style: sans(kTextXs, weight: FontWeight.w700, color: kBrand)),
          ])),
        ),
      ],
      if (option != null && option.inStock && !finished && isWeighed(option.unitName)) ...[
        const SizedBox(height: kSpace4),
        _WeighedPicks(
          value: qty,
          presets: _weightPresets.where((n) => n <= left).take(4).toList(),
          unit: option.unit,
          onPick: (n) => setState(() => _qty = n),
        ),
      ],
      if (feedingSpecies != null && option != null) _FeedingHint(species: feedingSpecies, option: option, productName: active.name),
      if (option != null) ...[
        const SizedBox(height: kSpace5),
        _Card(
          title: tr.facts,
          child: Column(children: [for (final row in productSpecs(active, option)) _SpecRow(row)]),
        ),
      ],
      if (active.description.trim().isNotEmpty) ...[
        const SizedBox(height: kSpace4),
        _Card(title: tr.description, child: Text(active.description, style: sans(kTextSm + 1, color: kInkSoft, height: 1.55))),
      ],
    ];

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          MediaQuery.removePadding(
            context: context,
            removeTop: true,
            // Bitta ustunda: varaq rasm ustiga chiqadi (sliverlarda oldingisi ustida chiziladi).
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Hero(
                    key: ValueKey(active.id),
                    height: heroHeight,
                    tint: tint,
                    pet: pet,
                    images: optionImage != null ? [optionImage, ...heroImages.where((s) => s != optionImage)] : heroImages,
                    alt: active.name,
                    showImages: catalog.showImages,
                    topInset: media.padding.top,
                  ),
                  Transform.translate(
                    offset: const Offset(0, -kRadiusXl),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(kGutter, kSpace5, kGutter, barSpace - kRadiusXl),
                      decoration: const BoxDecoration(color: kBg, borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusXl))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: sheet),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: media.padding.top + kSpace1,
            left: kGutter,
            right: kGutter,
            child: Row(
              children: [
                CircleButton(icon: LucideIcons.chevronLeft, label: tr.back, onTap: () => Navigator.of(context).maybePop()),
                const Spacer(),
                CartTarget(
                  child: BouncingCartIcon(
                    child: CircleButton(
                      icon: LucideIcons.shoppingBasket,
                      label: tr.cartCount(cart.ready ? cart.count : 0),
                      onTap: openCartPage,
                      badge: cart.ready && cart.count > 0 ? CountBadge(cart.count) : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: kSpace3,
            right: kSpace3,
            bottom: kSpace2 + media.padding.bottom,
            child: _BuyBar(
              option: option,
              qty: qty,
              decimal: decimal,
              canDecrease: option != null && stepQty(qty, -1, max: left, decimal: decimal) < qty,
              canIncrease: option != null && stepQty(qty, 1, max: left, decimal: decimal) > qty,
              finished: finished,
              added: _added,
              ready: cart.ready,
              onStep: (d) => setState(() => _qty = stepQty(qty, d, max: left, decimal: decimal)),
              onAdd: (buttonContext) {
                if (option == null) return;
                context.readCart.add(active, option, qty);
                CartFeedback.fire(buttonContext);
                setState(() {
                  _added = true;
                  _qty = 1;
                });
                _addedTimer?.cancel();
                _addedTimer = Timer(const Duration(milliseconds: 1800), () {
                  if (mounted) setState(() => _added = false);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Nom ostidagi narx qatori: "60 000 сум / шт", chegirmada eski narx chizilgan
/// holda yonida, dollarda — ostida so'mdagisi.
class _Price extends StatelessWidget {
  final BuyOption option;
  const _Price({required this.option});

  @override
  Widget build(BuildContext context) {
    final original = option.originalPrice;
    final discounted = original != null && original > option.curPrice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: nbsp(money(option.curPrice, option.currency)), style: display(24, height: 1.2).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          // "/" oldidan nol kenglikdagi bo'shliq: tor ekranda "/ шт" butunligicha keyingi qatorga o'tadi.
          TextSpan(text: ' \u200B/\u00A0${option.unit}', style: sans(13, color: kMuted)),
          if (discounted)
            TextSpan(
              text: '  ${nbsp(money(original, option.currency))}',
              style: sans(13, color: kFaint).copyWith(decoration: TextDecoration.lineThrough, decorationColor: kFaint),
            ),
        ])),
        if (option.currency == 'USD' && option.price > 0) Text('≈ ${money(option.price, '')}', style: sans(kTextXs, color: kMuted)),
      ],
    );
  }
}

/// Katta rasm hayvon fonida; bir nechta bo'lsa — suriladi, ostida nuqtalar. Bosilsa kattalashadi.
class _Hero extends StatefulWidget {
  final double height;
  final Color tint;
  final PetId pet;
  final List<String> images;
  final String alt;
  final bool showImages;
  final double topInset;
  const _Hero({super.key, required this.height, required this.tint, required this.pet, required this.images, required this.alt, required this.showImages, required this.topInset});

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.showImages ? widget.images : const <String>[];
    Widget photo(String src) => GestureDetector(
          onTap: isRenderableImageUrl(src) ? () => showLightbox(context, src: src, alt: widget.alt) : null,
          child: Padding(
            padding: EdgeInsets.fromLTRB(30, widget.topInset + kSpace2, 30, kRadiusXl + kSpace3),
            child: SafeImage(src: src, packshot: true, inset: false, backdrop: widget.tint, fallback: PetArt(pet: widget.pet)),
          ),
        );
    return Semantics(
      image: true,
      label: widget.alt,
      child: Container(
        height: widget.height,
        color: widget.tint,
        child: images.isEmpty
            ? PetArt(pet: widget.pet)
            : images.length == 1
                ? photo(images.first)
                : Stack(
                    children: [
                      PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (_, i) => photo(images[i]),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: kRadiusXl + kSpace2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < images.length; i++)
                              AnimatedContainer(
                                duration: kDuration,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _page ? 18 : 7,
                                height: 7,
                                decoration: BoxDecoration(color: i == _page ? kBrand : const Color(0x662F4A33), borderRadius: BorderRadius.circular(kRadiusFull)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

/// Pastdagi to'q yashil panel: miqdor va "Savatga qo'shish".
class _BuyBar extends StatelessWidget {
  final BuyOption? option;
  final double qty;
  final bool decimal;
  final bool canDecrease;
  final bool canIncrease;
  final bool finished;
  final bool added;
  final bool ready;
  final ValueChanged<int> onStep;
  final ValueChanged<BuildContext> onAdd;
  const _BuyBar({
    required this.option,
    required this.qty,
    required this.decimal,
    required this.canDecrease,
    required this.canIncrease,
    required this.finished,
    required this.added,
    required this.ready,
    required this.onStep,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final option = this.option;
    final buyable = option != null && option.inStock && !finished;
    Widget step(IconData icon, bool enabled, int direction, String label) => Semantics(
          button: true,
          enabled: enabled,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? () => onStep(direction) : null,
            child: SizedBox(width: 44, height: 52, child: Icon(icon, size: 18, color: enabled ? kOnDark : kOnDarkMuted.withValues(alpha: .5))),
          ),
        );

    final String label;
    final IconData icon;
    VoidCallback? Function(BuildContext) action;
    if (option == null || !option.inStock) {
      label = tr.notInStock;
      icon = LucideIcons.circleSlash;
      action = (_) => null;
    } else if (finished) {
      label = tr.allInCart;
      icon = LucideIcons.shoppingBasket;
      action = (_) => openCartPage;
    } else {
      label = added ? tr.addedToCart : tr.addToCart;
      icon = added ? LucideIcons.check : LucideIcons.shoppingBasket;
      action = (buttonContext) => ready ? () => onAdd(buttonContext) : null;
    }

    return Container(
      height: 68,
      padding: const EdgeInsets.all(kSpace2),
      decoration: BoxDecoration(
        color: kDark,
        borderRadius: BorderRadius.circular(kRadiusXl),
        boxShadow: const [BoxShadow(color: Color(0x421F2B24), blurRadius: 30, offset: Offset(0, 10))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (buyable) ...[
            Container(
              decoration: BoxDecoration(color: kDarkRaised, borderRadius: BorderRadius.circular(22)),
              child: Row(
                children: [
                  step(LucideIcons.minus, canDecrease, -1, tr.decrease),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 22),
                    child: Text(
                      decimal ? '${fmtNumber(qty)} ${option.unit}' : fmtNumber(qty),
                      textAlign: TextAlign.center,
                      style: display(decimal ? kTextMd : 17, color: kOnDark).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
                  step(LucideIcons.plus, canIncrease, 1, tr.increase),
                ],
              ),
            ),
            const SizedBox(width: kSpace2),
          ],
          Expanded(
            child: Builder(
              builder: (buttonContext) {
                final onTap = action(buttonContext);
                return Semantics(
                  button: true,
                  enabled: onTap != null,
                  child: Pressable(
                    onTap: onTap,
                    pressedScale: .97,
                    child: AnimatedContainer(
                      duration: kDuration,
                      decoration: BoxDecoration(
                        color: !buyable && option?.inStock != true ? kDarkRaised : (added ? kBrand : kAccent),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 19, color: kOnAccent),
                          const SizedBox(width: kSpace2),
                          Flexible(
                            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: display(15, weight: FontWeight.w800, color: kOnAccent)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Ochiq ozuqa: tez tanlash vaznlari va "tortib sotiladi" eslatmasi.
class _WeighedPicks extends StatelessWidget {
  final double value;
  final List<double> presets;
  final String unit;
  final ValueChanged<double> onPick;
  const _WeighedPicks({required this.value, required this.presets, required this.unit, required this.onPick});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: kSpace3, vertical: kSpace2),
            decoration: BoxDecoration(color: kSunSoft, borderRadius: BorderRadius.circular(kRadiusMd)),
            child: Row(
              children: [
                const Icon(LucideIcons.scale, size: 16, color: kOnSun),
                const SizedBox(width: kSpace2),
                Expanded(child: Text(tr.weighedNote, style: sans(13, weight: FontWeight.w500, color: kOnSun))),
              ],
            ),
          ),
          if (presets.length > 1) ...[
            const SizedBox(height: kSpace3),
            Wrap(
              spacing: kSpace2,
              runSpacing: kSpace2,
              children: [
                for (final n in presets)
                  Semantics(
                    button: true,
                    selected: value == n,
                    child: GestureDetector(
                      onTap: () => onPick(n),
                      child: AnimatedContainer(
                        duration: kDuration,
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: kSpace4),
                        decoration: BoxDecoration(
                          color: value == n ? kBrand : kSurface,
                          borderRadius: BorderRadius.circular(kRadiusFull),
                          boxShadow: value == n ? null : kShadowSm,
                        ),
                        child: Center(
                          widthFactor: 1,
                          child: Text('${fmtNumber(n)} $unit', style: display(kTextSm + 1, weight: FontWeight.w800, color: value == n ? kOnBrand : kInk)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      );
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: kSpace5, vertical: kSpace4),
        decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(kRadiusXl), boxShadow: kShadowSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: display(kTextLg)),
            const SizedBox(height: kSpace2),
            child,
          ],
        ),
      );
}

/// Yorliq, nuqtali chiziq, qiymat.
class _SpecRow extends StatelessWidget {
  final SpecRow row;
  const _SpecRow(this.row);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: LayoutBuilder(
          builder: (context, box) => Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(row.label, style: sans(13, color: kMuted)),
              const SizedBox(width: kSpace2),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 5),
                  child: SizedBox(height: 2, child: CustomPaint(painter: _DotsPainter())),
                ),
              ),
              const SizedBox(width: kSpace2),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: box.maxWidth * .6),
                child: Text(row.value, textAlign: TextAlign.right, style: sans(13, weight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = kBorderStrong;
    for (var x = 0.0; x < size.width; x += 4) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 2, 2), paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => false;
}

/// Mushuk yoki it quruq ozuqasida: bir kilo (yoki qadoq) necha kunga yetadi —
/// kalkulyatorda yozilgan hayvon uchun, u bo'lmasa odatiy katta hayvon uchun.
class _FeedingHint extends StatelessWidget {
  final Species species;
  final BuyOption option;
  final String productName;
  const _FeedingHint({required this.species, required this.option, required this.productName});

  @override
  Widget build(BuildContext context) {
    final feeding = context.feeding;
    final profile = feeding.profile;
    final own = feeding.ready && profile.touched && profile.species == species;
    final input = own
        ? FeedingInput(
            species: species,
            weightKg: profile.weightKg,
            stage: profile.stage,
            neutered: profile.neutered,
            activity: profile.activity,
            pouchesPerDay: 0,
            days: profile.days,
          )
        : FeedingInput(
            species: species,
            weightKg: species == Species.cat ? 4 : 12,
            stage: Stage.adult,
            neutered: true,
            activity: Activity.normal,
            pouchesPerDay: 0,
            days: profile.days,
          );
    final plan = feedingPlan(input);
    final grams = isWeighed(option.unitName) ? 1000 : packGrams('$productName ${option.label}');
    if (plan == null || grams == null || plan.dryGramsPerDay <= 0) return const SizedBox.shrink();

    final days = grams ~/ plan.dryGramsPerDay;
    final who = own && profile.petName.isNotEmpty ? profile.petName : tr.hintTypical(fmtNumber(input.weightKg), species);
    final amount = '1 ${option.unit}';

    return Padding(
      padding: const EdgeInsets.only(top: kSpace4),
      child: Pressable(
        onTap: openCalculator,
        child: Container(
          padding: const EdgeInsets.all(kSpace4),
          decoration: BoxDecoration(color: kDark, borderRadius: BorderRadius.circular(kRadiusLg + 2)),
          child: Row(
            children: [
              const Icon(LucideIcons.calculator, size: 22, color: kSun),
              const SizedBox(width: kSpace3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr.hintLasts(amount, days), style: display(kTextMd + 1, color: kOnDark)),
                    Text(
                      '${tr.hintDaily(who, plan.dryGramsPerDay)} ${own ? tr.hintEdit : tr.hintCalcOwn}',
                      style: sans(13, color: kOnDarkMuted, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: kSpace2),
              const Icon(LucideIcons.chevronRight, size: 18, color: kOnDark),
            ],
          ),
        ),
      ),
    );
  }
}
