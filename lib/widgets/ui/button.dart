import 'package:flutter/material.dart';

import '../../config/theme.dart';

enum ButtonVariant { primary, secondary, dark, ghost }

enum ButtonSize { sm, md, lg }

/// Saytdagi `Button`: yumaloq "pill", Nunito 800; bosilganda biroz kichrayadi.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool block;
  final IconData? icon;
  final double? iconSize;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.md,
    this.block = false,
    this.icon,
    this.iconSize,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final (height, padding, fontSize) = switch (widget.size) {
      ButtonSize.sm => (38.0, kSpace4, kTextSm),
      ButtonSize.md => (46.0, kSpace5, kTextMd),
      ButtonSize.lg => (54.0, kSpace6, kTextLg),
    };
    final (bg, fg, border, shadow) = switch (widget.variant) {
      ButtonVariant.primary => (kAccent, kOnAccent, null, const [BoxShadow(color: Color(0x38BF4F27), blurRadius: 14, offset: Offset(0, 4))]),
      ButtonVariant.secondary => (kSurface, kInk, Border.all(color: kBorderStrong, width: 1.5), null),
      ButtonVariant.dark => (kBrand, kOnBrand, null, null),
      ButtonVariant.ghost => (Colors.transparent, kInkSoft, null, null),
    };
    final content = Row(
      mainAxisSize: widget.block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: widget.iconSize ?? fontSize + 2, color: fg),
          const SizedBox(width: kSpace2),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: display(fontSize, weight: FontWeight.w800, color: fg, letterSpacing: fontSize * .01),
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _down ? .97 : 1,
          duration: kDuration,
          curve: kEase,
          child: Opacity(
            opacity: enabled ? 1 : .55,
            child: AnimatedContainer(
              duration: kDuration,
              constraints: BoxConstraints(minHeight: height),
              padding: EdgeInsets.symmetric(horizontal: padding),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(kRadiusFull),
                border: border,
                boxShadow: enabled ? shadow : null,
              ),
              alignment: widget.block ? Alignment.center : null,
              child: widget.block ? content : Center(widthFactor: 1, heightFactor: 1, child: content),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bosilganda biroz kichrayadigan oddiy bosiladigan maydon (havola o'rnida).
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  const Pressable({super.key, required this.child, this.onTap, this.pressedScale = .98});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
        onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
        onTapCancel: widget.onTap == null ? null : () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(scale: _down ? widget.pressedScale : 1, duration: kDuration, curve: kEase, child: widget.child),
      );
}
