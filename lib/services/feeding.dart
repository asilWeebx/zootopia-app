import 'dart:math' as math;

import '../config/pets.dart';
import '../models/models.dart';
import 'options.dart';
import 'pack.dart';
import 'pets.dart';
import 'units.dart';

// Mushuk yoki it qancha yeydi — veterinariyadagi standart hisob: tinch holat
// energiyasi 70 × kg^0.75 kkal kuniga, yoshi, sterilizatsiya va harakatga
// ko'ra koeffitsient bilan, keyin `_portionBoost` ga oshiriladi. Qadoqlarning
// kaloriyasi har xil, shuning uchun har bir raqam taxminiy — sahifa qadoqdagi
// jadvalni tekshirishni aytadi. Saytdagi `src/lib/shop/feeding.ts` bilan bir xil.

/// Do'kon tanlovi: quruq hisobdan ko'ra to'yimliroq porsiya. 15% — hayvonlar
/// orasidagi farq ichida; ko'prog'i, ayniqsa sterilizatsiya qilingan mushukni
/// semirtirishi mumkin.
const _portionBoost = 1.15;

enum Species { cat, dog }

enum Stage { young, adult, senior }

enum Activity { low, normal, high }

class FeedingInput {
  final Species species;
  final double weightKg;
  final Stage stage;
  final bool neutered;
  final Activity activity;
  /// Quruq ozuqa bilan birga kuniga beriladigan pauchlar.
  final int pouchesPerDay;
  /// Xarid necha kunga yetishi kerak.
  final int days;

  const FeedingInput({
    required this.species,
    required this.weightKg,
    required this.stage,
    required this.neutered,
    required this.activity,
    required this.pouchesPerDay,
    required this.days,
  });
}

/// Odatiy pauch; Whiskas, Gourmet va Darling 75–85 g.
const kPouchGrams = 85;
/// Odatiy quruq ozuqa, kkal/g.
const _dryKcalPerG = {Species.cat: 3.8, Species.dog: 3.6};
/// Odatiy pauch ozuqasi, kkal/g.
const _wetKcalPerG = 0.85;

/// Hisob mo'ljallangan vaznlar, kg.
const kWeightLimits = {
  Species.cat: (min: 0.3, max: 15.0),
  Species.dog: (min: 0.5, max: 90.0),
};

double restingEnergy(double weightKg) => 70 * math.pow(weightKg, 0.75).toDouble();

const _activity = {
  Species.cat: {Activity.low: 0.9, Activity.normal: 1.0, Activity.high: 1.15},
  Species.dog: {Activity.low: 0.85, Activity.normal: 1.0, Activity.high: 1.3},
};

/// Mushukcha va kuchukchaga, nima bo'lsa ham, tinch energiyaning ≈2.5 barobari kerak.
double energyFactor(Species species, Stage stage, bool neutered, Activity activity) {
  if (stage == Stage.young) return 2.5;
  final base = species == Species.cat
      ? (stage == Stage.senior ? 1.1 : (neutered ? 1.2 : 1.4))
      : (stage == Stage.senior ? 1.4 : (neutered ? 1.6 : 1.8));
  return base * _activity[species]![activity]!;
}

class FeedingPlan {
  final int kcalPerDay;
  final int dryGramsPerDay;
  /// Butun muddatga quruq ozuqa, kg, gramm aniqligida.
  final double dryKg;
  /// Butun muddatga pauchlar.
  final int pouches;
  const FeedingPlan({required this.kcalPerDay, required this.dryGramsPerDay, required this.dryKg, required this.pouches});
}

/// Vazn hisob mo'ljallanganidan tashqarida bo'lsa null.
FeedingPlan? feedingPlan(FeedingInput input) {
  final limits = kWeightLimits[input.species]!;
  if (!(input.weightKg >= limits.min && input.weightKg <= limits.max) || !(input.days > 0)) return null;
  final kcal = restingEnergy(input.weightKg) *
      energyFactor(input.species, input.stage, input.neutered, input.activity) *
      _portionBoost;
  final pouches = math.max(0, input.pouchesPerDay);
  final wetKcal = math.min(kcal, pouches * kPouchGrams * _wetKcalPerG);
  final dryGramsPerDay = (kcal - wetKcal) / _dryKcalPerG[input.species]!;
  return FeedingPlan(
    kcalPerDay: kcal.round(),
    dryGramsPerDay: dryGramsPerDay.round(),
    dryKg: math.max(0, (dryGramsPerDay * input.days - 1e-9).ceilToDouble() / 1000),
    pouches: pouches * input.days,
  );
}

class FoodFit {
  final Product product;
  final BuyOption option;
  /// Variant birligida.
  final double qty;
  /// Shu yoshga mo'ljallangan ozuqa (mushukchaga — mushukcha ozuqasi, kattaga — oddiy ozuqa).
  final bool stageMatch;
  /// Sterilizatsiya qilingan hayvonga — sterilizatsiya qilinganlar ozuqasi.
  final bool neuteredMatch;
  const FoodFit({required this.product, required this.option, required this.qty, required this.stageMatch, this.neuteredMatch = false});
}

