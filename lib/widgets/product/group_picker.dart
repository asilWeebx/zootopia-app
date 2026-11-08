import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../config/theme.dart';
import '../../l10n/strings.dart';
import '../../services/catalog.dart';
import '../../services/currency.dart';
import '../../services/groups.dart';
import '../../services/options.dart';
import '../../services/pets.dart';
import '../../services/units.dart';
import '../../state/scope.dart';
import '../ui/button.dart';
import '../ui/pet_art.dart';
import '../ui/sheet.dart';

/// Shundan kam bo'lsa qidiruv faqat joy egallaydi.
const _searchFrom = 8;

/// "5 l", "2 kg" / "5 л", "2 кг": o'lcham tugmada qanday o'qiladi.
String _sizeText(PackSize size) {
  final unit = switch (size.unit) {
    'л' => tr.units[UnitKind.l]!,
    'кг' => tr.kg,
    'гр' => tr.g,
    'мл' => tr.ml,
    _ => size.unit,
  };
  return '${fmtNumber(size.amount)} $unit';
}

/// Guruh ichidagi tanlov: sarlavha ("Ta’mi · 28 xil" va qidiruv), rasmli
/// plitkalar qatori (tanlangani ko'rinib turadi) va — hid ham, o'lcham ham
/// farq qilsa (PROLINE) — o'lcham tugmalari.
class FlavourPicker extends StatelessWidget {
  final ProductGroup group;
  final int activeId;
  final ValueChanged<int> onSelect;
  const FlavourPicker({super.key, required this.group, required this.activeId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final active = group.members.where((m) => m.product.id == activeId).firstOrNull ?? group.members.first;
    final twoChoice = group.sizes.length > 1;
    final choices = twoChoice ? _choices(group) : null;
    final tiles = twoChoice
        ? [
            for (final c in choices!)
              (
                member: c.members.where((m) => !isOutOfStock(m.product)).firstOrNull ?? c.members.first,
                selected: c.label == active.label,
                out: c.members.every((m) => isOutOfStock(m.product)),
                pick: () => onSelect((c.members.where((m) => m.size?.text == active.size?.text).firstOrNull ??
                        c.members.where((m) => !isOutOfStock(m.product)).firstOrNull ??
                        c.members.first)
                    .product
                    .id),
              ),
          ]
        : [
            for (final m in group.members)
              (member: m, selected: m.product.id == active.product.id, out: isOutOfStock(m.product), pick: () => onSelect(m.product.id)),
          ];
    final count = twoChoice ? choices!.length : group.members.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: tr.groupPicker(group.kind), style: display(17)),
                  TextSpan(text: ' · ${tr.variants(count)}', style: sans(13, weight: FontWeight.w500, color: kMuted)),
                ]),
              ),
            ),
            if (group.members.length >= _searchFrom)
              Pressable(
                onTap: () async {
                  final id = await showGroupSearch(context, group, active.product.id);
                  if (id != null) onSelect(id);
                },
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: kSpace3),
                  decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(kRadiusFull), boxShadow: kShadowSm),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.search, size: 15, color: kInk),
                      const SizedBox(width: 5),
                      Text(tr.groupSearch(group.kind), style: sans(kTextXs, weight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: kSpace3 - 2),
        _Strip(
          key: ValueKey(group.key),
          tiles: [
            for (final t in tiles)
              _Tile(
                image: t.member.product.image,
                label: t.member.label,
                tint: petTint(primaryPet(t.member.product)),
                selected: t.selected,
                out: t.out,
                onTap: t.pick,
              ),
          ],
        ),
        if (twoChoice) ...[
          const SizedBox(height: kSpace4),
          Text(group.sizes.first.unit == 'л' ? tr.volume : tr.pack, style: display(kTextMd)),
          const SizedBox(height: kSpace2),
          Wrap(
            spacing: kSpace2,
            runSpacing: kSpace2,
            children: [
              for (final size in group.sizes)
                () {
                  final member = choices!
                      .where((c) => c.label == active.label)
                      .firstOrNull
                      ?.members
                      .where((m) => m.size?.text == size.text)
                      .firstOrNull;
                  final on = size.text == active.size?.text;
                  return Semantics(
                    button: true,
                    selected: on,
                    enabled: member != null,
                    child: GestureDetector(
                      onTap: member == null ? null : () => onSelect(member.product.id),
                      child: Opacity(
                        opacity: member == null ? .45 : 1,
                        child: AnimatedContainer(
                          duration: kDuration,
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: kSpace4),
                          decoration: BoxDecoration(
                            color: on ? kBrand : kSurface,
                            borderRadius: BorderRadius.circular(kRadiusFull),
                            boxShadow: on ? null : kShadowSm,
                          ),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              _sizeText(size),
                              style: sans(13, weight: FontWeight.w600, color: on ? kOnBrand : kInk).copyWith(
                                decoration: member == null ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }(),
            ],
          ),
        ],
      ],
    );
  }
}

/// Hid bo'yicha a'zolar, har biri o'lchamlari bilan (kichigi birinchi).
List<({String label, List<GroupMember> members})> _choices(ProductGroup group) {
  final byLabel = <String, List<GroupMember>>{};
  for (final m in group.members) {
    (byLabel[m.label] ??= []).add(m);
  }
  final labels = byLabel.keys.toList()..sort(compareText);
  return [
    for (final label in labels)
      (label: label, members: [...byLabel[label]!]..sort((a, b) => (a.size?.amount ?? 0).compareTo(b.size?.amount ?? 0))),
  ];
}

class _Tile {
  final String image;
  final String label;
  final Color tint;
  final bool selected;
  final bool out;
  final VoidCallback onTap;
  const _Tile({required this.image, required this.label, required this.tint, required this.selected, required this.out, required this.onTap});
}

/// Gorizontal plitkalar; tanlangani (masalan, 28 tadan 25-si) ko'rinadigan joyga suriladi.
class _Strip extends StatefulWidget {
  final List<_Tile> tiles;
  const _Strip({super.key, required this.tiles});

  @override
  State<_Strip> createState() => _StripState();
}

class _StripState extends State<_Strip> {
  static const _width = 98.0;
  static const _gap = kSpace2;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(animate: false));
  }

  @override
  void didUpdateWidget(_Strip old) {
    super.didUpdateWidget(old);
    final was = old.tiles.indexWhere((t) => t.selected);
    final now = widget.tiles.indexWhere((t) => t.selected);
    if (was != now) WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(animate: true));
  }

  void _reveal({required bool animate}) {
    if (!mounted || !_scroll.hasClients) return;
    final i = widget.tiles.indexWhere((t) => t.selected);
    if (i < 0) return;
    final position = _scroll.position;
    final left = i * (_width + _gap);
    final view = position.viewportDimension;
    final current = position.pixels;
    double? target;
    if (left < current) {
      target = left - kGutter;
    } else if (left + _width > current + view) {
      target = left + _width - view + kGutter;
    }
    if (target == null) return;
    final to = target.clamp(0.0, position.maxScrollExtent);
    if (animate) {
      _scroll.animateTo(to, duration: const Duration(milliseconds: 260), curve: kEase);
    } else {
      _scroll.jumpTo(to);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showImages = context.catalog.showImages;
    // Chegara 2+2, ichki chekka 4+8, rasm 92, matn ustida 6 va ikki qator matn.
    final text = MediaQuery.textScalerOf(context).scale(11.5) * 1.25 * 2;
    return SizedBox(
      height: (showImages ? 92 : 0) + 4 + 12 + 6 + text + 2,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: widget.tiles.length,
        separatorBuilder: (_, _) => const SizedBox(width: _gap),
        itemBuilder: (context, i) {
          final tile = widget.tiles[i];
          return Semantics(
            button: true,
            selected: tile.selected,
            label: tile.out ? tr.optionSoldOut(tile.label) : tile.label,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: tile.onTap,
              child: Opacity(
                opacity: tile.out ? .5 : 1,
                child: AnimatedContainer(
                  duration: kDuration,
                  width: _width,
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(kRadiusLg),
                    border: Border.all(color: tile.selected ? kBrand : Colors.transparent, width: 2),
                    boxShadow: kShadowSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showImages)
                        Container(
                          height: 92,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(color: tile.tint, borderRadius: BorderRadius.circular(15)),
                          child: SafeImage(src: tile.image, packshot: true, backdrop: tile.tint),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                        child: Text(
                          tile.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: sans(11.5, weight: FontWeight.w600, height: 1.25).copyWith(
                            decoration: tile.out ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Guruh ta'mlari ro'yxati qidiruv bilan — tanlangani qaytadi.
Future<int?> showGroupSearch(BuildContext context, ProductGroup group, int activeId) => showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: kBg,
      barrierColor: kBackdrop,
      routeSettings: const RouteSettings(name: '/sheet/group-search'),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusXl))),
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .85),
      builder: (_) => _GroupSearch(group: group, activeId: activeId),
    );

class _GroupSearch extends StatefulWidget {
  final ProductGroup group;
  final int activeId;
  const _GroupSearch({required this.group, required this.activeId});

  @override
  State<_GroupSearch> createState() => _GroupSearchState();
}

class _GroupSearchState extends State<_GroupSearch> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final showStock = context.catalog.showStock;
    final showImages = context.catalog.showImages;
    final cheapest = groupPriceGroups(group).firstOrNull?.option.curPrice;
    final matches = group.members.where((m) => matchesText(m.label, _query.text)).toList();
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(kSpace5, kSpace4, kSpace5, kSpace3),
            child: Row(
              children: [
                Expanded(child: Text(tr.groupChoose(group.kind), style: display(kTextXl))),
                CloseCircle(onTap: () => Navigator.of(context).pop()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSpace5),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: kSpace4),
              decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(kRadiusFull), boxShadow: kShadowSm),
              child: Row(
                children: [
                  const Icon(LucideIcons.search, size: 18, color: kMuted),
                  const SizedBox(width: kSpace2),
                  Expanded(
                    child: TextField(
                      controller: _query,
                      autocorrect: false,
                      textInputAction: TextInputAction.search,
                      style: sans(kTextSm + 1),
                      decoration: InputDecoration.collapsed(hintText: tr.groupSearch(group.kind), hintStyle: sans(kTextSm + 1, color: kMuted)),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: kSpace3),
          Flexible(
            child: matches.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(kSpace8),
                    child: Text(tr.nothingFound, textAlign: TextAlign.center, style: sans(kTextSm, color: kMuted)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.fromLTRB(kSpace3, 0, kSpace3, kSpace5 + media.padding.bottom),
                    itemCount: matches.length,
                    itemBuilder: (context, i) {
                      final m = matches[i];
                      final option = memberOption(m.product);
                      final out = isOutOfStock(m.product);
                      final dearer = option != null && cheapest != null && option.curPrice != cheapest;
                      final current = m.product.id == widget.activeId;
                      final tint = petTint(primaryPet(m.product));
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).pop(m.product.id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          padding: const EdgeInsets.symmetric(horizontal: kSpace2, vertical: 6),
                          decoration: BoxDecoration(color: current ? kBrandSoft : Colors.transparent, borderRadius: BorderRadius.circular(kRadiusLg)),
                          child: Opacity(
                            opacity: out ? .55 : 1,
                            child: Row(
                              children: [
                                if (showImages) ...[
                                  Container(
                                    width: 48,
                                    height: 48,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(kRadiusMd)),
                                    child: SafeImage(src: m.product.image, packshot: true, backdrop: tint),
                                  ),
                                  const SizedBox(width: kSpace3),
                                ],
                                Expanded(
                                  child: Text(m.label, style: sans(kTextSm, weight: current ? FontWeight.w700 : FontWeight.w500, color: current ? kBrand : kInk)),
                                ),
                                if (dearer && !out) ...[
                                  const SizedBox(width: kSpace2),
                                  Text(money(option.curPrice, option.currency), style: display(kTextSm, weight: FontWeight.w800)),
                                ],
                                const SizedBox(width: kSpace2),
                                if (out)
                                  Text(tr.soldOut, style: sans(kTextXs, color: kMuted))
                                else if (showStock && option != null && option.stock.isFinite)
                                  Text('${fmtNumber(option.stock)} ${option.unit}', style: sans(kTextXs, color: kMuted)),
                                if (current) ...[const SizedBox(width: kSpace2), const Icon(LucideIcons.check, size: 18, color: kBrand)],
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
