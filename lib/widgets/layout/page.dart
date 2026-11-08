import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../config/theme.dart';
import '../../l10n/strings.dart';
import '../../state/catalog_controller.dart';
import '../../state/scope.dart';
import '../ui/basics.dart';
import '../ui/button.dart';

/// Tab sahifasining qolipi: holat paneli ostidan boshlanadi (aylangan matn
/// soat ostiga kirmaydi), pastga tortib katalog yangilanadi, oxirida pastki
/// menyu (va [bottom]dagi qo'shimcha panel) uchun joy qoladi.
class TabPage extends StatelessWidget {
  final List<Widget> slivers;
  final ScrollController? controller;
  /// Menyu ustida turadigan panel (savatdagi "Jami") balandligi.
  final double bottom;
  /// Sahifa ustida suzib turadigan narsa (savatning "Jami" paneli).
  final Widget? overlay;
  const TabPage({super.key, required this.slivers, this.controller, this.bottom = 0, this.overlay});

  @override
  Widget build(BuildContext context) {
    final catalog = context.readCatalog;
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: media.padding.top),
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: RefreshIndicator(
                color: kBrand,
                backgroundColor: kSurface,
                onRefresh: catalog.load,
                child: CustomScrollView(
                  controller: controller,
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    ...slivers,
                    SliverToBoxAdapter(child: SizedBox(height: navClearance(context) + bottom + kSpace4)),
                  ],
                ),
              ),
            ),
          ),
          ?overlay,
        ],
      ),
    );
  }
}

/// Tablar ustidagi sahifa (rasmiylashtirish, maxfiylik, kabinet bo'limlari):
/// chapda orqaga tugmasi va sarlavha, pastki menyusiz.
class DetailPage extends StatelessWidget {
  final String title;
  final List<Widget> slivers;
  const DetailPage({super.key, required this.title, required this.slivers});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: kBg,
      body: Padding(
        padding: EdgeInsets.only(top: media.padding.top),
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(kGutter, kSpace2, kGutter, kSpace4),
                  child: Row(
                    children: [
                      CircleButton(icon: LucideIcons.chevronLeft, label: tr.back, onTap: () => Navigator.of(context).maybePop()),
                      const SizedBox(width: kSpace3),
                      Expanded(
                        child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: display(kTextXl + 2, height: 1.15)),
                      ),
                    ],
                  ),
                ),
              ),
              ...slivers,
              SliverToBoxAdapter(child: SizedBox(height: kSpace8 + media.padding.bottom)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 44px oq yumaloq tugma: orqaga, qidiruv, savat.
class CircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? badge;
  final double iconSize;
  const CircleButton({super.key, required this.icon, required this.label, required this.onTap, this.badge, this.iconSize = 22});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Pressable(
          onTap: onTap,
          pressedScale: .94,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: kSurface, shape: BoxShape.circle, boxShadow: kShadowSm),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, size: iconSize, color: kInk),
                if (badge != null) Positioned(top: -2, right: -2, child: badge!),
              ],
            ),
          ),
        ),
      );
}

/// Savatdagi soni: terrakota doira, oq chegarasi bilan.
class CountBadge extends StatelessWidget {
  final int count;
  final Color border;
  const CountBadge(this.count, {super.key, this.border = kSurface});

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 18),
        height: 18,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: kAccent,
          borderRadius: BorderRadius.circular(kRadiusFull),
          border: Border.all(color: border, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(count > 99 ? '99+' : '$count', style: display(10, color: kOnAccent, height: 1)),
      );
}

/// Sahifa chekkasidagi bo'shliq (`Container` — `--gutter`).
class Gutter extends StatelessWidget {
  final Widget child;
  final EdgeInsets extra;
  const Gutter({super.key, required this.child, this.extra = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: kGutter).add(extra), child: child);
}

/// API kalitni rad etgan yoki yetib bo'lmagan payt katalog o'rnida.
class SetupNotice extends StatelessWidget {
  const SetupNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.catalog;
    final auth = catalog.reason == FailureReason.auth;
    return Gutter(
      child: EmptyState(
        icon: LucideIcons.circleAlert,
        title: auth ? tr.authTitle : tr.unavailableTitle,
        text: auth ? tr.authText : tr.unavailableText,
        action: AppButton(
          label: catalog.loading ? tr.loading : tr.retry,
          variant: ButtonVariant.secondary,
          onPressed: catalog.loading ? null : catalog.load,
        ),
      ),
    );
  }
}

/// Katalog kelguncha: sarlavha va kartalar o'rnida "nafas oladigan" shakllar.
class LoadingSkeleton extends StatelessWidget {
  final int cards;
  const LoadingSkeleton({super.key, this.cards = 4});

  @override
  Widget build(BuildContext context) => Gutter(
        extra: const EdgeInsets.only(top: kSpace4),
        child: Pulse(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, box) => SkeletonBox(
                  height: 36,
                  radius: kRadiusFull,
                  width: box.maxWidth * .7 < 320 ? box.maxWidth * .7 : 320,
                ),
              ),
              const SizedBox(height: kSpace6),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: kSpace3,
                crossAxisSpacing: kSpace3,
                childAspectRatio: 3 / 4.4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [for (var i = 0; i < cards; i++) const SkeletonBox()],
              ),
            ],
          ),
        ),
      );
}

/// Katalog holatiga qarab: yuklanmoqda, xato yoki tayyor mazmun.
List<Widget> catalogGate(BuildContext context, List<Widget> Function() ready) {
  final catalog = context.catalog;
  if (catalog.configured) return ready();
  if (catalog.loading) return const [SliverToBoxAdapter(child: LoadingSkeleton())];
  return const [SliverToBoxAdapter(child: SetupNotice())];
}