/// Ochiq ozuqa yarim kilolab buyuriladi: 1.9 kg kerak → 2 kg.
double _halfKilos(double kg) => math.max(0.5, (kg * 2 - 1e-9).ceilToDouble() / 2);

/// Ozuqa kim uchun: tur, yosh va sterilizatsiya.
class FoodFor {
  final Species species;
  final Stage stage;
  final bool neutered;
  const FoodFor({required this.species, required this.stage, required this.neutered});
  factory FoodFor.of(FeedingInput input) => FoodFor(species: input.species, stage: input.stage, neutered: input.neutered);
}

/// Ozuqa hayvonga qanchalik mos, kattasi yaxshi; umuman taklif qilinmasin
/// desa null. Do'kon nomlari kim uchunligini aytadi ("для котят", "для
/// стерил."); hech birini aytmagani — katta hayvonlar uchun oddiy ozuqa.
/// Mushukcha va kuchukchaga sterilizatsiya taalluqli emas: forma so'ramaydi,
/// lekin saqlangan profil shunday deyishi mumkin.
int? _suitability(String name, FoodFor pet) {
  final own = lifeStage(name);
  final sterilized = isSterilizedFood(name);
  if (pet.stage == Stage.young) {
    if (own == LifeStage.young) return 3;
    return own == null && !sterilized ? 1 : null;
  }
  if (own == LifeStage.young || (sterilized && !pet.neutered) || (own == LifeStage.senior && pet.stage == Stage.adult)) return null;
  if (own == LifeStage.senior) return 3;
  if (sterilized) return 2;
  return pet.stage == Stage.adult && !pet.neutered ? 2 : 1;
}

bool _sameStage(LifeStage? own, Stage stage) => switch (stage) {
      Stage.young => own == LifeStage.young,
      Stage.senior => own == LifeStage.senior,
      Stage.adult => own == LifeStage.adult || own == null,
    };

/// Katalogdagi hayvon uchun rejani qoplaydigan ozuqa: kilolab tortiladigan
/// yoki nomida og'irligi bor qadoqdagi quruq ozuqa, donalab pauch. Variantlar
/// birma-bir baholanadi ("Мяу пауч" ostidagi "Мяу Индейка для
/// Стерилизованных"), mahsulot bir marta — omborda bor eng mos varianti
/// bilan — taklif qilinadi. Avval omborda borlari, keyin hayvonga eng mosi,
/// keyin butun miqdorga yetadiganlari, keyin arzonrog'i.
List<FoodFit> foodFits(List<Product> products, FoodFor pet, {double? dryKg, int? pouches}) {
  final wet = pouches != null;
  final petId = pet.species == Species.cat ? PetId.cat : PetId.dog;
  final fits = <FoodFit>[];
  final scores = <FoodFit, int>{};
  for (final product in products) {
    if (!productPets(product).contains(petId)) continue;
    if (productType(product) != (wet ? ProductTypeId.wet : ProductTypeId.dry)) continue;
    final options = [...productOptions(product)]
      ..sort((a, b) {
        final byStock = (b.inStock ? 1 : 0) - (a.inStock ? 1 : 0);
        return byStock != 0 ? byStock : a.multiplier.compareTo(b.multiplier);
      });
    FoodFit? best;
    var bestScore = -1;
    for (final option in options) {
      final named = '${product.name} ${option.label}';
      final score = _suitability(named, pet);
      if (score == null || score <= bestScore || ((best?.option.inStock ?? false) && !option.inStock)) continue;
      double? qty;
      if (!wet) {
        final need = dryKg ?? 0;
        if (!(need > 0)) break;
        final pack = packGrams(named);
        if (isWeighed(option.unitName)) {
          qty = _halfKilos(need);
        } else if (pack != null && pack >= 200) {
          qty = ((need * 1000) / (pack * option.multiplier) - 1e-9).ceilToDouble();
        }
      } else if (pouches > 0 && !option.decimal && option.multiplier == 1) {
        qty = pouches.toDouble();
      }
      if (qty != null && qty > 0) {
        best = FoodFit(
          product: product,
          option: option,
          qty: qty,
          stageMatch: _sameStage(lifeStage(named), pet.stage),
          neuteredMatch: pet.stage != Stage.young && pet.neutered && isSterilizedFood(named),
        );
        bestScore = score;
      }
    }
    if (best != null) {
      fits.add(best);
      scores[best] = bestScore;
    }
  }
  int covers(FoodFit f) => f.option.inStock && f.option.stock >= f.qty ? 1 : 0;
  // Teng bo'lganlar katalog tartibida qoladi (Dart'ning `sort`i buni kafolatlamaydi).
  final order = {for (final (i, f) in fits.indexed) f: i};
  fits.sort((a, b) {
    final s = (b.option.inStock ? 1 : 0) - (a.option.inStock ? 1 : 0);
    if (s != 0) return s;
    final st = scores[b]! - scores[a]!;
    if (st != 0) return st;
    final c = covers(b) - covers(a);
    if (c != 0) return c;
    final p = (a.option.curPrice * a.qty).compareTo(b.option.curPrice * b.qty);
    return p != 0 ? p : order[a]! - order[b]!;
  });
  return fits;
}
