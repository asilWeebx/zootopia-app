import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/theme.dart';
import '../../state/scope.dart';

/// "Savatga qo'shildi"ning ko'rinishi: kichik panja tugmadan savat belgisiga
/// sakraydi, belgi esa silkinadi. Savat holati har doim avval o'zgaradi —
/// bu faqat bezak (saytdagi `cartFeedback`).
class CartFeedback {
  CartFeedback._();

  /// Savat belgilari (pastki menyuda va mahsulot sahifasida) — panja ochiq
  /// sahifadagisiga uchadi.
  static final _targets = <_CartTargetState>[];
  /// Belgi silkinishi uchun hisoblagich.
  static final bounce = ValueNotifier<int>(0);
  static final flights = ValueNotifier<List<_Flight>>(const []);
  static int _id = 0;

  static RenderBox? _targetBox() {
    for (final t in _targets.reversed) {
      if (!t.mounted || ModalRoute.of(t.context)?.isCurrent == false) continue;
      final box = t.context.findRenderObject() as RenderBox?;
      if (box != null && box.attached && box.hasSize) return box;
    }
    return null;
  }

  static void fire(BuildContext from) {
    if (from.readHaptics.value) HapticFeedback.lightImpact();
    if (MediaQuery.of(from).disableAnimations) return;
    final targetBox = _targetBox();
    if (targetBox == null) return;
    Future.delayed(const Duration(milliseconds: 380), () => bounce.value++);
    final fromBox = from.findRenderObject() as RenderBox?;
    if (fromBox == null || !fromBox.attached) return;
    final start = fromBox.localToGlobal(fromBox.size.center(Offset.zero));
    final end = targetBox.localToGlobal(targetBox.size.center(Offset.zero));
    final flight = _Flight(++_id, start, end);
    flights.value = [...flights.value, flight];
    Future.delayed(const Duration(milliseconds: 620), () {
      flights.value = flights.value.where((f) => f.id != flight.id).toList();
    });
  }
}

/// Panja uchib keladigan savat belgisi; bir nechtasi bo'lishi mumkin.
class CartTarget extends StatefulWidget {
  final Widget child;
  const CartTarget({super.key, required this.child});

  @override
  State<CartTarget> createState() => _CartTargetState();
}

class _CartTargetState extends State<CartTarget> {
  @override
  void initState() {
    super.initState();
    CartFeedback._targets.add(this);
  }

  @override
  void dispose() {
    CartFeedback._targets.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _Flight {
  final int id;
  final Offset start;
  final Offset end;
  const _Flight(this.id, this.start, this.end);
}

/// Hamma narsa ustidagi qatlam — uchayotgan panjalar shu yerda chiziladi.
class PawLayer extends StatelessWidget {
  const PawLayer({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ValueListenableBuilder<List<_Flight>>(
          valueListenable: CartFeedback.flights,
          builder: (context, flights, _) => Stack(
            children: [for (final f in flights) _PawFlight(key: ValueKey(f.id), flight: f)],
          ),
        ),
      );
}

class _PawFlight extends StatefulWidget {
  final _Flight flight;
  const _PawFlight({super.key, required this.flight});

  @override
  State<_PawFlight> createState() => _PawFlightState();
}

class _PawFlightState extends State<_PawFlight> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = const Cubic(.3, .6, .3, 1).transform(_ctrl.value);
          final d = widget.flight.end - widget.flight.start;
          // Uch nuqta: boshlanish, yarim yo'lda 60px yuqorida, oxiri.
          final Offset offset;
          final double rotate, scale, opacity;
          if (t < .5) {
            final k = t / .5;
            offset = Offset(d.dx * .5 * k, (d.dy * .5 - 60) * k);
            rotate = -20 * k;
            scale = 1.2 - .2 * k;
            opacity = 1;
          } else {
            final k = (t - .5) / .5;
            offset = Offset(d.dx * (.5 + .5 * k), (d.dy * .5 - 60) + (d.dy * .5 + 60) * k);
            rotate = -20 + 30 * k;
            scale = 1 - .6 * k;
            opacity = 1 - .7 * k;
          }
          final p = widget.flight.start + offset;
          return Positioned(
            left: p.dx - 10,
            top: p.dy - 10,
            child: Opacity(
              opacity: opacity,
              child: Transform.rotate(
                angle: rotate * 3.1415926 / 180,
                child: Transform.scale(scale: scale, child: const CustomPaint(size: Size(20, 20), painter: PawPainter(kAccent))),
              ),
            ),
          );
        },
      );
}

/// Saytdagi panja izi (24×24 viewBox).
class PawPainter extends CustomPainter {
  final Color color;
  const PawPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()..color = color;
    for (final (x, y) in const [(5.5, 10.0), (9.5, 5.5), (14.5, 5.5), (18.5, 10.0)]) {
      canvas.drawCircle(Offset(x * s, y * s), 2.2 * s, paint);
    }
    final pad = Path()
      ..moveTo(12 * s, 11 * s)
      ..cubicTo(8.8 * s, 11 * s, 6 * s, 14.6 * s, 6 * s, 17.2 * s)
      ..cubicTo(6 * s, 18.8 * s, 7.2 * s, 19.5 * s, 8.6 * s, 19.5 * s)
      ..cubicTo(9.9 * s, 19.5 * s, 10.7 * s, 18.8 * s, 12 * s, 18.8 * s)
      ..cubicTo(13.3 * s, 18.8 * s, 14.1 * s, 19.5 * s, 15.4 * s, 19.5 * s)
      ..cubicTo(16.8 * s, 19.5 * s, 18 * s, 18.8 * s, 18 * s, 17.2 * s)
      ..cubicTo(18 * s, 14.6 * s, 15.2 * s, 11 * s, 12 * s, 11 * s)
      ..close();
    canvas.drawPath(pad, paint);
  }

  @override
  bool shouldRepaint(PawPainter old) => old.color != color;
}

/// Savat belgisi: `CartFeedback.bounce` o'zgarganda kattalashib, burilib qaytadi.
class BouncingCartIcon extends StatefulWidget {
  final Widget child;
  const BouncingCartIcon({super.key, required this.child});

  @override
  State<BouncingCartIcon> createState() => _BouncingCartIconState();
}

class _BouncingCartIconState extends State<BouncingCartIcon> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void initState() {
    super.initState();
    CartFeedback.bounce.addListener(_play);
  }

  void _play() => _ctrl.forward(from: 0);

  @override
  void dispose() {
    CartFeedback.bounce.removeListener(_play);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = _ctrl.value;
          final k = t < .5 ? t / .5 : (1 - t) / .5;
          return Transform.rotate(
            angle: -8 * k * 3.1415926 / 180,
            child: Transform.scale(scale: 1 + .25 * k, child: child),
          );
        },
        child: widget.child,
      );
}
