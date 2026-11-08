import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Bir-birini istisno qiladigan tanlovlar qatori (Kuryer | Olib ketish).
class Segmented<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  const Segmented({super.key, required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: kSurfaceMuted, borderRadius: BorderRadius.circular(kRadiusFull)),
        child: Row(
          children: [
            for (final (i, (option, label)) in options.indexed) ...[
              if (i > 0) const SizedBox(width: kSpace1),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(option),
                  child: AnimatedContainer(
                    duration: kDuration,
                    constraints: const BoxConstraints(minHeight: 42),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: kSpace4 - 4),
                    decoration: BoxDecoration(
                      color: option == value ? kSurface : Colors.transparent,
                      borderRadius: BorderRadius.circular(kRadiusFull),
                      boxShadow: option == value ? kShadowSm : null,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: sans(kTextSm,
                          weight: option == value ? FontWeight.w700 : FontWeight.w600,
                          color: option == value ? kBrand : kInkSoft),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

/// Bo'sh holat kartasi: belgili doira, sarlavha, matn va amal.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? text;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, this.text, this.action});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          margin: const EdgeInsets.symmetric(vertical: kSpace12),
          padding: const EdgeInsets.symmetric(vertical: kSpace10, horizontal: kSpace6),
          decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(kRadiusXl), boxShadow: kShadowSm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(color: kSunSoft, shape: BoxShape.circle),
                child: Icon(icon, size: 32, color: kBark),
              ),
              const SizedBox(height: kSpace2 + kSpace3),
              Text(title, textAlign: TextAlign.center, style: display(kTextXl)),
              if (text != null) ...[
                const SizedBox(height: kSpace3),
                Text(text!, textAlign: TextAlign.center, style: sans(kTextMd, color: kMuted, height: 1.55)),
              ],
              if (action != null) ...[const SizedBox(height: kSpace6), action!],
            ],
          ),
        ),
      );
}

/// Yuklanayotgan joy — sekin "nafas oladigan" bo'sh shakl.
class Pulse extends StatefulWidget {
  final Widget child;
  const Pulse({super.key, required this.child});

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 1.0, end: .55).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
        child: widget.child,
      );
}

/// Yumaloq kulrang blok (skelet).
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;
  const SkeletonBox({super.key, this.width, this.height, this.radius = kRadiusXl});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: kSurfaceMuted, borderRadius: BorderRadius.circular(radius)),
      );
}

/// "XARIDNI BOSHLANG" — sarlavha ustidagi yorliq.
class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  const Eyebrow(this.text, {super.key, this.color = kAccentInk});

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: eyebrow(color: color));
}
