// Saytdagi `tests/cart.test.ts` — savat va miqdor qoidalari bir xil bo'lishi kerak.
import 'package:flutter_test/flutter_test.dart';
import 'package:online_store_app/l10n/strings.dart';
import 'package:online_store_app/models/models.dart';
import 'package:online_store_app/services/cart_lines.dart';
import 'package:online_store_app/services/options.dart';
import 'package:online_store_app/services/quantity.dart';

import 'fixtures.dart';

void main() {
  // Bu fayldagi kutilgan so'zlar o'zbekcha; rus tili — l10n_test.dart.
  setUp(() => appLang.value = AppLang.uz);

  test('loose food is sold in tenths of a kilo, pouches by the piece', () {
    final kg = productOptions(whiskasDry).first;
    expect(kg.unit, 'kg');
    expect(kg.decimal, true);
    expect(addLine([], whiskasDry, kg, 1.27).first.qty, 1.3);
    final pouch = productOptions(whiskasPouch).first;
    expect(pouch.decimal, false);
    expect(addLine([], whiskasPouch, pouch, 2.7).first.qty, 2);
  });

  test('adding caps at stock and merges into the same line', () {
    final option = productOptions(proplanLast).first;
    var cart = addLine([], proplanLast, option, 0.5);
    cart = addLine(cart, proplanLast, option, 0.8);
    expect(cart.length, 1);
    expect(cart.first.qty, 1);
    expect(identical(addLine(cart, proplanLast, option, 0.5), cart), true);
  });

  test('the buttons step loose food in half kilos and stop at one step', () {
    expect(stepQty(1, 1, decimal: true), 1.5);
    expect(stepQty(0.3, 1, decimal: true), 0.5);
    expect(stepQty(1.2, -1, decimal: true), 1);
    expect(stepQty(1, -1, decimal: true), 0.5);
    // Pastda − hech narsani o'zgartirmaydi — savat qatori buni "o'chirish" deb oladi.
    expect(stepQty(0.5, -1, decimal: true), 0.5);
    expect(stepQty(0.3, -1, decimal: true), 0.3);
    expect(stepQty(1.5, 1, decimal: true, max: 1.7), 1.7);
    expect(stepQty(1, -1), 1);
    expect(stepQty(3, 1, max: 3), 3);
  });

  test('typed quantities keep one decimal for loose food and whole numbers otherwise', () {
    expect(commitQty('1,25', decimal: true), 1.3);
    expect(commitQty('0', decimal: true), 0.1);
    expect(commitQty('7.9'), 7);
    expect(commitQty('abc'), null);
    expect(commitQty(' ', decimal: true), null);
    expect(commitQty('50', decimal: true, max: 23.5), 23.5);
  });

  test('two units of one product share its stock', () {
    final options = productOptions(pouchBox);
    final single = options[0], box = options[1];
    var cart = addLine([], pouchBox, box, 2); // 48 pauch
    cart = addLine(cart, pouchBox, single, 10); // faqat 2 qoldi
    expect(cart.firstWhere((l) => l.optionKey == 'base').qty, 2);
    expect(identical(addLine(cart, pouchBox, box, 1), cart), true);
  });

  test('cards price a multi-unit product by its base unit, and variants from the cheapest', () {
    final base = optionPriceGroups(productOptions(pouchBox)).first;
    expect(base.option.unit, 'dona');
    expect(base.varies, false);
    final from = optionPriceGroups(productOptions(flavours)).first;
    // Tugagan ta'm "dan" narxiga kirmaydi.
    expect(from.option.curPrice, 8000);
    expect(from.varies, false);
  });

  test('setting zero removes a line', () {
    final cart = addLine([], proplan, productOptions(proplan).first, 2);
    expect(setLineQty(cart, cart.first.key, 0), isEmpty);
  });

  test('revalidation follows new stock and drops sold-out lines', () {
    final cart = addLine([], proplan, productOptions(proplan).first, 10);
    // 3.25 kg qolgan bo'lsa 3.2 kg buyuriladi: 3.3 kg rad etiladi.
    expect(revalidateCart(cart, [withStock(proplan, 3.25)]).first.qty, 3.2);
    expect(revalidateCart(cart, [withStock(proplan, 0, inStock: false)]), isEmpty);
    expect(identical(revalidateCart(cart, [proplan]), cart), true);
  });

  test('order items carry the unit only for non-base units, and variants by id', () {
    final options = productOptions(pouchBox);
    var cart = addLine(addLine([], pouchBox, options[0], 10), pouchBox, options[1], 1);
    cart = addLine(cart, flavours, productOptions(flavours).first, 3);
    expect(toOrderItems(cart).map((i) => i.toJson()).toList(), [
      {'product_id': 9001, 'qty': 10.0},
      {'product_id': 9001, 'unit_id': 77, 'qty': 1.0},
      {'product_id': 9002, 'variant_id': 501, 'qty': 3.0},
    ]);
  });

  test('the summary adds up kilos of loose food', () {
    var cart = addLine([], whiskasDry, productOptions(whiskasDry).first, 1.5);
    cart = addLine(cart, proplan, productOptions(proplan).first, 2);
    cart = addLine(cart, whiskasPouch, productOptions(whiskasPouch).first, 6);
    expect(weighedKg(cart), 3.5);
  });

  test('the pre-check sums every unit of a product', () {
    expect(
      stockProblems(const [OrderItemPayload(productId: 9001, qty: 2), OrderItemPayload(productId: 9001, unitId: 77, qty: 2)], [pouchBox]),
      isEmpty,
    );
    final problems = stockProblems(
      const [OrderItemPayload(productId: 9001, qty: 5), OrderItemPayload(productId: 9001, unitId: 77, qty: 2)],
      [pouchBox],
    );
    expect(problems.length, 1);
    expect(problems.first, contains('faqat 50 dona mavjud, siz 53 dona'));
    expect(stockProblems(const [OrderItemPayload(productId: 8894, qty: 1.5)], [proplanLast]).first, contains('faqat 1 kg mavjud, siz 1.5 kg'));
    expect(
      stockProblems(const [OrderItemPayload(productId: 1, qty: 1)], [product(id: 1, name: 'X', stock: 0, inStock: false)]).first,
      contains('tugagan'),
    );
  });
}
