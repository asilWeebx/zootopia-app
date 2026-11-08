import 'package:flutter/material.dart';

/// Do'kon logosi: to'tiqush, it va baliq — `assets/logo.png`ning oq doirasisiz
/// nusxasi. Balandlik bo'yicha o'lchanadi, eni proporsiyada.
class BrandMark extends StatelessWidget {
  final double height;
  const BrandMark({super.key, this.height = 48});

  /// `assets/brand/logo.png` eni/bo'yi (678×510).
  static const ratio = 678 / 510;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/brand/logo.png',
        height: height,
        width: height * ratio,
        filterQuality: FilterQuality.medium,
        semanticLabel: null,
        excludeFromSemantics: true,
      );
}

enum WordmarkTone { light, dark }

/// "ZOOTOPIA" — brend varag'idagi ko'p chiziqli harflar, saytdagi
/// `Wordmark.tsx` + `wordmark-geometry.ts`dan: har harf o'rta chizig'i, uni
/// niqob to'rtta parallel chiziqqa aylantiradi, orqasidan logoning qizil,
/// yashil, sariq va ko'k diagonal maydonlari ko'rinadi. Och fonda to'qroq,
/// to'q fonda yorqinroq ranglar.
class Wordmark extends StatelessWidget {
  final double height;
  final WordmarkTone tone;
  const Wordmark({super.key, required this.height, this.tone = WordmarkTone.light});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: height * _viewBox.width / _viewBox.height,
        child: CustomPaint(painter: _WordmarkPainter(tone)),
      );
}

// ── Geometriya (wordmark-geometry.ts) ───────────────────────────
// Birliklar: bosh harf balandligi 100 (Z va T).

/// Bitta chiziq va ikki chiziq orasidagi bo'shliq. Chiziqlar bo'shliqdan
/// biroz qalinroq — sarlavha o'lchamida rang yaxlit turadi.
const _line = 4.8;
const _gap = 4.0;

/// Navbat bilan ko'rinadigan/yashirin chizilganda `lines` ta parallel chiziq beradigan qalinliklar.
List<double> bandWidths(int lines) {
  final widths = <double>[];
  var width = lines * _line + (lines - 1) * _gap;
  for (var on = true; width > 0.01; on = !on) {
    widths.add((width * 100).round() / 100);
    width -= 2 * (on ? _line : _gap);
  }
  return widths;
}

/// To'rt chiziqli dastaning yarmi: o'rta chiziq harf chetidan shuncha ichkarida.
const _h = (4 * _line + 3 * _gap) / 2;
/// T'ning uch chiziqli qopqog'ining yarmi.
const _h3 = (3 * _line + 2 * _gap) / 2;
/// O 92 enli: o'rta chizig'ining radiusi 46 − H.
const _oRadius = 46 - _h;

const _viewBox = Rect.fromLTWH(-1, -1, 744, 102);

class _Stroke {
  final Path path;
  final int lines;
  final StrokeJoin join;
  /// Chiziqni harf qutisida ushlab turadi — Z'ning o'tkir uchlarini tekis kesadi.
  final Rect? clip;
  const _Stroke(this.path, this.lines, this.join, [this.clip]);
}

Path _ring(double cx, double cy, double r) => Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

