import 'units.dart';

/// Miqdor maydoniga yozilganni qo'llanadigan miqdorga aylantiradi yoki null —
/// tahrir bekor. Bo'sh va son bo'lmagan yozuv bekor, shuning uchun "1"ni
/// o'chirib "10" yozganda qator yo'qolib qolmaydi. Tortiladigan mahsulot bir
/// xona oladi ("1,5" ham, "1.5" ham), donabay kasrni tashlaydi. Eng kamidan
/// past va `max`dan yuqori bo'lmaydi.
double? commitQty(String draft, {double max = double.infinity, bool decimal = false}) {
  final raw = draft.trim().replaceFirst(',', '.').replaceAll(RegExp(r'\s+'), '');
  if (raw.isEmpty) return null;
  final parsed = double.tryParse(raw);
  if (parsed == null || !parsed.isFinite) return null;
  final rounded = roundQty(parsed, decimal);
  final atLeast = rounded > minQty(decimal) ? rounded : minQty(decimal);
  return atLeast < max ? atLeast : max;
}

/// +/− tugmasining keyingi qiymati. Ochiq ozuqa yarim kilo to'rida yuradi
/// (0.3 → 0.5 → 1 → 1.5), g'alati yozilgan vazn to'rga qaytadi; donabay
/// bittadan. Tugmalar bir qadamda (yoki undan kichik yozilgan vaznda) to'xtaydi,
/// `max`dan oshmaydi: − qiymatni o'zgartirmasa, savat qatori buni "o'chirish" deb oladi.
double stepQty(double qty, int direction, {double max = double.infinity, bool decimal = false}) {
  final step = qtyStep(decimal);
  final slots = qty / step;
  final next = direction > 0 ? ((slots + 1e-9).floorToDouble() + 1) * step : ((slots - 1e-9).ceilToDouble() - 1) * step;
  final floor = qty < step ? qty : step;
  final rounded = roundQty(next, decimal);
  final atLeast = rounded > floor ? rounded : floor;
  return atLeast < max ? atLeast : max;
}
