import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/store.dart';
import '../config/theme.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/catalog.dart';
import '../services/groups.dart';
import '../services/pets.dart';
import '../state/scope.dart';
import '../widgets/layout/brand.dart';
import '../widgets/layout/page.dart';
import '../widgets/product/product_grid.dart';
import '../widgets/ui/button.dart';
import '../widgets/ui/pet_art.dart';
import 'navigation.dart';

/// Ko'p sotilganlar yetarli bo'lganda o'z javoniga ega bo'ladi (saytdagidek).
const _topShelfMin = 4;
const _topShelfMax = 12;
const _shelfMax = 10;

/// Ko'p sotilganlar foni ekran chetidan shuncha ichkarida — kartalar
/// pastdagi javonlar bilan bir chiziqda qoladi.
const _bandInset = kSpace2;

/// Bosh sahifa (dizayndagi "F2 · Asosiy"): logo va qidiruv, sarlavhasiz
/// hayvon plitkalari, to'q yashil fondagi ko'p sotilganlar va har hayvonning javoni.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    homeScrollTop.addListener(_toTop);
  }

  void _toTop() {
    if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 450), curve: kEase);
  }

  @override
  void dispose() {
    homeScrollTop.removeListener(_toTop);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.catalog;
    return TabPage(
      controller: _scroll,
      slivers: [
        const SliverToBoxAdapter(child: _Header()),
        ...catalogGate(context, () {
          final cards = catalog.cards;
          final pets = petGroups(cards);
          final shelves = groupByPet(cards, [for (final g in pets) g.id]);
          final top = collapseGroups(catalog.topProducts, catalog.groups).take(_topShelfMax).toList();
          return [
            if (pets.isNotEmpty) SliverToBoxAdapter(child: _PetPicker(groups: pets)),
            if (top.length >= _topShelfMin) SliverToBoxAdapter(child: _TopBand(products: top)),
            for (final shelf in shelves)
              SliverToBoxAdapter(
                child: _Shelf(
                  title: shelf.title,
                  icon: petIcon(shelf.id, stroke: 300),
                  iconTint: petTint(shelf.id),
                  products: shelf.items.take(_shelfMax).toList(),
                  onAll: () => openCatalogPage(CatalogFilters(pet: shelf.id)),
                ),
              ),
          ];
        }),
      ],
    );
  }
}

/// Logo, "ZOOTOPIA", shior va qidiruv tugmasi.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(kGutter, kSpace2, kGutter, kSpace4),
        child: Row(
          children: [
            Semantics(
              label: Brand.name,
              header: true,
              excludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(height: 39),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Wordmark(height: 19),
                      const SizedBox(height: 3),
                      Text(tr.tagline, style: sans(kText2xs, weight: FontWeight.w600, color: kMuted, height: 1.2)),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            CircleButton(icon: LucideIcons.search, label: tr.openSearch, onTap: openSearch),
          ],
        ),
      );
}

/// Hayvon plitkalari (sarlavhasiz): mahsuloti bor har hayvonga bitta, yonma-yon suriladi.
class _PetPicker extends StatelessWidget {
  final List<PetGroup> groups;
  const _PetPicker({required this.groups});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: kSpace5),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: kGutter),
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final (i, g) in groups.indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                _PetTile(group: g),
              ],
            ],
          ),
        ),
      );
}

class _PetTile extends StatelessWidget {
  final PetGroup group;
  const _PetTile({required this.group});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${group.label}, ${tr.products(group.count)}',
        excludeSemantics: true,
        child: Pressable(
          onTap: () => openCatalogPage(CatalogFilters(pet: group.id)),
          pressedScale: .96,
          child: Container(
            width: 128,
            constraints: const BoxConstraints(minHeight: 144),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: petTint(group.id), borderRadius: BorderRadius.circular(kRadiusXl)),
            child: Stack(
              children: [
                // Burchakdagi muhrdek yumshoq doira.
                const Positioned(
                  right: -26,
                  bottom: -26,
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: DecoratedBox(decoration: BoxDecoration(color: Color(0x59FFFFFF), shape: BoxShape.circle)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(color: kSurface, shape: BoxShape.circle, boxShadow: kShadowSm),
                        child: Icon(petIcon(group.id, stroke: 300), size: 30, color: kBrand),
                      ),
                      const SizedBox(height: 10),
                      Text(group.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: display(17)),
                      const SizedBox(height: 1),
                      Text(tr.products(group.count), maxLines: 1, overflow: TextOverflow.ellipsis, style: sans(kText2xs, weight: FontWeight.w600, color: kMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// "Barchasi →" tugmasi; ko'p sotilganlar fonida to'q, javonlarda oq.
class _SeeAll extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool onDark;
  const _SeeAll({required this.title, required this.onTap, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? kOnDark : kInk;
    return Semantics(
      button: true,
      label: tr.seeAllOf(title),
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: kSpace3),
          decoration: BoxDecoration(
            color: onDark ? kDarkRaised : kSurface,
            borderRadius: BorderRadius.circular(kRadiusFull),
            boxShadow: onDark ? null : kShadowSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr.seeAll, style: sans(kTextXs, weight: FontWeight.w700, color: fg)),
              const SizedBox(width: 4),
              Icon(LucideIcons.arrowRight, size: 14, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ko'p sotilganlar to'q yashil fonda (menyu rangida), boshqa javonlardan
/// ajralib turadi: xantal doirada olov, "Xaridorlar tanlovi" va sarlavha.
class _TopBand extends StatelessWidget {
  final List<Product> products;
  const _TopBand({required this.products});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(_bandInset, 0, _bandInset, kSpace6),
        padding: const EdgeInsets.only(top: kSpace4, bottom: kSpace3),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: kDark, borderRadius: BorderRadius.circular(32)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kGutter - _bandInset),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: kSun, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.flame, size: 21, color: kOnSun),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.bestEyebrow.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: sans(kText2xs, weight: FontWeight.w700, color: kSun, height: 1.3).copyWith(letterSpacing: kText2xs * .06),
                        ),
                        const SizedBox(height: 1),
                        Text(tr.bestTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: display(kTextXl, color: kOnDark, height: 1.1)),
                      ],
                    ),
                  ),
                  const SizedBox(width: kSpace2),
                  _SeeAll(title: tr.bestTitle, onTap: () => openCatalogPage(), onDark: true),
                ],
              ),
            ),
            const SizedBox(height: kSpace4),
            ProductRail(products: products, inset: kGutter - _bandInset),
          ],
        ),
      );
}

/// Javon: belgili sarlavha, "Barchasi →" va gorizontal kartalar qatori.
class _Shelf extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconTint;
  final List<Product> products;
  final VoidCallback onAll;
  const _Shelf({required this.title, required this.icon, required this.iconTint, required this.products, required this.onAll});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: kSpace5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Gutter(
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: iconTint, shape: BoxShape.circle),
                    child: Icon(icon, size: 20, color: kBrand),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: display(kTextXl, height: 1.15))),
                  const SizedBox(width: kSpace2),
                  _SeeAll(title: title, onTap: onAll),
                ],
              ),
            ),
            const SizedBox(height: kSpace3),
            ProductRail(products: products),
          ],
        ),
      );
}
