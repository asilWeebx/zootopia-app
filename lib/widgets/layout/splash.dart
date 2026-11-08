import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/pets.dart';
import '../../config/store.dart';
import '../../config/theme.dart';
import '../../l10n/strings.dart';
import '../ui/pet_art.dart';
import 'brand.dart';

/// Ilova ochilganda (dizayndagi "E · Ochilish"): to'rt hayvon plitkasi navbat
/// bilan paydo bo'lib markazga yig'iladi, o'rnida logo sakrab chiqadi va
/// atrofidan hayvon ranglaridagi halqalar tarqaladi, keyin "ZOOTOPIA" chapdan
/// ochiladi va shior ko'tariladi. Bir marta, ~2.4 s, tarmoqni kutmaydi
/// (katalog orqada yuklanaveradi). Tizimda "harakatni kamaytirish" yoqilgan
/// bo'lsa ko'rsatilmaydi.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key});

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay> with TickerProviderStateMixin {
  late final _play = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  late final _leave = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  bool _started = false;
  bool _done = false;
  Timer? _hold;

  @override
  void initState() {
    super.initState();
    _play.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      _hold = Timer(const Duration(milliseconds: 260), () {
        if (mounted) _leave.forward().whenComplete(() => mounted ? setState(() => _done = true) : null);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _done = true;
      return;
    }
    // Logo tayyor bo'lmasa bo'sh joy sakrardi; uzoq kutilmaydi.
    precacheImage(const AssetImage('assets/brand/logo.png'), context)
        .timeout(const Duration(milliseconds: 600), onTimeout: () {})
        .whenComplete(() {
      if (mounted) _play.forward();
    });
  }

  @override
  void dispose() {
    _hold?.cancel();
    _play.dispose();
    _leave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();
    return IgnorePointer(
      ignoring: _leave.isAnimating,
      child: FadeTransition(
        opacity: ReverseAnimation(_leave),
        // Navigator ustida — matnga Material uslubi shu yerdan beriladi.
        child: Material(
          type: MaterialType.transparency,
          child: AnimatedBuilder(
            animation: _play,
            // Dizayndagi 6 soniyalik halqaning 0–80% qismi bir marta o'ynaydi.
            builder: (context, _) => _Stage(p: _play.value * 80),
          ),
        ),
      ),
    );
  }
}

const _pop = Cubic(.2, .7, .2, 1);
const _bounce = Cubic(.34, 1.4, .64, 1);

/// `p` (dizayn foizida) ning [a, b] oralig'idagi ulushi, egri bo'yicha.
double _seg(double p, double a, double b, [Curve curve = Curves.linear]) => curve.transform(((p - a) / (b - a)).clamp(0.0, 1.0));

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Plitkalar: hayvon, o'rni (markazga nisbatan) va paydo bo'lish boshlanishi (%).
const _tiles = [
  (PetId.cat, Offset(-56, -56), 0.0),
  (PetId.dog, Offset(56, -56), 5.0),
  (PetId.bird, Offset(-56, 56), 10.0),
  (PetId.fish, Offset(56, 56), 15.0),
];

/// Logo atrofidan tarqaladigan halqalar: rangi va kechikishi (%).
const _rings = [(kTintCat, 0.0), (kTintBird, 10 / 3), (kTintFish, 20 / 3)];

class _Stage extends StatelessWidget {
  final double p;
  const _Stage({required this.p});

  @override
  Widget build(BuildContext context) {
    const width = 300.0;
    const height = 330.0;
    const center = Offset(width / 2, 120);
    return ColoredBox(
      color: kBg,
      child: Align(
        alignment: const Alignment(0, -.12),
        child: Semantics(
          label: Brand.name,
          image: true,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final (color, delay) in _rings) _ring(center, color, delay),
                for (final (pet, offset, start) in _tiles) _tile(center, pet, offset, start),
                _logo(center),
                _wordmark(center),
                _tagline(center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(Offset center, PetId pet, Offset offset, double start) {
    final popIn = _seg(p, start, start + 7, _pop);
    final settle = _seg(p, start + 7, start + 10, _pop);
    final gather = _seg(p, 34, 44, _pop);
    final scale = gather > 0 ? _lerp(1, .2, gather) : (settle > 0 ? _lerp(1.06, 1, settle) : _lerp(.4, 1.06, popIn));
    final opacity = gather > 0 ? 1 - gather : popIn;
    // Har plitka markazga qarab yarim yo'l yuradi (dizayndagi ±52px).
    final shift = Offset(-offset.dx.sign * 52, -offset.dy.sign * 52) * gather;
    const side = 96.0;
    final at = center + offset + shift;
    return Positioned(
      left: at.dx - side / 2,
      top: at.dy - side / 2,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: side,
            height: side,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: petTint(pet), borderRadius: BorderRadius.circular(kRadiusXl)),
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(color: kSurface, shape: BoxShape.circle, boxShadow: kShadowSm),
              child: Icon(petIcon(pet, stroke: 300), size: 34, color: kBrand),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ring(Offset center, Color color, double delay) {
    final grow = _seg(p, 42 + delay, 72 + delay, Curves.easeOut);
    final show = _seg(p, 42 + delay, 46 + delay, Curves.easeOut);
    final fade = _seg(p, 46 + delay, 72 + delay, Curves.easeOut);
    final opacity = p < 42 + delay ? 0.0 : (fade > 0 ? 1 - fade : show);
    const side = 200.0;
    return Positioned(
      left: center.dx - side / 2,
      top: center.dy - side / 2,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: _lerp(.4, 2.4, grow),
          child: Container(
            width: side,
            height: side,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 14)),
          ),
        ),
      ),
    );
  }

  Widget _logo(Offset center) {
    final rise = _seg(p, 40, 50, _bounce);
    final settle = _seg(p, 50, 55, _bounce);
    final scale = settle > 0 ? _lerp(1.12, 1, settle) : _lerp(.3, 1.12, rise);
    final turn = settle > 0 ? _lerp(3, 0, settle) : _lerp(-14, 3, rise);
    const w = 220.0, h = 166.0;
    return Positioned(
      left: center.dx - w / 2,
      top: center.dy - h / 2,
      child: Opacity(
        opacity: _seg(p, 40, 45).clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: turn * math.pi / 180,
          child: Transform.scale(
            scale: scale,
            child: Image.asset('assets/brand/logo.png', width: w, height: h, fit: BoxFit.contain, excludeFromSemantics: true),
          ),
        ),
      ),
    );
  }

  Widget _wordmark(Offset center) {
    final open = _seg(p, 54, 68, Curves.ease);
    return Positioned(
      left: 0,
      right: 0,
      top: center.dy + 120,
      child: Center(
        child: ClipRect(
          clipper: _FromLeft(open),
          child: const Wordmark(height: 38.4),
        ),
      ),
    );
  }

  Widget _tagline(Offset center) {
    final show = _seg(p, 66, 72, Curves.ease);
    return Positioned(
      left: 0,
      right: 0,
      top: center.dy + 174,
      child: Opacity(
        opacity: show,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - show)),
          child: Text(tr.tagline, textAlign: TextAlign.center, style: display(kTextMd, weight: FontWeight.w800, color: kBrand)),
        ),
      ),
    );
  }
}

/// Chapdan `fraction` qismigacha ochiladi.
class _FromLeft extends CustomClipper<Rect> {
  final double fraction;
  const _FromLeft(this.fraction);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_FromLeft old) => old.fraction != fraction;
}
