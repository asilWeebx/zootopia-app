import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../config/theme.dart';
import '../../l10n/strings.dart';
import 'pet_art.dart';

const _zoomMin = 1.0;
const _zoomMax = 6.0;

/// Mahsulot rasmi to'liq ekranda: chimdib, ikki marta bosib yoki +/− bilan
/// kattalashtiriladi, surib ko'riladi.
Future<void> showLightbox(BuildContext context, {required String src, required String alt}) => showGeneralDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: const Color(0xF5161E19),
      routeSettings: const RouteSettings(name: '/sheet/lightbox'),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => _Lightbox(src: src, alt: alt),
      transitionBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
    );

class _Lightbox extends StatefulWidget {
  final String src;
  final String alt;
  const _Lightbox({required this.src, required this.alt});

  @override
  State<_Lightbox> createState() => _LightboxState();
}

class _LightboxState extends State<_Lightbox> with SingleTickerProviderStateMixin {
  final _ctrl = TransformationController();
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
  Animation<Matrix4>? _tween;
  double _zoom = 1;
  Offset _lastTap = Offset.zero;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final z = _ctrl.value.getMaxScaleOnAxis();
      if ((z - _zoom).abs() > .01) setState(() => _zoom = z);
    });
    _anim.addListener(() {
      if (_tween != null) _ctrl.value = _tween!.value;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _animateTo(Matrix4 target) {
    _tween = Matrix4Tween(begin: _ctrl.value, end: target).animate(CurvedAnimation(parent: _anim, curve: kEase));
    _anim.forward(from: 0);
  }

  /// Ekran markazi atrofida `factor` marta.
  void _zoomBy(double factor, [Offset? focal]) {
    final size = MediaQuery.sizeOf(context);
    final center = focal ?? Offset(size.width / 2, size.height / 2);
    final next = (_zoom * factor).clamp(_zoomMin, _zoomMax);
    if (next == _zoomMin) {
      _animateTo(Matrix4.identity());
      return;
    }
    final k = next / _zoom;
    final m = _ctrl.value.clone()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(k, k, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
    _animateTo(m);
  }

  Widget _button(IconData icon, String label, VoidCallback? onTap) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null ? .4 : 1,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(kRadiusSm)),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          Container(
            color: const Color(0x40000000),
            padding: EdgeInsets.fromLTRB(kSpace2, media.padding.top + kSpace2, kSpace2, kSpace2),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: kSpace2),
                    child: Text(
                      widget.alt.isEmpty ? tr.photo : widget.alt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sans(kTextSm, color: Colors.white),
                    ),
                  ),
                ),
                _button(LucideIcons.zoomOut, tr.zoomOut, _zoom <= _zoomMin + .01 ? null : () => _zoomBy(1 / 1.45)),
                const SizedBox(width: kSpace1),
                GestureDetector(
                  onTap: () => _animateTo(Matrix4.identity()),
                  child: SizedBox(
                    width: 56,
                    height: 44,
                    child: Center(child: Text('${(_zoom * 100).round()}%', style: sans(kTextXs, color: Colors.white))),
                  ),
                ),
                const SizedBox(width: kSpace1),
                _button(LucideIcons.zoomIn, tr.zoomIn, _zoom >= _zoomMax - .01 ? null : () => _zoomBy(1.45)),
                const SizedBox(width: kSpace1),
                _button(LucideIcons.x, tr.close, () => Navigator.of(context).pop()),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onDoubleTapDown: (d) => _lastTap = d.localPosition,
              onDoubleTap: () => _zoom > 1.01 ? _animateTo(Matrix4.identity()) : _zoomBy(2.5, _lastTap),
              onTap: () {
                if (_zoom <= 1.01) Navigator.of(context).pop();
              },
              child: InteractiveViewer(
                transformationController: _ctrl,
                minScale: _zoomMin,
                maxScale: _zoomMax,
                child: SizedBox.expand(
                  child: FractionallySizedBox(
                    widthFactor: .95,
                    heightFactor: .95,
                    child: SafeImage(src: widget.src, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(kSpace5, kSpace3, kSpace5, kSpace3 + media.padding.bottom),
            child: Text(
              tr.lightboxHint,
              textAlign: TextAlign.center,
              style: sans(10, color: Colors.white.withValues(alpha: .65)),
            ),
          ),
        ],
      ),
    );
  }
}
