// Saytdagi `tests/feeding.test.ts` — kalkulyator raqamlari sayt bilan bir xil bo'lishi kerak.
import 'package:flutter_test/flutter_test.dart';
import 'package:online_store_app/l10n/strings.dart';
import 'package:online_store_app/models/models.dart';
import 'package:online_store_app/services/currency.dart';
import 'package:online_store_app/services/feeding.dart';
import 'package:online_store_app/services/units.dart';
import 'package:online_store_app/state/feeding_controller.dart';

import 'fixtures.dart';

FeedingInput input({Species species = Species.cat, double weightKg = 4, int pouchesPerDay = 0, int days = 30}) => FeedingInput(
      species: species,
      weightKg: weightKg,
      stage: Stage.adult,
      neutered: true,
      activity: Activity.normal,
      pouchesPerDay: pouchesPerDay,
      days: days,
    );

const adultCat = FoodFor(species: Species.cat, stage: Stage.adult, neutered: false);

FoodFor pet({Species species = Species.cat, Stage stage = Stage.adult, bool neutered = false}) =>
    FoodFor(species: species, stage: stage, neutered: neutered);

void main() {
  // Bu fayldagi kutilgan so'zlar o'zbekcha; rus tili — l10n_test.dart.
  setUp(() => appLang.value = AppLang.uz);

  test('an adult neutered 4 kg cat is offered about 70 g of dry food a day', () {
    final plan = feedingPlan(const FeedingProfile())!;
    expect(plan.kcalPerDay, 273);
    expect(plan.dryGramsPerDay, 72);
    expect(plan.dryKg, 2.158);
    expect(plan.pouches, 0);
  });

  test("the period's dry food is worked out to the gram and written with three decimals", () {
    // Do'kon egasining o'z misoli: 3 kg, kam harakat, kuniga ikki pauch, bir haftaga.
    final plan = feedingPlan(const FeedingProfile(weightKg: 3, activity: Activity.low, pouchesPerDay: 2, days: 7))!;
    expect(plan.dryGramsPerDay, 14);
    expect(plan.dryKg, 0.099);
    expect(exactKg(0.345), '0,345');
    expect(exactKg(plan.dryKg), '0,099');
    expect(exactKg(2.2), '2,200');
  });

  test('a pouch a day replaces part of the dry food', () {
    final plan = feedingPlan(input(pouchesPerDay: 1))!;
    expect(plan.dryGramsPerDay < 72 && plan.dryGramsPerDay > 35, true);
    expect(plan.pouches, 30);
  });

  test('pouches never push dry food below zero', () {
    final plan = feedingPlan(input(pouchesPerDay: 6))!;
    expect(plan.dryGramsPerDay, 0);
    expect(plan.dryKg, 0);
  });

  test('a 10 kg adult dog is offered about 200 g a day', () {
    final plan = feedingPlan(input(species: Species.dog, weightKg: 10, days: 7))!;
    expect(plan.dryGramsPerDay, 201);
    expect(plan.dryKg, 1.409);
  });

  test('growth and activity change the factor; weights out of range give no plan', () {
    expect(energyFactor(Species.cat, Stage.young, true, Activity.low), 2.5);
    expect(energyFactor(Species.dog, Stage.adult, false, Activity.high) > 2.3, true);
    expect(feedingPlan(input(weightKg: 0)), null);
    expect(feedingPlan(input(weightKg: 40)), null);
  });

  test('dry food is matched in half kilos, kitten food first for a kitten', () {
    final adult = foodFits(catalog, adultCat, dryKg: 1.9);
    expect(adult.length > 3, true);
    expect(adult.every((f) => f.qty == 2 && isWeighed(f.option.unitName)), true);
    expect(adult.first.product.id != kitten.id, true);
    final young = foodFits(catalog, pet(stage: Stage.young), dryKg: 1.2);
    expect([kitten.id, proplan.id].contains(young.first.product.id), true);
    expect(young.first.qty, 1.5);
    expect(adult.any((f) => f.product.id == whiskasPouch.id), false);
    expect(adult.any((f) => f.product.id == whiskasDry.id), true);
    // 1 kg qolgani 2 kg ni qoplay olmaydi — qoplay oladiganlardan keyin.
    expect(
      adult.indexWhere((f) => f.product.id == proplanLast.id) > adult.indexWhere((f) => f.product.id == whiskasDry.id),
      true,
    );
  });

  test('pouches are matched by the piece, and packed dog food by its pack weight', () {
    final wet = foodFits(catalog, adultCat, pouches: 30);
    expect(wet.map((f) => f.product.id).toSet(), {gourmet.id, whiskasPouch.id});
    expect(wet.every((f) => f.qty == 30), true);
    final dog = foodFits([dogBag, dogLoose], pet(species: Species.dog), dryKg: 5.3);
    expect(dog.firstWhere((f) => f.product.id == dogBag.id).qty, 3);
    expect(dog.firstWhere((f) => f.product.id == dogLoose.id).qty, 5.5);
  });

  // ERP'dagidek nomlar.
  Product food(int id, String name, [double kgPrice = 100000, double stock = 100]) => product(
        id: id,
        name: name,
        categoryId: 802,
        categoryName: 'Сухой корм',
        categoryParentId: 573,
        categoryParentName: 'Для Кошек',
        stock: stock,
        units: [unit('Kilogram', kgPrice)],
      );
  final plain = food(101, 'Вискас Говядина для кошек', 50000);
  final cheapPlain = food(102, 'Клуб 4 Лапы Курица для Кошек', 40000);
  final sterilized = food(103, 'Проплан Лосось для стерилизованных', 130000);
  final sterilShort = food(104, 'Проплан Индейка для стерил. кошек', 120000);
  final kittenFood = food(105, 'Проплан Индейка для Котят', 140000);
  final seniorFood = food(106, 'Royal Canin Senior 7+', 150000);
  final shelf = [plain, cheapPlain, sterilized, sterilShort, kittenFood, seniorFood];
  List<int> ids(List<FoodFit> fits) => [for (final f in fits) f.product.id];

  test('a neutered pet is offered sterilized food first, however much it costs', () {
    final fits = foodFits(shelf, pet(neutered: true), dryKg: 2);
    expect(ids(fits).take(2).toSet(), {sterilized.id, sterilShort.id});
    expect(fits.take(2).every((f) => f.neuteredMatch), true);
    // Sterilizatsiya ozuqasi kam bo'lsa oddiy ozuqa ham bor.
    expect(ids(fits).skip(2), [cheapPlain.id, plain.id]);
    expect(fits.skip(2).every((f) => !f.neuteredMatch), true);
    expect(ids(foodFits([plain, cheapPlain], pet(neutered: true), dryKg: 2)), [cheapPlain.id, plain.id]);
  });

  test('the sterilized answer changes what is offered', () {
    final yes = ids(foodFits(shelf, pet(neutered: true), dryKg: 2));
    final no = ids(foodFits(shelf, pet(neutered: false), dryKg: 2));
    expect(yes == no, false);
    expect(no, [cheapPlain.id, plain.id]);
  });

  test("adult pets aren't offered kitten or senior food, and kittens get their own", () {
    final adult = ids(foodFits(shelf, adultCat, dryKg: 2));
    expect(adult.contains(kittenFood.id) || adult.contains(seniorFood.id), false);
    // Mushukchaga savol yashiriladi, lekin saqlangan profil hali "sterilizatsiya" deydi.
    final kittenFits = foodFits(shelf, pet(stage: Stage.young, neutered: true), dryKg: 2);
    expect(kittenFits.first.product.id, kittenFood.id);
    expect(kittenFits.first.stageMatch, true);
    expect(ids(kittenFits).contains(sterilized.id) || ids(kittenFits).contains(seniorFood.id), false);
    final senior = foodFits(shelf, pet(stage: Stage.senior, neutered: true), dryKg: 2);
    expect(senior.first.product.id, seniorFood.id);
    expect(ids(senior).contains(kittenFood.id), false);
  });

  test('the right food for the pet ranks above having more of the wrong one', () {
    final short = food(107, 'Проплан Кролик для стерилизованных', 130000, 1);
    expect(foodFits([plain, short], pet(neutered: true), dryKg: 2).first.product.id, short.id);
  });

  test("kittens and puppies aren't offered food named for grown pets", () {
    final adultNamed = food(108, 'GRANDORF Adult Indoor 2kg');
    final grownUps = food(109, 'A-PRO для взрослых кошек с Говядиной');
    expect(ids(foodFits([plain, adultNamed, grownUps], pet(stage: Stage.young), dryKg: 2)), [plain.id]);
    // Katta hayvon uchun bular shunchaki oddiy ozuqa.
    expect(foodFits([adultNamed], adultCat, dryKg: 2).first.stageMatch, true);
  });

  // Do'kon pauchlarni bitta mahsulot variantlari qilib ham yozgan ("Мяу пауч 85гр").
  ProductVariant flavour(int id, String name) =>
      ProductVariant(id: id, name: name, sku: 'V$id', price: 5000, curPrice: 5000, stock: 90);
  Product grouped(int id, List<ProductVariant> variants) => product(
        id: id,
        name: 'Мяу пауч 85гр',
        categoryId: 803,
        categoryName: 'Влажный корм',
        categoryParentId: 573,
        categoryParentName: 'Для Кошек',
        hasVariants: true,
        units: [unit('Dona', 5000)],
        variants: variants,
      );
  final meow = grouped(110, [flavour(1, 'Мяу Индейка в Соусе'), flavour(2, 'Мяу Индейка для Стерилизованных'), flavour(3, 'Мяу с Говядиной в Соусе')]);

  test("a product's variants are judged one by one", () {
    final neutered = foodFits([meow], pet(neutered: true), pouches: 30).first;
    expect(neutered.option.label, 'Мяу Индейка для Стерилизованных');
    expect(neutered.neuteredMatch, true);
    final intact = foodFits([meow], pet(neutered: false), pouches: 30).first;
    expect(intact.option.label != 'Мяу Индейка для Стерилизованных', true);
    expect(intact.neuteredMatch, false);
    final young = foodFits([meow], pet(stage: Stage.young, neutered: true), pouches: 30).first;
    expect(young.option.label != 'Мяу Индейка для Стерилизованных', true);
  });

  test("only sterilized variants left means nothing for a pet that isn't neutered", () {
    final onlySterilized = grouped(111, [flavour(2, 'Мяу Индейка для Стерилизованных')]);
    expect(foodFits([onlySterilized], pet(neutered: false), pouches: 30), isEmpty);
  });

  test('a saved profile from an older build is sanitized', () {
    final p = FeedingProfile.sanitize({'species': 'dog', 'weightKg': 500, 'days': 9, 'pouchesPerDay': 20, 'stage': 'x'});
    expect(p.species, Species.dog);
    expect(p.weightKg, 10);
    expect(p.days, 30);
    expect(p.pouchesPerDay, 6);
    expect(p.stage, Stage.adult);
  });
}
