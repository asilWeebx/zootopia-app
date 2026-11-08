import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/pets.dart';
import '../config/theme.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/catalog.dart';
import '../services/groups.dart';
import '../services/pets.dart';
import '../state/scope.dart';
import '../widgets/layout/page.dart';
import '../widgets/product/product_grid.dart';
import '../widgets/ui/basics.dart';
import '../widgets/ui/button.dart';
import '../widgets/ui/pet_art.dart';
import '../widgets/ui/sheet.dart';

/// Mahsulot turlarining belgilari (saytdagi `TYPE_ICONS`).
IconData typeIcon(ProductTypeId id) => switch (id) {
      ProductTypeId.vitamin => LucideIcons.pill,
      ProductTypeId.treat => LucideIcons.bone,
      ProductTypeId.wet => LucideIcons.soup,
      ProductTypeId.litter => LucideIcons.shovel,
      ProductTypeId.care => LucideIcons.bath,
      ProductTypeId.dry => LucideIcons.wheat,
    };

/// "Mushuklar · Nam ozuqa", bo'lim, qidiruv yoki hammasi.
String _pageTitle(CatalogFilters f, Category? category) {
  final pet = f.pet == null ? null : petLabel(f.pet!);
  final type = f.type == null ? null : typeLabel(f.type!);
  final title = [?pet, ?type, ?category?.name].join(' · ');
  return title.isEmpty ? tr.allProducts : title;
}

/// Katalog — Asosiy tab ustida ochiladi (saytdagi `/catalog`; filtrlar URL
/// o'rnida holatda). Filtrlar har ta'mga qaraydi, to'r esa har guruhni bir
/// marta ko'rsatadi.
class CatalogScreen extends StatefulWidget {
  final CatalogFilters initial;
  final bool focusSearch;
  const CatalogScreen({super.key, this.initial = const CatalogFilters(), this.focusSearch = false});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late CatalogFilters _filters = widget.initial;
  late final _query = TextEditingController(text: widget.initial.query);
  final _queryFocus = FocusNode();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.focusSearch) WidgetsBinding.instance.addPostFrameCallback((_) => _queryFocus.requestFocus());
  }

  void _set(CatalogFilters next) {
    setState(() => _filters = next);
    if (_query.text != next.query) _query.text = next.query;
    if (_scroll.hasClients && _scroll.offset > 0) _scroll.jumpTo(0);
  }

  @override
  void dispose() {
    _query.dispose();
    _queryFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.catalog;
    return TabPage(
      controller: _scroll,
      slivers: catalogGate(context, () {
        final f = _filters;
        final products = catalog.products;
        final cards = catalog.cards;
        final category = catalog.categories.where((c) => c.id == f.categoryId).firstOrNull;
        final results = collapseGroups(filterProducts(products, f), catalog.groups);
        final suggestions = results.isEmpty && f.query.trim().isNotEmpty
            ? collapseGroups(searchSuggestions(f.query, products, 40), catalog.groups).take(8).toList()
            : const <Product>[];
        // Turlar va bo'limlar tanlangan hayvon ichida, kartalarda sanaladi — raqam bosilganda chiqqaniga teng.
        final forPet = f.pet != null ? cards.where((p) => matchesPet(p, f.pet!)).toList() : cards;
        final categoryCounts = {for (final c in catalog.categories) c.id: productsInCategory(forPet, c.id).length};
        final types = typeGroups(forPet);
        final title = f.query.trim().isNotEmpty ? '“${f.query.trim()}”' : _pageTitle(f, category);

        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(kGutter, kSpace2, kGutter, kSpace3),
              child: Row(
                children: [
                  CircleButton(icon: LucideIcons.chevronLeft, label: tr.back, onTap: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: kSpace3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: display(kTextXl, height: 1.15)),
                        Text(tr.products(results.length), style: sans(kTextXs, color: kMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: kSpace2),
                  _FiltersButton(
                    activeCount: f.activeCount + (f.sort != SortKey.recommended ? 1 : 0),
                    onTap: () => _openFilters(categoryCounts: categoryCounts, hasSales: products.any(isDiscounted)),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Gutter(
              child: _SearchField(
                controller: _query,
                focusNode: _queryFocus,
                onChanged: (q) => setState(() => _filters = _filters.copyWith(query: q)),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _PetChips(filters: f, pets: petGroups(cards), total: cards.length, onChange: _set)),
          if (types.isNotEmpty) SliverToBoxAdapter(child: _KindTabs(filters: f, types: types, onChange: _set)),
          const SliverToBoxAdapter(child: SizedBox(height: kSpace3)),
          if (results.isNotEmpty)
            SliverToBoxAdapter(child: Gutter(child: ProductGrid(products: results)))
          else ...[
            SliverToBoxAdapter(
              child: Gutter(
                child: EmptyState(
                  icon: LucideIcons.searchX,
                  title: tr.emptyTitle,
                  text: tr.emptyText,
                  action: AppButton(label: tr.allProducts, variant: ButtonVariant.secondary, onPressed: () => _set(const CatalogFilters())),
                ),
              ),
            ),
            if (suggestions.isNotEmpty)
              SliverToBoxAdapter(
                child: Gutter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(tr.suggestions, style: display(kTextXl)),
                      const SizedBox(height: kSpace4),
                      ProductGrid(products: suggestions),
                    ],
                  ),
                ),
              ),
          ],
        ];
      }),
    );
  }

  void _openFilters({required Map<int, int> categoryCounts, required bool hasSales}) {
    final categories = context.readCatalog.categories;
    showSiteSheet<void>(
      context,
      title: tr.filters,
      name: '/sheet/filters',
      builder: (sheetContext) => _FilterPanel(
        filters: _filters,
        categories: categories,
        categoryCounts: categoryCounts,
        hasSales: hasSales,
        onChange: (next) {
          Navigator.of(sheetContext).pop();
          _set(next);
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.focusNode, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        padding: const EdgeInsets.only(left: kSpace4, right: kSpace1),
        decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(kRadiusFull), boxShadow: kShadowSm),
        child: Row(
          children: [
            const Icon(LucideIcons.search, size: 20, color: kMuted),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autocorrect: false,
                textInputAction: TextInputAction.search,
                style: sans(kTextSm),
                decoration: InputDecoration.collapsed(hintText: tr.searchPlaceholder, hintStyle: sans(kTextSm, color: kMuted)),
                onChanged: onChanged,
                onTapOutside: (_) => focusNode.unfocus(),
              ),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => controller.text.isEmpty
                  ? const SizedBox(width: kSpace3)
                  : Semantics(
                      button: true,
                      label: tr.clearSearch,
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          controller.clear();
                          onChanged('');
                        },
                        child: const SizedBox(width: 44, height: 44, child: Icon(LucideIcons.x, size: 18, color: kMuted)),
                      ),
                    ),
            ),
          ],
        ),
      );
}

