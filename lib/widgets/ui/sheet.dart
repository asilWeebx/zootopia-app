import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../config/theme.dart';
import '../../l10n/strings.dart';

/// Saytdagi dialog fonining rangi: rgb(31 43 36 / 45%).
const kBackdrop = Color(0x731F2B24);

/// Yumaloq yopish tugmasi (44px, sarlavha o'ngida).
class CloseCircle extends StatelessWidget {
  final VoidCallback onTap;
  /// Bo'sh bo'lsa — 'Yopish' / 'Закрыть'.
  final String? label;
  final double size;
  const CloseCircle({super.key, required this.onTap, this.label, this.size = 44});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label ?? tr.close,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(color: kSurfaceMuted, shape: BoxShape.circle),
            child: Icon(LucideIcons.x, size: size >= 44 ? 22 : 20, color: kInk),
          ),
        ),
      );
}

/// Dialog ichi: sarlavha + yopish, aylanadigan tana, ixtiyoriy pastki qism.
class SheetFrame extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? footer;
  final bool fullScreen;
  /// Tana o'zi aylanadigan bo'lsa (ro'yxat) — false.
  final bool scrollBody;
  const SheetFrame({super.key, required this.title, required this.body, this.footer, this.fullScreen = false, this.scrollBody = true});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final head = Padding(
      padding: EdgeInsets.fromLTRB(kSpace5, kSpace4 + (fullScreen ? media.padding.top : 0), kSpace5, kSpace4),
      child: Row(
        children: [
          Expanded(child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: display(kTextXl))),
          const SizedBox(width: kSpace4),
          CloseCircle(onTap: () => Navigator.of(context).maybePop(), label: tr.closeOf(title)),
        ],
      ),
    );
    final bottomInset = footer == null ? media.padding.bottom + media.viewInsets.bottom : 0.0;
    final content = scrollBody
        ? SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(kSpace5, 0, kSpace5, kSpace5 + bottomInset),
            child: body,
          )
        : Padding(padding: EdgeInsets.only(bottom: bottomInset), child: body);
    return Column(
      mainAxisSize: fullScreen ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        head,
        if (fullScreen) Expanded(child: content) else Flexible(child: content),
        if (footer != null)
          Container(
            padding: EdgeInsets.fromLTRB(kSpace5, kSpace4, kSpace5, kSpace5 + media.padding.bottom),
            decoration: const BoxDecoration(
              color: kSurface,
              border: Border(top: BorderSide(color: kBorder)),
            ),
            child: footer,
          ),
      ],
    );
  }
}

/// Pastdan chiqadigan dialog (qidiruv, tez tanlash): ekranning 90%igacha.
Future<T?> showSiteSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  WidgetBuilder? footer,
  String name = '/sheet',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: kBg,
    barrierColor: kBackdrop,
    elevation: 0,
    routeSettings: RouteSettings(name: name),
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusXl))),
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: footer != null ? MediaQuery.viewInsetsOf(context).bottom : 0),
      child: SheetFrame(title: title, body: Builder(builder: builder), footer: footer == null ? null : Builder(builder: footer)),
    ),
  );
}
