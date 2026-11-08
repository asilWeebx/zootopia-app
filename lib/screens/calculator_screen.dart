import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/pets.dart';
import '../config/theme.dart';
import '../l10n/strings.dart';
import '../services/currency.dart';
import '../services/feeding.dart';
import '../state/feeding_controller.dart';
import '../state/scope.dart';
import '../widgets/layout/cart_feedback.dart';
import '../widgets/layout/page.dart';
import '../widgets/ui/basics.dart';
import '../widgets/ui/button.dart';
import '../widgets/ui/pet_art.dart';
import 'navigation.dart';

/// Ozuqa kalkulyatori (dizayndagi "E · Hisoblash"): hayvon va vazn, yoshi va
/// odatlari, natija to'q kartada, ostida katalogdagi mos ozuqa. Kiritilgani
/// keyingi safarga eslab qolinadi.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _picks = GlobalKey();

  void _showPicks() {
    final target = _picks.currentContext;
    if (target != null) Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 450), curve: kEase, alignment: .02);
  }

  @override
  Widget build(BuildContext context) {
    final feeding = context.feeding;
    final profile = feeding.profile;
    final plan = feeding.ready ? feedingPlan(profile) : null;
    return TabPage(
      slivers: [
        SliverToBoxAdapter(
          child: Gutter(
            extra: const EdgeInsets.only(top: kSpace2, bottom: kSpace4),
            child: Text(tr.calcTitle, style: display(26, height: 1.15)),
          ),
        ),
        if (!feeding.ready)
          const SliverToBoxAdapter(child: Gutter(child: Pulse(child: SkeletonBox(height: 560))))
        else ...[
          SliverToBoxAdapter(child: Gutter(child: _PetCard(profile: profile))),
          const SliverToBoxAdapter(child: SizedBox(height: kSpace3)),
          SliverToBoxAdapter(child: Gutter(child: _HabitsCard(profile: profile))),
          const SliverToBoxAdapter(child: SizedBox(height: kSpace3)),
          SliverToBoxAdapter(child: Gutter(child: _ResultCard(profile: profile, plan: plan, onPicks: _showPicks))),
          if (plan != null)
            SliverToBoxAdapter(
              child: Gutter(
                extra: const EdgeInsets.only(top: kSpace6),
                child: _Picks(key: _picks, profile: profile, plan: plan),
              ),
            ),
        ],
      ],
    );
  }
}

Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(kSpace3)}) => Container(
      padding: padding,
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(kRadiusXl), boxShadow: kShadowSm),
      child: child,
    );

/// − qiymat + (vazn va pauchlar uchun): ikki yumaloq tugma, o'rtada katta raqam.
class _Stepper extends StatelessWidget {
  final Widget value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final String label;
  const _Stepper({required this.value, required this.label, this.onMinus, this.onPlus});

  Widget _button(IconData icon, VoidCallback? onTap, String name) => Semantics(
        button: true,
        enabled: onTap != null,
        label: '$label: $name',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null ? .4 : 1,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: kSurfaceMuted, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: kInk),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(LucideIcons.minus, onMinus, tr.decrease.toLowerCase()),
          ConstrainedBox(constraints: const BoxConstraints(minWidth: 76), child: Center(widthFactor: 1, child: value)),
          _button(LucideIcons.plus, onPlus, tr.increase.toLowerCase()),
        ],
      );
}

/// Mushuk yoki it, vazni va kuniga nechta pauch.
class _PetCard extends StatefulWidget {
  final FeedingProfile profile;
  const _PetCard({required this.profile});

  @override
  State<_PetCard> createState() => _PetCardState();
}

class _PetCardState extends State<_PetCard> {
  final _weight = TextEditingController();
  final _weightFocus = FocusNode();
  /// Yozilgan vazn formula qabul qiladigan bo'lguncha matn bo'lib turadi.
  String? _draft;

  @override
  void initState() {
    super.initState();
    _weightFocus.addListener(() {
      if (_weightFocus.hasFocus) {
        _weight.selection = TextSelection(baseOffset: 0, extentOffset: _weight.text.length);
      } else {
        setState(() => _draft = null);
      }
    });
  }