/// "Hammasi · Mushuklar · Itlar ·…" — har biri o'z hayvon fonida, tanlangani yashil.
class _PetChips extends StatelessWidget {
  final CatalogFilters filters;
  final List<PetGroup> pets;
  final int total;
  final ValueChanged<CatalogFilters> onChange;
  const _PetChips({required this.filters, required this.pets, required this.total, required this.onChange});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(kGutter, kSpace3, kGutter, kSpace1),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _chip(null, tr.all, total, filters.pet == null),
            for (final pet in pets) ...[
              const SizedBox(width: kSpace2),
              _chip(pet.id, pet.label, pet.count, filters.pet == pet.id),
            ],
          ],
        ),
      );

  Widget _chip(PetId? pet, String label, int count, bool selected) {
    final fg = selected ? kOnBrand : kInk;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count',
      excludeSemantics: true,
      child: Pressable(
        onTap: () => onChange(filters.copyWith(pet: pet)),
        child: AnimatedContainer(
          duration: kDuration,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(color: selected ? kBrand : petTint(pet ?? PetId.other), borderRadius: BorderRadius.circular(kRadiusFull)),
          child: Row(
            children: [
              Icon(petIcon(pet ?? PetId.other, stroke: 300), size: 18, color: fg),
              const SizedBox(width: 6),
              Text(label, style: sans(13, weight: FontWeight.w700, color: fg)),
              const SizedBox(width: 6),
              Text('$count', style: display(kTextXs, weight: FontWeight.w800, color: fg.withValues(alpha: .75))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mahsulot turlari — tagi chizilgan yorliqlar.
class _KindTabs extends StatelessWidget {
  final CatalogFilters filters;
  final List<TypeGroup> types;
  final ValueChanged<CatalogFilters> onChange;
  const _KindTabs({required this.filters, required this.types, required this.onChange});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(kGutter, kSpace2, kGutter, 0),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _tab(null, tr.all, null, filters.type == null),
            for (final t in types) ...[
              const SizedBox(width: kSpace5),
              _tab(t.id, t.label, typeIcon(t.id), filters.type == t.id),
            ],
          ],
        ),
      );

  Widget _tab(ProductTypeId? id, String label, IconData? icon, bool on) {
    final color = on ? kBrand : kMuted;
    return Semantics(
      button: true,
      selected: on,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChange(filters.copyWith(type: id)),
        child: AnimatedContainer(
          duration: kDuration,
          height: 40,
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: on ? kBrand : Colors.transparent, width: 2))),
          child: Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 15, color: color), const SizedBox(width: 5)],
              Text(label, style: sans(13, weight: on ? FontWeight.w700 : FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltersButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;
  const _FiltersButton({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: activeCount > 0 ? tr.filtersActive(activeCount) : tr.filters,
        excludeSemantics: true,
        child: Pressable(
          onTap: onTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: kSpace3 + 2),
            decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(kRadiusFull), boxShadow: kShadowSm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.slidersHorizontal, size: 18, color: kInk),
                const SizedBox(width: 6),
                Text(tr.filters, style: sans(13, weight: FontWeight.w600)),
                if (activeCount > 0) ...[
                  const SizedBox(width: 6),
                  CountBadge(activeCount),
                ],
              ],
            ),
          ),
        ),
      );
}

