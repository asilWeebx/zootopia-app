import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../config/pets.dart';
import '../../config/theme.dart';

/// Hayvonning pastel foni: mahsulot rasmi shu fonda turadi — bir qarashda kim uchunligi ko'rinadi.
Color petTint(PetId? pet) => switch (pet) {
      PetId.cat => kTintCat,
      PetId.dog => kTintDog,
      PetId.bird => kTintBird,
      PetId.fish => kTintFish,
      PetId.small => kTintSmall,
      _ => kTintOther,
    };

/// Saytdagi `PET_ICONS` (lucide). [stroke] — chiziq qalinligi: saytdagi 1.5–1.75
/// uchun 300 (1.55), 1.25 uchun 200 (1.0), sukut 2.
IconData petIcon(PetId? pet, {int stroke = 400}) => switch ((pet ?? PetId.other, stroke)) {
      (PetId.cat, 200) => LucideIcons.cat200,
      (PetId.cat, 300) => LucideIcons.cat300,
      (PetId.cat, _) => LucideIcons.cat,
      (PetId.dog, 200) => LucideIcons.dog200,
      (PetId.dog, 300) => LucideIcons.dog300,
      (PetId.dog, _) => LucideIcons.dog,
      (PetId.bird, 200) => LucideIcons.bird200,
      (PetId.bird, 300) => LucideIcons.bird300,
      (PetId.bird, _) => LucideIcons.bird,
      (PetId.fish, 200) => LucideIcons.fish200,
      (PetId.fish, 300) => LucideIcons.fish300,
      (PetId.fish, _) => LucideIcons.fish,
      (PetId.small, 200) => LucideIcons.rabbit200,
      (PetId.small, 300) => LucideIcons.rabbit300,
      (PetId.small, _) => LucideIcons.rabbit,
      (PetId.other, 200) => LucideIcons.pawPrint200,
      (PetId.other, 300) => LucideIcons.pawPrint300,
      (PetId.other, _) => LucideIcons.pawPrint,
    };

/// Mahsulot rasmi yo'q bo'lsa: hayvon belgisi o'z fonida — rasmsiz katalog
/// ham "rasm yo'q" devori emas, uy hayvonlari do'koni bo'lib ko'rinadi.
class PetArt extends StatelessWidget {
  final PetId? pet;
  const PetArt({super.key, this.pet});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) {
          final side = box.biggest.shortestSide.isFinite ? box.biggest.shortestSide : 80.0;
          return ColoredBox(
            color: petTint(pet),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-.4, -.5),
                  radius: 1.03,
                  colors: [Color(0x8CFFFFFF), Color(0x00FFFFFF)],
                  stops: [0, .55],
                ),
              ),
              child: Center(
                child: Icon(petIcon(pet, stroke: 200), size: side * .46, color: kBrand.withValues(alpha: .32)),
              ),
            ),
          );
        },
      );
}

/// Katalog rasm manzillari ERP'ga qo'lda yoziladi — faqat http(s) manzil yuklanadi.
bool isRenderableImageUrl(String? src) {
  if (src == null || src.trim().isEmpty) return false;
  final uri = Uri.tryParse(src.trim());
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
}

/// Buzilmaydigan rasm: manzil yaroqsiz yoki yuklanmasa `fallback` (yoki oddiy
/// belgi) chiqadi. Ota o'lchamini to'ldiradi.
///
/// `packshot` — oq fonda suratga olingan mahsulot rasmi: oqi orqadagi pastel
/// fonga singib ketadi (multiply), rasm kesilmaydi, 8% chekka bilan sig'adi.
class SafeImage extends StatefulWidget {
  final String? src;
  final bool packshot;
  /// `packshot`da rasm orqasidagi fon — oq shu rangga aylanadi.
  final Color? backdrop;
  final Widget? fallback;
  final VoidCallback? onFail;
  /// Sukut: `packshot`da contain, aks holda cover.
  final BoxFit? fit;
  /// `packshot`da rasm atrofidagi 8% chekka; kartadagi yelpig'ich qadoqlarida yo'q.
  final bool inset;

  const SafeImage({super.key, required this.src, this.packshot = false, this.backdrop, this.fallback, this.onFail, this.fit, this.inset = true});

  @override
  State<SafeImage> createState() => _SafeImageState();
}

class _SafeImageState extends State<SafeImage> {
  /// Yuklanmagan manzil — o'rniga to'liq o'lchamdagi `fallback` chiqadi.
  String? _failed;

  Widget _fallback() => SizedBox.expand(
        child: widget.fallback ??
            const ColoredBox(
              color: kSurfaceMuted,
              child: Center(child: Icon(LucideIcons.imageOff300, size: 28, color: kFaint)),
            ),
      );

  @override
  Widget build(BuildContext context) {
    final src = widget.src;
    if (!isRenderableImageUrl(src) || _failed == src) return _fallback();
    final packshot = widget.packshot;
    final image = CachedNetworkImage(
      imageUrl: src!.trim(),
      fit: widget.fit ?? (packshot ? BoxFit.contain : BoxFit.cover),
      width: double.infinity,
      height: double.infinity,
      color: packshot ? (widget.backdrop ?? kTintOther) : null,
      colorBlendMode: packshot ? BlendMode.multiply : null,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, _) => const SizedBox.expand(),
      errorWidget: (_, _, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || widget.src != src) return;
          setState(() => _failed = src);
          widget.onFail?.call();
        });
        return const SizedBox.expand();
      },
    );
    if (!packshot || !widget.inset) return image;
    return LayoutBuilder(
      builder: (context, box) {
        final pad = box.maxWidth.isFinite ? box.maxWidth * .08 : 8.0;
        return Padding(padding: EdgeInsets.all(pad), child: image);
      },
    );
  }
}
