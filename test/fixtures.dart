// Saytdagi `tests/fixtures.ts`ning nusxasi: jonli Zootopia katalogidan
// (2026-10-03) olingan shakllar.
import 'package:online_store_app/models/models.dart';

ProductUnit unit(String name, double price, {int? unitId, double multiplier = 1, bool isBase = true}) => ProductUnit(
      unitId: unitId,
      unitName: name,
      multiplier: multiplier,
      isBase: isBase,
      price: price,
      curPrice: price,
    );

Product product({
  required int id,
  required String name,
  int? categoryId = 308,
  String? categoryName = 'Весовой',
  int? categoryParentId,
  String? categoryParentName,
  double stock = 100,
  bool inStock = true,
  bool hasVariants = false,
  List<ProductVariant> variants = const [],
  List<ProductUnit>? units,
}) =>
    Product(
      id: id,
      name: name,
      sku: 'SKU-$id',
      categoryId: categoryId,
      categoryName: categoryName,
      categoryParentId: categoryParentId,
      categoryParentName: categoryParentName,
      image: 'https://example.com/p.webp',
      stockType: 'tracked',
      stock: stock,
      inStock: inStock,
      hasVariants: hasVariants,
      variants: variants,
      units: units ?? [unit('Kilogram', 45000)],
    );

Product piece({required int id, required String name, double stock = 100, List<ProductUnit>? units, bool hasVariants = false, List<ProductVariant> variants = const []}) =>
    product(id: id, name: name, categoryId: 307, categoryName: 'Штучный', stock: stock, units: units, hasVariants: hasVariants, variants: variants);

Product root({required int id, required String name, double stock = 100, bool inStock = true, List<ProductUnit>? units}) =>
    product(id: id, name: name, categoryId: 306, categoryName: 'Корневая группа', stock: stock, inStock: inStock, units: units);

final whiskasPouch = piece(id: 9160, name: 'Вискас пауч 80гр', stock: 2324, units: [unit('Dona', 6000)]);
final gourmet = piece(id: 9158, name: 'Гоурме пауч говядина 75гр', stock: 122, units: [unit('Dona', 7990)]);
final whiskasDry = product(id: 8551, name: 'Вискас сухой корм для взрослых кошек', stock: 12229.66, units: [unit('Kilogram', 90000)]);
final proplan = product(id: 8550, name: 'Проплан для кошек и котят', stock: 221.393, units: [unit('Kilogram', 130000)]);
final kitten = product(id: 8549, name: 'Роял Канин для котят', stock: 23.565, units: [unit('Kilogram', 150000)]);
final maineCoon = product(id: 8548, name: 'Роял канин для Мейн кунов', stock: 19.867, units: [unit('Kilogram', 160000)]);
final proplanLast = product(id: 8894, name: 'Проплан сухой для кошек', stock: 1, units: [unit('Kilogram', 100000)]);
final puppy = product(id: 8553, name: 'Клуб 4 лапы сухой корм для щенков всех пород', stock: 0, inStock: false);
final parrotFood = product(id: 8534, name: 'Корм для крупных папугаев кг', stock: 16.92, units: [unit('Kilogram', 50000)]);
final parrotVitamin = product(id: 8533, name: 'Папугай витамин кг', stock: 44.782, units: [unit('Kilogram', 15000)]);
final carella = product(id: 8532, name: 'Карелла витамин кг', stock: 69.2, units: [unit('Kilogram', 25000)]);
final pawPicks = root(id: 8466, name: 'Пав ПИКС', stock: 937.109, units: [unit('Kilogram', 35000)]);
final club = product(id: 8541, name: 'Клуб 4 лапки', stock: 0, inStock: false, units: [unit('Kilogram', 60000)]);
final plainFood = root(id: 8468, name: 'Корм', stock: 0, inStock: false, units: [unit('Dona', 15000)]);

// ERP qo'llaydigan, lekin bu katalogda hali yo'q shakllar.
final pouchBox = piece(
  id: 9001,
  name: 'Феликс пауч 85г',
  stock: 50,
  units: [unit('Dona', 6500), unit('Quti', 150000, unitId: 77, multiplier: 24, isBase: false)],
);
final flavours = piece(
  id: 9002,
  name: 'Шеба паштет',
  hasVariants: true,
  units: [unit('Dona', 9000)],
  variants: const [
    ProductVariant(id: 501, name: 'Tovuq', image: 'https://example.com/chicken.webp', price: 8000, originalPrice: 9000, curPrice: 8000, curOriginalPrice: 9000, stock: 12),
    ProductVariant(id: 502, name: 'Mol go‘shti', price: 9000, curPrice: 9000, stock: 0, inStock: false),
  ],
);
final dogBag = piece(id: 9003, name: 'Pedigree для взрослых собак 2 кг', stock: 8, units: [unit('Dona', 98000)]);
final dogLoose = product(id: 9004, name: 'Сухой корм для собак', stock: 40, units: [unit('Kilogram', 38000)]);

final catalog = [whiskasPouch, gourmet, whiskasDry, proplan, kitten, maineCoon, proplanLast, puppy, parrotFood, parrotVitamin, carella, pawPicks, club, plainFood];

/// `{...p, stock, in_stock}`.
Product withStock(Product p, double stock, {bool inStock = true}) => Product(
      id: p.id,
      name: p.name,
      sku: p.sku,
      categoryId: p.categoryId,
      categoryName: p.categoryName,
      image: p.image,
      stockType: p.stockType,
      stock: stock,
      inStock: inStock,
      hasVariants: p.hasVariants,
      variants: p.variants,
      units: p.units,
    );