  @override
  void dispose() {
    _weight.dispose();
    _weightFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feeding = context.readFeeding;
    final profile = widget.profile;
    final limits = kWeightLimits[profile.species]!;
    final typed = _draft == null ? null : double.tryParse(_draft!.replaceAll(',', '.'));
    final invalid = _draft != null && !(typed != null && typed >= limits.min && typed <= limits.max);
    final step = profile.species == Species.cat ? .5 : 1.0;
    if (_draft == null) {
      final shown = fmtNumber(profile.weightKg).replaceAll(' ', '');
      if (_weight.text != shown) _weight.text = shown;
    }

    void nudge(int direction) {
      _weightFocus.unfocus();
      setState(() => _draft = null);
      final next = ((profile.weightKg + direction * step) * 10).round() / 10;
      feeding.update(weightKg: next.clamp(limits.min, limits.max).toDouble());
    }

    Widget species(Species s) {
      final on = profile.species == s;
      final pet = s == Species.cat ? PetId.cat : PetId.dog;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          child: GestureDetector(
            onTap: () {
              setState(() => _draft = null);
              feeding.update(species: s, weightKg: on ? profile.weightKg : (s == Species.dog ? 12 : 4));
            },
            child: AnimatedContainer(
              duration: kDuration,
              height: 48,
              decoration: BoxDecoration(
                color: on ? petTint(pet) : kSurfaceMuted,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: on ? kBrand : Colors.transparent, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(petIcon(pet, stroke: 300), size: 20, color: on ? kBrand : kInkSoft),
                  const SizedBox(width: kSpace2),
                  Text(tr.species(s), style: display(15, weight: FontWeight.w800, color: on ? kInk : kInkSoft)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget row(String label, Widget control, {String? hint, Color hintColor = kMuted}) => Padding(
          padding: const EdgeInsets.fromLTRB(kSpace1, kSpace3, kSpace1, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: sans(kTextSm, weight: FontWeight.w600, height: 1.25)),
                    if (hint != null) Text(hint, style: sans(kText2xs, color: hintColor, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: kSpace2),
              control,
            ],
          ),
        );

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [species(Species.cat), const SizedBox(width: kSpace2), species(Species.dog)]),
          row(
            tr.weight,
            _Stepper(
              label: tr.weight,
              onMinus: profile.weightKg <= limits.min ? null : () => nudge(-1),
              onPlus: profile.weightKg >= limits.max ? null : () => nudge(1),
              value: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  IntrinsicWidth(
                    child: TextField(
                      controller: _weight,
                      focusNode: _weightFocus,
                      textAlign: TextAlign.right,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                      style: display(24).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                      decoration: const InputDecoration.collapsed(hintText: ''),
                      onTapOutside: (_) => _weightFocus.unfocus(),
                      onChanged: (v) {
                        setState(() => _draft = v);
                        final value = double.tryParse(v.replaceAll(',', '.'));
                        if (value != null && value >= limits.min && value <= limits.max) feeding.update(weightKg: value);
                      },
                    ),
                  ),
                  Text(' ${tr.kg}', style: display(24)),
                ],
              ),
            ),
            hint: invalid ? tr.weightRange(fmtNumber(limits.min), fmtNumber(limits.max)) : null,
            hintColor: kDanger,
          ),
          row(
            tr.pouchesQuestion,
            _Stepper(
              label: tr.pouches,
              onMinus: profile.pouchesPerDay <= 0 ? null : () => feeding.update(pouchesPerDay: profile.pouchesPerDay - 1),
              onPlus: profile.pouchesPerDay >= 6 ? null : () => feeding.update(pouchesPerDay: profile.pouchesPerDay + 1),
              value: Text('${profile.pouchesPerDay}', style: display(24)),
            ),
          ),
        ],
      ),
    );
  }
}