/// Bo'lim, mavjudlik va tartib. Hayvon va tur sahifaning o'zida tanlanadi.
class _FilterPanel extends StatelessWidget {
  final CatalogFilters filters;
  final List<Category> categories;
  final Map<int, int> categoryCounts;
  final bool hasSales;
  final ValueChanged<CatalogFilters> onChange;

  const _FilterPanel({
    required this.filters,
    required this.categories,
    required this.categoryCounts,
    required this.hasSales,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final f = filters;
    // Hayvon ichida bo'sh bo'limlar — shovqin; tanlangani esa tozalash uchun qoladi.
    final tops = topCategories(categories).where((c) => (categoryCounts[c.id] ?? 0) > 0 || c.id == f.categoryId).toList();

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(bottom: kSpace2),
          child: Text(text, style: display(kTextMd)),
        );

    Widget option(String label, int? count, bool current, VoidCallback onTap, {bool child = false}) => Padding(
          padding: EdgeInsets.only(left: child ? kSpace3 : 0, bottom: 2),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: kSpace3, vertical: kSpace2),
              decoration: BoxDecoration(color: current ? kBrandSoft : Colors.transparent, borderRadius: BorderRadius.circular(kRadiusFull)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label, style: sans(kTextSm, weight: current ? FontWeight.w700 : FontWeight.w400, color: current ? kBrand : kInkSoft)),
                  ),
                  if (count != null) Text('$count', style: sans(kTextXs, color: kMuted)),
                  if (current) ...[const SizedBox(width: kSpace2), const Icon(LucideIcons.check, size: 16, color: kBrand)],
                ],
              ),
            ),
          ),
        );

    Widget toggle(String label, bool on, VoidCallback onTap) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: kDuration,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: on ? kBrand : kSurface,
                    borderRadius: BorderRadius.circular(kRadiusXs),
                    border: Border.all(color: on ? kBrand : kBorderStrong, width: 1.5),
                  ),
                  child: on ? const Icon(LucideIcons.check600, size: 14, color: kOnBrand) : null,
                ),
                const SizedBox(width: kSpace3),
                Text(label, style: sans(kTextSm, weight: FontWeight.w600)),
              ],
            ),
          ),
        );

    final sections = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading(tr.sort),
          for (final (key, label) in kSortOptions) option(label, null, f.sort == key, () => onChange(f.copyWith(sort: key))),
        ],
      ),
      if (tops.length > 1)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading(tr.sections),
            option(tr.all, null, f.categoryId == null, () => onChange(f.copyWith(categoryId: null))),
            for (final c in tops) ...[
              option(c.name, categoryCounts[c.id] ?? 0, f.categoryId == c.id, () => onChange(f.copyWith(categoryId: c.id))),
              for (final child in categories.where((x) => x.parentId == c.id && (categoryCounts[x.id] ?? 0) > 0))
                option(child.name.split(' › ').last, categoryCounts[child.id] ?? 0, f.categoryId == child.id,
                    () => onChange(f.copyWith(categoryId: child.id)),
                    child: true),
            ],
          ],
        ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading(tr.show),
          toggle(tr.inStockOnly, f.inStockOnly, () => onChange(f.copyWith(inStockOnly: !f.inStockOnly))),
          if (hasSales) toggle(tr.onSale, f.saleOnly, () => onChange(f.copyWith(saleOnly: !f.saleOnly))),
        ],
      ),
      if (f.activeCount > 0 || f.sort != SortKey.recommended)
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => onChange(f.cleared().copyWith(sort: SortKey.recommended)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: kSpace2),
              child: Text(
                tr.clearFilters,
                style: sans(kTextSm, weight: FontWeight.w700, color: kAccentInk).copyWith(decoration: TextDecoration.underline, decorationColor: kAccentInk),
              ),
            ),
          ),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, s) in sections.indexed) ...[if (i > 0) const SizedBox(height: kSpace6), s],
      ],
    );
  }
}
