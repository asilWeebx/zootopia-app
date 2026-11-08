import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/store.dart';
import '../config/theme.dart';
import '../l10n/strings.dart';
import '../services/api_service.dart';
import '../services/cart_lines.dart';
import '../services/currency.dart';
import '../services/geo_service.dart';
import '../services/units.dart';
import '../state/scope.dart';
import '../widgets/layout/page.dart';
import '../widgets/ui/basics.dart';
import '../widgets/ui/button.dart';
import 'map_picker_screen.dart';
import 'navigation.dart';

/// Onlayn hech narsa yechilmaydi: naqd yoki operator aytadigan karta o'tkazmasi.
List<(String, String, String, IconData)> get _payments => [
      ('cash', tr.cash.title, tr.cash.text, LucideIcons.banknote),
      ('card', tr.card.title, tr.card.text, LucideIcons.creditCard),
    ];

/// O'zbekiston raqami: ko'p mijoz +998 ni yozmaydi — o'zimiz qo'shamiz.
String normalizeUzPhone(String raw) {
  final v = raw.trim();
  if (v.isEmpty || v.startsWith('+')) return v;
  final digits = v.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('998')) return '+$digits';
  if (digits.length == 9) return '+998$digits';
  return v;
}

/// Rasmiylashtirish — saytdagi `/checkout`.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _landmark = TextEditingController();
  final _note = TextEditingController();
  /// Mijoz o'zi yozmaguncha kirgan mijozning ismi/telefoni qo'yiladi.
  bool _nameTouched = false;
  bool _phoneTouched = false;
  String _delivery = 'courier';
  String _payment = 'cash';
  LatLng? _coords;
  bool _locating = false;
  String _error = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());
  }

  Future<void> _prefill() async {
    final customer = context.readCatalog.customer;
    if (customer == null) return;
    void apply(String name, String phone) {
      if (!mounted) return;
      if (!_nameTouched && name.isNotEmpty) _name.text = name;
      if (!_phoneTouched && phone.isNotEmpty) _phone.text = phone;
    }

    apply(customer.displayName == customer.customerCode ? '' : customer.displayName,
        customer.phone.isNotEmpty ? customer.phone : customer.phoneNumber);
    try {
      final data = await ApiService.getCustomer(customer.customerCode);
      final p = data.customer;
      apply(p.name.isNotEmpty ? p.name : p.customerName, p.phone.isNotEmpty ? p.phone : p.phoneNumber);
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _landmark, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _locateMe() async {
    setState(() {
      _locating = true;
      _error = '';
    });
    try {
      final p = await GeoService.currentPosition();
      if (!mounted) return;
      setState(() => _coords = p);
      final found = await GeoService.reverseGeocode(p.latitude, p.longitude);
      if (found != null && mounted) _address.text = found;
    } catch (e) {
      if (mounted) setState(() => _error = e is GeoException ? e.message : tr.geoDenied);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openMap() async {
    final result = await Navigator.of(context).push<MapPickResult>(MaterialPageRoute(
      settings: const RouteSettings(name: '/map'),
      fullscreenDialog: true,
      builder: (_) => MapPickerScreen(initial: _coords),
    ));
    if (result == null || !mounted) return;
    setState(() => _coords = result.point);
    if (result.address != null) _address.text = result.address!;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final name = _name.text.trim(), phone = normalizeUzPhone(_phone.text);
    final courier = _delivery == 'courier';
    if (name.isEmpty || phone.isEmpty) {
      setState(() => _error = tr.nameAndPhone);
      return;
    }
    if (courier && _address.text.trim().isEmpty && _coords == null) {
      setState(() => _error = tr.addressRequired);
      return;
    }
    final cart = context.readCart;
    final catalog = context.readCatalog;
    setState(() {
      _error = '';
      _submitting = true;
    });

    final items = toOrderItems(cart.items);
    final payload = <String, dynamic>{
      'customer_name': name,
      'phone': phone,
      'delivery_type': _delivery,
      'payment_method': _payment,
      if (courier) 'address': _address.text.trim(),
      if (courier) 'landmark': _landmark.text.trim(),
      if (courier && _coords != null) 'latitude': _coords!.latitude,
      if (courier && _coords != null) 'longitude': _coords!.longitude,
      if (catalog.customer != null) 'customer_code': catalog.customer!.customerCode,
      if (_note.text.trim().isNotEmpty) 'note': _note.text.trim(),
      'items': [for (final i in items) i.toJson()],
    };

    try {
      // Ortiqcha qoldiq shu yerda rad etiladi: variantsiz mahsulotda ERP aniq
      // xabar o'rniga 500 qaytargan. Katalog o'qilmasa — ERP o'zi tekshiradi.
      final fresh = await ApiService.getCatalog().then((r) => r.results).catchError((Object _) => const <Never>[]);
      final problems = fresh.isEmpty ? const <String>[] : stockProblems(items, fresh);
      if (problems.isNotEmpty) {
        // Qoldiq sahifa ochilgandan beri o'zgargan: yangi katalog savatni qayta cheklaydi.
        catalog.load();
        throw StorefrontError(problems.join('\n'), 409);
      }
      final orderNo = await ApiService.createOrder(payload);
      cart.clear();
      if (!mounted) return;
      await _showSuccess(orderNo);
    } on StorefrontError catch (e) {
      if (mounted) {
        setState(() => _error = e.status >= 500
            ? tr.orderFailed
            : e.message);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e is NetworkError ? e.toString() : tr.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showSuccess(String orderNo) => showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: const Color(0x801F2B24),
        routeSettings: const RouteSettings(name: '/sheet/order-success'),
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (dialogContext, _, _) => _OrderSuccess(
          orderNo: orderNo,
          onClose: () {
            Navigator.of(dialogContext).pop();
            goHome();
          },
        ),
        transitionBuilder: (_, anim, _, child) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: Tween(begin: .92, end: 1.0).animate(CurvedAnimation(parent: anim, curve: kEaseBounce)), child: child),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cart = context.cart;
    final items = cart.items;

    Widget content;
    if (!cart.ready) {
      content = const Padding(padding: EdgeInsets.symmetric(vertical: kSpace6), child: Pulse(child: SkeletonBox(height: 420)));
    } else if (items.isEmpty) {
      content = EmptyState(
        icon: LucideIcons.shoppingCart,
        title: tr.checkoutEmpty,
        text: tr.checkoutEmptyText,
        action: AppButton(label: tr.toCatalog, onPressed: () => openCatalogPage()),
      );
    } else {
      content = _form(context);
    }

    return DetailPage(
      title: tr.checkoutTitle,
      slivers: [SliverToBoxAdapter(child: Gutter(child: content))],
    );
  }

  Widget _form(BuildContext context) {
    final items = context.cart.items;
    final courier = _delivery == 'courier';
    final kg = weighedKg(items);
    var step = 0;

    Widget card(String title, List<Widget> children) {
      step++;
      return Container(
        margin: const EdgeInsets.only(bottom: kSpace4),
        padding: const EdgeInsets.all(kSpace5),
        decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(kRadiusXl), boxShadow: kShadowSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: kSunSoft,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(17),
                      topRight: Radius.circular(17),
                      bottomRight: Radius.circular(17),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Text('$step', style: display(kTextMd, color: kBark)),
                ),
                const SizedBox(width: kSpace3),
                Expanded(child: Text(title, style: display(kTextXl))),
              ],
            ),
            for (final c in children) ...[const SizedBox(height: kSpace4), c],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: kSpace12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          card(tr.recipient, [
            _Field(
              label: tr.name,
              controller: _name,
              hint: tr.namePlaceholder,
              autofill: const [AutofillHints.name],
              capitalization: TextCapitalization.words,
              onChanged: (_) => _nameTouched = true,
            ),
            _Field(
              label: tr.phone,
              controller: _phone,
              hint: '+998 90 000 00 00',
              keyboard: TextInputType.phone,
              autofill: const [AutofillHints.telephoneNumber],
              onChanged: (_) => _phoneTouched = true,
            ),
          ]),
          card(tr.delivery, [
            Segmented<String>(
              options: [('courier', tr.courier), ('pickup', tr.pickup)],
              value: _delivery,
              onChanged: (v) => setState(() => _delivery = v),
            ),
            if (courier) ...[
              _Field(
                label: tr.address,
                controller: _address,
                hint: tr.addressPlaceholder,
                autofill: const [AutofillHints.fullStreetAddress],
              ),
              _Field(label: tr.landmark, controller: _landmark, hint: tr.landmarkPlaceholder),
              Wrap(
                spacing: kSpace2,
                runSpacing: kSpace2,
                children: [
                  AppButton(
                    label: _locating ? tr.locating : tr.locateMe,
                    variant: ButtonVariant.secondary,
                    icon: LucideIcons.crosshair,
                    iconSize: 16,
                    onPressed: _locating ? null : _locateMe,
                  ),
                  AppButton(
                    label: tr.pickOnMap,
                    variant: ButtonVariant.secondary,
                    icon: LucideIcons.mapPin,
                    iconSize: 16,
                    onPressed: _openMap,
                  ),
                ],
              ),
              if (_coords != null)
                Row(
                  children: [
                    const Icon(LucideIcons.check, size: 14, color: kSuccess),
                    const SizedBox(width: kSpace1),
                    Text(tr.located, style: sans(kTextSm, weight: FontWeight.w600, color: kSuccess)),
                  ],
                ),
            ] else
              Container(
                padding: const EdgeInsets.all(kSpace4),
                decoration: BoxDecoration(color: kPaper, borderRadius: BorderRadius.circular(kRadiusLg)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.store, size: 18, color: kAccent),
                    const SizedBox(width: kSpace3),
                    Expanded(
                      child: StoreContact.address.isNotEmpty
                          ? Text.rich(TextSpan(style: sans(kTextSm, height: 1.55), children: [
                              TextSpan(text: tr.pickupAt),
                              TextSpan(text: StoreContact.address, style: const TextStyle(fontWeight: FontWeight.w700)),
                              if (StoreContact.landmark.isNotEmpty) const TextSpan(text: ' (${StoreContact.landmark})'),
                              if (StoreContact.hours.isNotEmpty) const TextSpan(text: '. ${StoreContact.hours}'),
                            ]))
                          : Text(
                              tr.pickupCall,
                              style: sans(kTextSm, height: 1.55),
                            ),
                    ),
                  ],
                ),
              ),
          ]),
          card(tr.payment, [
            Column(
              children: [
                for (final (i, (value, title, text, icon)) in _payments.indexed) ...[
                  if (i > 0) const SizedBox(height: kSpace2),
                  GestureDetector(
                    onTap: () => setState(() => _payment = value),
                    child: AnimatedContainer(
                      duration: kDuration,
                      padding: const EdgeInsets.all(kSpace4),
                      decoration: BoxDecoration(
                        color: _payment == value ? kBrandSoft : kSurface,
                        borderRadius: BorderRadius.circular(kRadiusLg),
                        border: Border.all(color: _payment == value ? kBrand : kBorder, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, size: 22, color: kBrand),
                          const SizedBox(width: kSpace3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: sans(kTextMd, weight: FontWeight.w700)),
                                Text(text, style: sans(kTextXs, color: kMuted)),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: kDuration,
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _payment == value ? kBrand : kBorderStrong, width: _payment == value ? 7 : 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ]),
          card(tr.comment, [
            _Field(
              label: tr.commentLabel,
              controller: _note,
              hint: tr.commentPlaceholder,
              maxLines: 3,
              maxLength: 500,
            ),
          ]),
          const SizedBox(height: kSpace2),
          Container(
            padding: const EdgeInsets.all(kSpace5),
            decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(kRadiusXl), boxShadow: kShadowSm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr.summary, style: display(kTextXl)),
                const SizedBox(height: kSpace4),
                for (final (i, item) in items.indexed) ...[
                  if (i > 0) const SizedBox(height: kSpace3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(TextSpan(children: [
                              TextSpan(text: item.name, style: sans(kTextSm)),
                              if (item.optionLabel.isNotEmpty) TextSpan(text: ' · ${item.optionLabel}', style: sans(kTextSm, color: kMuted)),
                            ])),
                            Text(
                              '${fmtNumber(item.qty)} ${unitLabel(item.unit)} × ${money(item.curPrice, item.currency)}',
                              style: sans(kTextXs, color: kMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: kSpace3),
                      Text(money(lineTotal(item), item.currency), style: display(kTextSm)),
                    ],
                  ),
                ],
                const SizedBox(height: kSpace4),
                Container(
                  padding: const EdgeInsets.only(top: kSpace4),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorder))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(text: tr.total, style: sans(kTextMd)),
                        if (kg > 0) TextSpan(text: ' · ${tr.kgFood(fmtNumber(kg))}', style: sans(kTextXs, color: kMuted)),
                      ])),
                      const SizedBox(width: kSpace3),
                      Expanded(child: Text(groupTotal(totalsInput(items)), textAlign: TextAlign.right, style: display(kText2xl))),
                    ],
                  ),
                ),
                const SizedBox(height: kSpace4),
                Text(tr.deliveryNote, style: sans(kTextXs, color: kMuted)),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: kSpace4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: kSpace4, vertical: kSpace3),
                    decoration: BoxDecoration(color: kDangerSoft, borderRadius: BorderRadius.circular(kRadiusMd)),
                    child: Text(_error, style: sans(kTextSm, weight: FontWeight.w600, color: kDanger)),
                  ),
                ],
                const SizedBox(height: kSpace4),
                AppButton(
                  label: _submitting ? tr.submitting : tr.submit,
                  size: ButtonSize.lg,
                  block: true,
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Yorliqli kiritish maydoni (saytdagi `.field` + `.input`).
class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboard;
  final Iterable<String>? autofill;
  final int maxLines;
  final int? maxLength;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboard,
    this.autofill,
    this.maxLines = 1,
    this.maxLength,
    this.capitalization = TextCapitalization.sentences,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: sans(kTextSm, weight: FontWeight.w600, color: kInkSoft)),
          const SizedBox(height: kSpace2),
          TextField(
            controller: controller,
            keyboardType: keyboard ?? (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
            autofillHints: autofill,
            maxLines: maxLines,
            minLines: maxLines > 1 ? maxLines : 1,
            maxLength: maxLength,
            textCapitalization: capitalization,
            onChanged: onChanged,
            style: sans(kTextMd),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: sans(kTextMd, color: kFaint),
              counterText: '',
              filled: true,
              fillColor: kBg,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: kSpace4, vertical: maxLines > 1 ? kSpace3 : 15),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusMd),
                borderSide: const BorderSide(color: kBorder, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusMd),
                borderSide: const BorderSide(color: kBrand, width: 1.5),
              ),
            ),
          ),
        ],
      );
}