List<(Stage, String)> _stages(Species s) => [for (final stage in Stage.values) (stage, tr.stage(s, stage))];
List<(Activity, String)> get _activities => [for (final a in Activity.values) (a, tr.activityLabel(a))];
List<(int, String)> get _periods => [for (final days in const [7, 14, 30]) (days, tr.period(days))];

/// Yoshi, sterilizatsiya, harakati va muddat — segmentli tanlovlar.
class _HabitsCard extends StatelessWidget {
  final FeedingProfile profile;
  const _HabitsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final feeding = context.readFeeding;
    return _card(
      padding: const EdgeInsets.fromLTRB(kSpace3, kSpace3, kSpace3, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Segments(title: tr.age, options: _stages(profile.species), value: profile.stage, onChange: (s) => feeding.update(stage: s)),
          if (profile.stage != Stage.young) ...[
            const SizedBox(height: 10),
            _Segments(
              title: tr.neutered,
              options: [(true, tr.yes), (false, tr.no)],
              value: profile.neutered,
              onChange: (v) => feeding.update(neutered: v),
            ),
          ],
          const SizedBox(height: 10),
          _Segments(title: tr.activity, options: _activities, value: profile.activity, onChange: (a) => feeding.update(activity: a)),
          const SizedBox(height: 10),
          _Segments(title: tr.periodQuestion, options: _periods, value: profile.days, onChange: (d) => feeding.update(days: d)),
        ],
      ),
    );
  }
}