final _strokes = <_Stroke>[
  // Z, 0–99: yuqori chiziq, diagonal, pastki chiziq — bitta chiziq; burchaklar oshib ketadi va tekis kesiladi.
  _Stroke(
    Path()
      ..moveTo(0, _h)
      ..lineTo(105, _h)
      ..lineTo(-6, 100 - _h)
      ..lineTo(99, 100 - _h),
    4,
    StrokeJoin.miter,
    Rect.fromLTWH(0, _viewBox.top, 99, _viewBox.height),
  ),
  // O, 109–201
  _Stroke(_ring(155, 54, _oRadius), 4, StrokeJoin.round),
  // O, 215–307
  _Stroke(_ring(261, 54, _oRadius), 4, StrokeJoin.round),
  // T, 320–388: uch chiziqli qopqoq va undan bir bo'shliq pastdan to'rt chiziqli ustun.
  _Stroke(Path()..moveTo(320, _h3)..lineTo(388, _h3), 3, StrokeJoin.round),
  _Stroke(Path()..moveTo(354, 2 * _h3 + _gap)..lineTo(354, 100), 4, StrokeJoin.round),
  // O, 398–490
  _Stroke(_ring(444, 54, _oRadius), 4, StrokeJoin.round),
  // P, 504–585: ustun bo'ylab yuqoriga, qorni atrofida, ustundan bir bo'shliq oldin to'xtaydi.
  _Stroke(
    Path()
      ..moveTo(504 + _h, 100)
      ..lineTo(504 + _h, 13 + _h)
      ..lineTo(585 - _h, 13 + _h)
      ..lineTo(585 - _h, 69)
      ..lineTo(504 + 2 * _h + _gap, 69),
    4,
    StrokeJoin.round,
  ),
  // I, 602–633
  _Stroke(Path()..moveTo(602 + _h, 13)..lineTo(602 + _h, 100), 4, StrokeJoin.round),
  // a, 643–742: ustun ko'tariladi, ustidan egilib, chapdan tushadi va qorniga buraladi.
  _Stroke(
    Path()
      ..moveTo(742 - _h, 100)
      ..lineTo(742 - _h, 62.5)
      ..arcToPoint(const Offset(643 + _h, 62.5), radius: const Radius.circular(33.9), clockwise: false)
      ..arcToPoint(const Offset(643 + _h + 21.9, 100 - _h), radius: const Radius.circular(21.9), clockwise: false)
      ..lineTo(742 - 2 * _h - _gap, 100 - _h),
    4,
    StrokeJoin.round,
  ),
];

Path _polygon(List<double> xy) {
  final path = Path()..moveTo(xy[0], xy[1]);
  for (var i = 2; i < xy.length; i += 2) {
    path.lineTo(xy[i], xy[i + 1]);
  }
  return path..close();
}

/// Qizil asos ustidagi rang maydonlari.
final _fields = <(int, Path)>[
  // Birinchi O'ning o'ngi va ikkinchisining chap-yuqorisi.
  (1, _polygon([177, -5, 319, -5, 225, 105, 144, 105])),
  // Ikkinchi O'ning o'ng-pasti, butun T va uchinchi O'ning chap-pasti.
  (2, _polygon([319, -5, 395, -5, 496, 105, 225, 105])),
  // Uchinchi O'ning o'ng-yuqorisi, P, I'ning tepasi va a'ning chapi.
  (3, _polygon([395, -5, 680, -5, 674, 105, 640, 105, 640, 36.3, 579.5, 105, 496, 105])),
];

/// Logoning ranglari (qizil, yashil, sariq, ko'k) fonga moslab: ingichka
/// chiziqqa logoning yaxlit shakllaridan ko'ra ko'proq kontrast kerak.
const _colors = {
  // Krem sahifa (#fbf7f0) uchun to'qroq.
  WordmarkTone.light: [Color(0xFFCC0F1A), Color(0xFF2B8519), Color(0xFFBD7A00), Color(0xFF0A4B98)],
  // To'q yashil futer (#1e3123) uchun yorqinroq.
  WordmarkTone.dark: [Color(0xFFFF4A3D), Color(0xFF6FD14A), Color(0xFFFFC83D), Color(0xFF5AA2FF)],
};

class _WordmarkPainter extends CustomPainter {
  final WordmarkTone tone;
  const _WordmarkPainter(this.tone);

  @override
  void paint(Canvas canvas, Size size) {
    final colors = _colors[tone]!;
    canvas.save();
    canvas.scale(size.width / _viewBox.width, size.height / _viewBox.height);
    canvas.translate(-_viewBox.left, -_viewBox.top);

    canvas.saveLayer(_viewBox, Paint());
    canvas.drawRect(_viewBox, Paint()..color = colors[0]);
    for (final (color, path) in _fields) {
      canvas.drawPath(path, Paint()..color = colors[color]);
    }

    // Niqob: keng chiziq ko'rinadi, keyingisi o'chiradi va hokazo.
    canvas.saveLayer(_viewBox, Paint()..blendMode = BlendMode.dstIn);
    for (final stroke in _strokes) {
      if (stroke.clip != null) {
        canvas.save();
        canvas.clipRect(stroke.clip!);
      }
      for (final (k, width) in bandWidths(stroke.lines).indexed) {
        canvas.drawPath(
          stroke.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..strokeJoin = stroke.join
            ..strokeMiterLimit = 20
            ..color = const Color(0xFFFFFFFF)
            ..blendMode = k.isOdd ? BlendMode.clear : BlendMode.srcOver,
        );
      }
      if (stroke.clip != null) canvas.restore();
    }
    canvas.restore();
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WordmarkPainter old) => old.tone != tone;
}