class _OrderSuccess extends StatelessWidget {
  final String orderNo;
  final VoidCallback onClose;
  const _OrderSuccess({required this.orderNo, required this.onClose});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(kSpace4),
          child: Material(
            color: kSurface,
            borderRadius: BorderRadius.circular(kRadiusXl),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.fromLTRB(kSpace6, kSpace8, kSpace6, kSpace6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(color: kSuccessSoft, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.check, size: 32, color: kSuccess),
                  ),
                  const SizedBox(height: kSpace4),
                  Text(tr.orderTitle, textAlign: TextAlign.center, style: display(kText2xl)),
                  const SizedBox(height: kSpace4),
                  Text(tr.orderNumber, style: sans(kTextSm, color: kMuted)),
                  Text(orderNo.isEmpty ? '—' : orderNo, style: display(text3xl(context), color: kAccentInk)),
                  const SizedBox(height: kSpace3),
                  Text(
                    tr.orderText,
                    textAlign: TextAlign.center,
                    style: sans(kTextMd, color: kInkSoft, height: 1.55),
                  ),
                  const SizedBox(height: kSpace6),
                  AppButton(label: tr.keepShopping, size: ButtonSize.lg, block: true, onPressed: onClose),
                ],
              ),
            ),
          ),
        ),
      );
}