class _Segments<T> extends StatelessWidget {
  final String title;
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChange;
  const _Segments({required this.title, required this.options, required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(kSpace1, 0, kSpace1, 5),
            child: Text(title, style: sans(12.5, weight: FontWeight.w600, color: kInkSoft)),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: kSurfaceMuted, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                for (final (i, (option, label)) in options.indexed) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: option == value,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChange(option),
                        child: AnimatedContainer(
                          duration: kDuration,
                          constraints: const BoxConstraints(minHeight: 44),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                          decoration: BoxDecoration(
                            color: option == value ? kSurface : Colors.transparent,
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: option == value ? kShadowSm : null,
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: sans(13, weight: option == value ? FontWeight.w700 : FontWeight.w500, color: option == value ? kBrand : kInkSoft),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
}

/// To'q karta: kunlik me'yor va muddatga kerakli miqdor, "Mos ozuqani tanlash".
class _ResultCard extends StatelessWidget {
  final FeedingProfile profile;
  final FeedingPlan? plan;
  final VoidCallback onPicks;
  const _ResultCard({required this.profile, required this.plan, required this.onPicks});

  @override
  Widget build(BuildContext context) {
    final plan = this.plan;
    Widget figure(String label, String value, [String? extra]) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: sans(kTextXs, color: kOnDarkMuted)),
              const SizedBox(height: 1),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: display(24, color: kOnDark).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
              ),
              if (extra != null) Text(extra, style: sans(kTextXs, weight: FontWeight.w600, color: kSun)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(kSpace3),
      decoration: BoxDecoration(color: kDark, borderRadius: BorderRadius.circular(kRadiusXl)),
      child: plan == null
          ? Padding(
              padding: const EdgeInsets.all(kSpace2),
              child: Text(tr.calcEmpty, style: sans(kTextSm, color: kOnDarkMuted)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: figure(
                        tr.perDay,
                        plan.dryGramsPerDay > 0 ? '≈ ${plan.dryGramsPerDay} ${tr.g}' : '0 ${tr.g}',
                        profile.pouchesPerDay > 0 ? '+ ${tr.pouchesPerDay(profile.pouchesPerDay, kPouchGrams)}' : null,
                      ),
                    ),
                    const SizedBox(width: kSpace2),
                    Expanded(
                      child: figure(
                        tr.forPeriod(profile.days),
                        plan.dryKg > 0 ? '≈ ${exactKg(plan.dryKg)} ${tr.kg}' : '0 ${tr.kg}',
                        plan.pouches > 0 ? '+ ${tr.pouchAmount(plan.pouches)}' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: kSpace2),
                Pressable(
                  onTap: onPicks,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(kRadiusFull)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(child: Text(tr.pickFood, maxLines: 1, overflow: TextOverflow.ellipsis, style: display(kTextMd, weight: FontWeight.w800, color: kOnAccent))),
                        const SizedBox(width: kSpace2),
                        const Icon(LucideIcons.arrowDown, size: 18, color: kOnAccent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Katalogdagi mos ozuqa: quruq va nam, jami va "Ikkalasini savatga".
class _Picks extends StatefulWidget {
  final FeedingProfile profile;
  final FeedingPlan plan;
  const _Picks({super.key, required this.profile, required this.plan});

  @override
  State<_Picks> createState() => _PicksState();
}

class _PicksState extends State<_Picks> {
  String? _addedAll;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final plan = widget.plan;
    final products = context.catalog.products;
    final pet = FoodFor.of(profile);
    final dry = plan.dryKg > 0 ? foodFits(products, pet, dryKg: plan.dryKg).take(3).toList() : <FoodFit>[];
    final wet = plan.pouches > 0 ? foodFits(products, pet, pouches: plan.pouches).take(3).toList() : <FoodFit>[];
    final picks = [dry, wet].map((list) => list.where((f) => f.option.inStock).firstOrNull).whereType<FoodFit>().toList();
    final signature = '${profile.toJson()}|${picks.map((f) => '${f.product.id}:${f.qty}').join(',')}';
    final meals = plan.dryGramsPerDay > 0 ? (profile.stage == Stage.young ? 3 : 2) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr.fitTitle, style: display(kTextXl)),
        if (meals > 0) ...[
          const SizedBox(height: kSpace1),
          Text(
            tr.meals(meals, (plan.dryGramsPerDay / meals).round()),
            style: sans(13, color: kInkSoft, height: 1.5),
          ),
        ],
        if (plan.dryKg > 0) ...[
          const SizedBox(height: kSpace4),
          _FitGroup(title: tr.dry, fits: dry, species: profile.species, none: tr.noDry),
        ],
        if (plan.pouches > 0) ...[
          const SizedBox(height: kSpace4),
          _FitGroup(title: tr.wet, fits: wet, species: profile.species, none: tr.noWet),
        ],
        if (picks.length > 1) ...[
          const SizedBox(height: kSpace4),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr.pickedTotal, style: sans(11.5, color: kMuted)),
                    Text(
                      groupTotal(picks.map((f) => TotalInput(currency: f.option.currency, price: f.option.price, curPrice: f.option.curPrice, qty: f.qty))),
                      style: display(kTextLg),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Builder(
                builder: (buttonContext) => AppButton(
                  size: ButtonSize.lg,
                  variant: _addedAll == signature ? ButtonVariant.dark : ButtonVariant.primary,
                  icon: _addedAll == signature ? LucideIcons.check : null,
                  iconSize: 18,
                  label: _addedAll == signature ? tr.added : tr.addBoth,
                  onPressed: () {
                    final cart = context.readCart;
                    for (final fit in picks) {
                      cart.add(fit.product, fit.option, fit.qty);
                    }
                    CartFeedback.fire(buttonContext);
                    setState(() => _addedAll = signature);
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: kSpace4),
        for (final note in tr.calcNotes)
          Padding(
            padding: const EdgeInsets.only(bottom: kSpace2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(padding: EdgeInsets.only(top: 2), child: Icon(LucideIcons.info, size: 14, color: kMuted)),
                const SizedBox(width: kSpace2),
                Expanded(child: Text(note, style: sans(kTextXs, color: kMuted, height: 1.5))),
              ],
            ),
          ),
      ],
    );
  }
}

class _FitGroup extends StatelessWidget {
  final String title;
  final List<FoodFit> fits;
  final Species species;
  final String none;
  const _FitGroup({required this.title, required this.fits, required this.species, required this.none});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: kSpace1, bottom: kSpace2),
            child: Text(title.toUpperCase(), style: eyebrow()),
          ),
          if (fits.isEmpty)
            Container(
              padding: const EdgeInsets.all(kSpace4),
              decoration: BoxDecoration(color: kSurfaceMuted, borderRadius: BorderRadius.circular(kRadiusLg)),
              child: Text(none, style: sans(13, color: kMuted)),
            )
          else
            for (final (i, fit) in fits.indexed) ...[
              if (i > 0) const SizedBox(height: kSpace2),
              _FitRow(key: ValueKey(fit.product.id), fit: fit, species: species),
            ],
        ],
      );
}

class _FitRow extends StatefulWidget {
  final FoodFit fit;
  final Species species;
  const _FitRow({super.key, required this.fit, required this.species});

  @override
  State<_FitRow> createState() => _FitRowState();
}

class _FitRowState extends State<_FitRow> {
  bool _added = false;

  @override
  Widget build(BuildContext context) {
    final fit = widget.fit;
    final option = fit.option;
    final product = fit.product;
    final short = option.inStock && option.stock.isFinite && fit.qty > option.stock;
    final pet = widget.species == Species.cat ? PetId.cat : PetId.dog;
    final tint = petTint(pet);
    void open() => openProduct(product, optionKey: option.key == 'base' ? null : option.key);
    final badge = fit.neuteredMatch ? tr.neuteredMatch : (fit.stageMatch ? tr.stageMatch : null);

    return Pressable(
      onTap: open,
      pressedScale: .99,
      child: Container(
        padding: const EdgeInsets.all(kSpace2),
        decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(kRadiusXl - 4), boxShadow: kShadowSm),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 88,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(18)),
              child: SafeImage(src: option.image.isNotEmpty ? option.image : product.image, packshot: true, backdrop: tint, fallback: PetArt(pet: pet)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: product.name, style: sans(13, weight: FontWeight.w600, height: 1.25)),
                      if (option.label.isNotEmpty) TextSpan(text: ' · ${option.label}', style: sans(13, color: kMuted, height: 1.25)),
                    ]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (badge != null) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                      decoration: BoxDecoration(color: kBrandSoft, borderRadius: BorderRadius.circular(kRadiusFull)),
                      child: Text(badge, style: sans(kText2xs, weight: FontWeight.w700, color: kBrand)),
                    ),
                  ],
                  if (!option.inStock) Text(tr.notInStock, style: sans(kTextXs, weight: FontWeight.w600, color: kWarning)),
                  if (short) Text(tr.onlyLeft('${fmtNumber(option.stock)} ${option.unit}'), style: sans(kTextXs, weight: FontWeight.w600, color: kWarning)),
                  const SizedBox(height: kSpace1),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${fmtNumber(fit.qty)} ${option.unit}', style: sans(13, weight: FontWeight.w600, color: kBrand)),
                            Text(money(option.curPrice * fit.qty, option.currency), style: display(kTextSm, weight: FontWeight.w900)),
                          ],
                        ),
                      ),
                      Builder(
                        builder: (buttonContext) => Semantics(
                          button: true,
                          label: '${product.name}: ${tr.addAmount('${fmtNumber(fit.qty)} ${option.unit}')}',
                          excludeSemantics: true,
                          child: Pressable(
                            onTap: option.inStock
                                ? () {
                                    context.readCart.add(product, option, fit.qty);
                                    CartFeedback.fire(buttonContext);
                                    setState(() => _added = true);
                                  }
                                : null,
                            child: AnimatedContainer(
                              duration: kDuration,
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: kSpace3),
                              decoration: BoxDecoration(
                                color: !option.inStock ? kSurfaceMuted : (_added ? kBrand : kAccent),
                                borderRadius: BorderRadius.circular(kRadiusFull),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_added ? LucideIcons.check : LucideIcons.shoppingBasket, size: 15, color: option.inStock ? kOnAccent : kMuted),
                                  const SizedBox(width: 5),
                                  Text(_added ? tr.added : tr.add, style: display(13, weight: FontWeight.w800, color: option.inStock ? kOnAccent : kMuted)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
