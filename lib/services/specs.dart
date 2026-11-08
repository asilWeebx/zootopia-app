import '../l10n/strings.dart';
import '../models/models.dart';
import 'options.dart';
import 'pack.dart';
import 'pets.dart';
import 'units.dart';

class SpecRow {
  final String label;
  final String value;
  const SpecRow(this.label, this.value);
}

/// Mahsulot sahifasidagi ma'lumotlar: kim uchun, ERP bo'limi, qanday sotiladi
/// va ERP'dagi xususiyatlar.
List<SpecRow> productSpecs(Product p, BuyOption option) {
  final pets = productPets(p);
  final pack = packGrams('${p.name} ${option.label}');
  final category = [p.categoryParentName, p.categoryName?.split(' › ').last]
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .join(' › ');
  return [
    if (pets.isNotEmpty) SpecRow(tr.specForWhom, pets.map(petLabel).join(', ')),
    if (category.isNotEmpty) SpecRow(tr.specSection, category),
    SpecRow(tr.specSold, isWeighed(option.unitName) ? tr.specByWeight : tr.specByPiece(option.unit)),
    if (pack != null) SpecRow(tr.pack, formatGrams(pack)),
    if (option.sku.isNotEmpty) SpecRow(tr.specSku, option.sku),
    for (final e in p.attributes.entries) SpecRow(e.key, e.value),
  ];
}
