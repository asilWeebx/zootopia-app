// Saytdagi `tests/catalog.test.ts` — hayvon, tur, qidiruv va filtrlar bir xil ishlashi kerak.
import 'package:flutter_test/flutter_test.dart';
import 'package:online_store_app/config/pets.dart';
import 'package:online_store_app/l10n/strings.dart';
import 'package:online_store_app/models/models.dart';
import 'package:online_store_app/services/catalog.dart';
import 'package:online_store_app/services/options.dart';
import 'package:online_store_app/services/pack.dart';
import 'package:online_store_app/services/pets.dart';
import 'package:online_store_app/services/specs.dart';

import 'fixtures.dart';

void main() {
  // Bu fayldagi kutilgan so'zlar o'zbekcha; rus tili — l10n_test.dart.
  setUp(() => appLang.value = AppLang.uz);

  test('pets are read from the live product names', () {
    expect(productPets(whiskasDry), [PetId.cat]);
    expect(productPets(kitten), [PetId.cat]);
    expect(productPets(maineCoon), [PetId.cat]);
    expect(productPets(puppy), [PetId.dog]);
    expect(productPets(parrotFood), [PetId.bird]);
    expect(productPets(parrotVitamin), [PetId.bird]);
    // "Карелла" — do'konda корелла (nimfa to'tiqush) shunday yozilgan.
    expect(productPets(carella), [PetId.bird]);
    // Faqat brend: Whiskas va Gourmet pauchlari — mushuk ozuqasi.
    expect(productPets(whiskasPouch), [PetId.cat]);
    expect(productPets(gourmet), [PetId.cat]);
    expect(productPets(dogBag), [PetId.dog]);
    // Hayvon so'zi ham, tanish brend ham yo'q.
    expect(productPets(pawPicks), isEmpty);
    expect(productPets(club), isEmpty);
    // Do'konning o'z yorliqlari hayvon bo'lib o'qilmasin ("Tortib" — "to'ti" emas).
    final relabelled = relabelCategories([club]).first;
    expect(relabelled.categoryName, 'Tortib sotiladi');
    expect(productPets(relabelled), isEmpty);
    expect(productPets(product(id: 3, name: 'To‘tiqush uchun don')), [PetId.bird]);
  });

  test('product kinds come from the name, and loose goods count as food', () {
    expect(productType(whiskasPouch), ProductTypeId.wet);
    expect(productType(whiskasDry), ProductTypeId.dry);
    expect(productType(proplan), ProductTypeId.dry);
    expect(productType(parrotVitamin), ProductTypeId.vitamin);
    expect(productType(carella), ProductTypeId.vitamin);
    expect(productType(pawPicks), ProductTypeId.dry);
    expect(productType(plainFood), ProductTypeId.dry);
    expect(productType(flavours), ProductTypeId.wet);
  });

  test('life stages and sterilized food are read from the name', () {
    expect(lifeStage('Club 4 Paws Курица в желе Puppies 100гр'), LifeStage.young);
    expect(lifeStage('Проплан Индейка для Котят'), LifeStage.young);
    // Katta mushuk va mushukchaga birdek ozuqa — mushukcha ozuqasi emas.
    expect(lifeStage('Проплан для кошек и котят'), null);
    for (final name in ['Проплан Лосось для стерилизованных', 'Мяу Индейка для стерил. 85гр', 'OPTI MEAL курица и индейка для стерел. 85гр', 'GRANDORF TURKEY Adult Sterilised 2kg', 'ROYAL CANIN Sterilized']) {
      expect(isSterilizedFood(name), true, reason: name);
    }
    expect(isSterilizedFood('Вискас сухой корм для взрослых кошек'), false);
  });

  test('pack sizes are read from names', () {
    expect(packGrams('Вискас пауч 80гр'), 80);
    expect(packGrams('Гоурме пауч говядина 75гр'), 75);
    expect(packGrams('Pedigree для взрослых собак 2 кг'), 2000);
    expect(packGrams('Royal Canin 1,5kg'), 1500);
    expect(packGrams('Клуб 4 лапки'), null);
    expect(packGrams('Корм для крупных папугаев кг'), null);
  });

  test('pet groups list only pets with products, then everything else', () {
    final groups = petGroups(catalog);
    expect(groups.map((g) => g.id), [PetId.cat, PetId.dog, PetId.bird, PetId.other]);
    final dog = groups.firstWhere((g) => g.id == PetId.dog);
    expect(dog.count, 1);
    expect(dog.available, 0);
  });

  test('home shelves skip pets with nothing in stock', () {
    final shelves = groupByPet(catalog, [PetId.cat, PetId.dog, PetId.bird]);
    expect(shelves.map((s) => s.id), [PetId.cat, PetId.bird, PetId.other]);
    expect(shelves.first.title, 'Mushuklar uchun');
  });

  test('the ERP root group and stock-keeping names are relabelled', () {
    final products = normalizeCategories(relabelCategories(catalog));
    final categories = buildCategories(products);
    expect(categories.map((c) => c.name), ['Donalab sotiladi', 'Tortib sotiladi', 'Boshqa mahsulotlar']);
    expect(products.firstWhere((p) => p.id == pawPicks.id).categoryId, null);
    expect(categories.any((c) => c.id == kUncategorizedId), true);
  });

  test('search understands Russian whatever the page says', () {
    // Faqat brendli nom hayvonining ruscha so'zlarini oladi, istalgan shaklda.
    expect(matchesSearch(whiskasPouch, 'кошка'), true);
    expect(matchesSearch(whiskasPouch, 'Для кошек'), true);
    expect(matchesSearch(whiskasPouch, 'влажный корм'), true);
    expect(matchesSearch(puppy, 'собаки'), true);
    expect(matchesSearch(parrotFood, 'птицы'), true);
    expect(matchesSearch(parrotFood, 'кошка'), false);
    // Qisqa so'zlar butun qoladi: "корм" "кор"ga qisqarmaydi.
    expect(matchesSearch(product(id: 4, name: 'Коробка', units: [unit('Dona', 1000)]), 'корм'), false);
  });

  test('search understands Uzbek pet words and Latin spellings of Russian names', () {
    expect(matchesSearch(whiskasDry, 'mushuk'), true);
    expect(matchesSearch(whiskasDry, 'viskas'), true);
    expect(matchesSearch(kitten, 'royal'), true);
    expect(matchesSearch(parrotFood, 'qush'), true);
    expect(matchesSearch(whiskasPouch, 'nam ozuqa'), true);
    expect(matchesSearch(whiskasPouch, 'pauch'), true);
    // Har qanday o'zbekcha tutuq belgisi boshqasiga mos.
    expect(matchesSearch(product(id: 2, name: "To'ldirgich"), 'to‘ldirgich'), true);
    expect(matchesSearch(parrotFood, 'mushuk'), false);
    // Xato yozilgan so'z ham yaqinini topadi.
    expect(searchSuggestions('proplam', catalog).any((p) => p.id == proplan.id), true);
  });

  test('catalog filters combine pet, kind and stock', () {
    final cats = filterProducts(catalog, const CatalogFilters(pet: PetId.cat));
    expect(cats.every((p) => productPets(p).contains(PetId.cat)), true);
    final wet = filterProducts(catalog, const CatalogFilters(pet: PetId.cat, type: ProductTypeId.wet));
    expect(wet.map((p) => p.id).toSet(), {gourmet.id, whiskasPouch.id});
    final other = filterProducts(catalog, const CatalogFilters(pet: PetId.other, inStockOnly: true));
    expect(other.map((p) => p.id), [pawPicks.id]);
    // Tugaganlar oxiriga tushadi.
    final all = filterProducts(catalog, const CatalogFilters());
    expect(all.indexWhere((p) => p.id == puppy.id) > all.indexWhere((p) => p.id == whiskasDry.id), true);
  });

  test('similar products prefer the same pet and kind', () {
    final similar = similarProducts(whiskasDry, catalog, 4);
    expect(similar.every((p) => productPets(p).contains(PetId.cat)), true);
    expect(similar.take(3).every((p) => productType(p) == ProductTypeId.dry), true);
  });

  // Jonli katalogdagi shakllar (2026-11): tepasida hayvoni bor haqiqiy ERP bo'limlari.
  Product forCats(int id, String name, String sub, [int categoryId = 803]) => product(
        id: id,
        name: name,
        categoryId: categoryId,
        categoryName: sub,
        categoryParentId: 573,
        categoryParentName: 'Для Кошек',
        units: [unit('Dona', 5000)],
      );
  Product inSection(int id, String name, String section, int categoryId) =>
      product(id: id, name: name, categoryId: categoryId, categoryName: section, units: [unit('Dona', 5000)]);

  test('a flavour is not a pet: the ERP section says who it is for', () {
    for (final name in ['Felix Кролик в Желе 75гр', 'Мяу с Рыбой в Соусе 85гр', 'Felix Говядина и Домашняя Птица в Желе 75гр', 'TRIXIE fish chicken rools 50гр', 'GRANDORF RABBIT&TURKEY Adult Sterilized 2kg']) {
      expect(productPets(forCats(20, name, 'Влажный корм')), [PetId.cat], reason: name);
    }
    expect(productPets(inSection(21, 'Sebo submersible pump WP-5000', 'Аквариум', 580)), [PetId.fish]);
    expect(
      productPets(product(id: 22, name: 'RIO корм', categoryId: 581, categoryName: 'Корм', categoryParentId: 576, categoryParentName: 'Для Птиц', units: [unit('Dona', 5000)])),
      [PetId.bird],
    );
  });

  test("outside a pet section a flavour names nobody, but 'для' does", () {
    Product grooming(int id, String name) => inSection(id, name, 'Грумминг и уход', 695);
    expect(productPets(grooming(23, 'Паста с кроликом')), isEmpty);
    expect(productPets(grooming(24, 'Сено для кроликов')), [PetId.small]);
    expect(productPets(grooming(25, 'Витамины для рыб')), [PetId.fish]);
    expect(productPets(grooming(26, 'Зерно д/птиц')), [PetId.bird]);
    expect(productPets(grooming(27, 'TETRA AQUASAFE 50мл')), [PetId.fish]);
    expect(productPets(grooming(28, 'Дирофен таблетки для кошек и собак')), [PetId.cat, PetId.dog]);
  });

  test('a pet named outright beats a misfiled ERP section', () {
    expect(productPets(forCats(29, 'REFLEX для собак курица 3кг', 'Сухой корм', 802)), [PetId.dog]);
    expect(productPets(forCats(30, 'REFLEX ADULT DOG POMERANIAN 2kg', 'Сухой корм', 802)), [PetId.dog]);
    expect(productPets(forCats(31, 'Клуб 4 Лапы Рыба для котят 300гр', 'Сухой корм', 802)), [PetId.cat]);
  });

  test('the ERP section names the kind before the product name does', () {
    expect(productType(inSection(32, 'Pet grooming dryer', 'Грумминг и уход', 695)), ProductTypeId.care);
    expect(productType(inSection(33, 'Лосьон для ушей', 'Грумминг и уход', 695)), ProductTypeId.care);
    expect(productType(forCats(34, 'Консерва с лососем 375гр', 'Консерва', 813)), ProductTypeId.wet);
    // Ozuqa emas, ilovada ular uchun o'ylab topilgan tur yo'q.
    expect(productType(forCats(35, 'Приучения к унитазу Citi Kitty', 'Латки', 584)), null);
    expect(productType(inSection(36, 'Кормушка для рыб F-21', 'Аквариум', 580)), null);
    expect(productType(inSection(38, 'TRIXIE керам. миска д/кошка 0,2л 12см', 'Миски', 575)), null);
    expect(productType(inSection(39, 'Беафар ошейник инсектоакарицидный для собак 500гр', 'Для Собак', 579)), null);
    // Sut kukuni — qadog'i qancha bo'lmasin, quruq ozuqa emas.
    expect(productType(inSection(41, 'Lactol Puppy Milk Молочная смесь для щенков, 250 гр', 'Для Собак', 579)), null);
    // "до 3кг" — mushukning vazni, tomchilar quruq ozuqa emas.
    expect(productType(inSection(37, 'Дана спот-он капли от блох для котят и кошек до 3кг', 'Ветаптека', 810)), null);
  });

  test("categories follow the ERP's own list, whatever their ids and however the products arrive", () {
    final products = normalizeCategories(relabelCategories([
      forCats(40, 'Newest', 'Консерва', 813),
      inSection(41, 'Pump', 'Аквариум', 580),
      forCats(42, 'Sand', 'Наполнители', 582),
      pawPicks,
      inSection(43, 'Bowl', 'Миски', 575),
      forCats(44, 'Dry', 'Сухой корм', 802),
      forCats(45, 'Wet', 'Влажный корм', 803),
      product(id: 46, name: 'Dog', categoryId: 806, categoryName: 'Сухой корм', categoryParentId: 579, categoryParentName: 'Для Собак', units: [unit('Dona', 5000)]),
      inSection(47, 'Shampoo', 'Грумминг и уход', 695),
      inSection(48, 'Pills', 'Ветаптека', 810),
      // Ro'yxatda yo'q bo'limlar undan keyin, eskisi birinchi.
      inSection(49, 'New', 'Новый раздел', 900),
      inSection(50, 'Pass', 'Штучный', 307),
    ]));
    final categories = buildCategories(products);
    expect(
      topCategories(categories).map((c) => c.name),
      ['Аквариум', 'Для Кошек', 'Для Собак', 'Ветаптека', 'Грумминг и уход', 'Миски', 'Donalab sotiladi', 'Новый раздел', kUncategorizedName],
    );
    expect(categories.where((c) => c.parentId == 573).map((c) => c.name), ['Влажный корм', 'Сухой корм', 'Консерва', 'Наполнители']);
  });

  test('kinds follow the ERP sections they come from', () {
    final products = [
      forCats(50, 'Лакомство', 'Лакомства', 804),
      forCats(51, 'Пауч', 'Влажный корм', 803),
      forCats(52, 'Гранулы', 'Сухой корм', 802),
      forCats(53, 'Песок', 'Наполнители', 582),
      // Bu turni hech bir bo'lim bermaydi, faqat nomi — qolganlaridan keyin.
      inSection(54, 'Шампунь от блох', 'Ветаптека', 810),
      // Umuman tur emas: faqat o'z ERP bo'limida turadi.
      inSection(55, 'Ошейник от блох', 'Ветаптека', 810),
    ];
    expect(typeGroups(products).map((t) => t.id), [ProductTypeId.wet, ProductTypeId.dry, ProductTypeId.treat, ProductTypeId.litter, ProductTypeId.care]);
    // Bo'lim bergach, tur o'sha bo'lim o'rnini oladi.
    final grooming = inSection(56, 'Расчёска', 'Грумминг и уход', 695);
    final vitamins = forCats(57, 'Таблетки', 'Витамины и добавки', 809);
    expect(
      typeGroups([grooming, vitamins, ...products]).map((t) => t.id),
      [ProductTypeId.wet, ProductTypeId.dry, ProductTypeId.treat, ProductTypeId.vitamin, ProductTypeId.litter, ProductTypeId.care],
    );
  });

  test('the product facts have no kind row', () {
    final felix = forCats(60, 'Felix Кролик в Желе 75гр', 'Влажный корм');
    final specs = productSpecs(felix, productOptions(felix).first);
    expect(specs.map((row) => row.label), ['Kim uchun', 'Bo‘lim', 'Sotilishi', 'Qadoq', 'Artikul']);
    expect(specs.first.value, 'Mushuklar');
  });

  test("a section that only says 'food' lets the name be more exact", () {
    Product birdFood(int id, String name) =>
        product(id: id, name: name, categoryId: 581, categoryName: 'Корм', categoryParentId: 576, categoryParentName: 'Для Птиц', units: [unit('Dona', 5000)]);
    expect(productType(birdFood(70, 'Папугай витамин')), ProductTypeId.vitamin);
    expect(productType(birdFood(71, 'RIO для попугаев 500гр')), ProductTypeId.dry);
    // Turni aytadigan bo'lim nom nima qo'shmasin hal qiladi.
    expect(productType(forCats(72, 'Корм с витаминами 2кг', 'Сухой корм', 802)), ProductTypeId.dry);
  });
}
