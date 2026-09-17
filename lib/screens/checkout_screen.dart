import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/geo_service.dart';
import '../config/theme.dart';
import 'map_picker_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cart;
  final Customer? customer;
  final ValueChanged<OnlineOrder> onSuccess;

  const CheckoutScreen({super.key, required this.cart, this.customer, required this.onSuccess});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();

  String _delivery = 'courier'; // 'courier' | 'pickup'
  String _payment = 'cash'; // 'cash' | 'card'
  double? _lat;
  double? _lng;
  bool _locating = false;
  bool _busy = false;
  String _err = '';
  OnlineOrder? _done;

  bool get _isCourier => _delivery == 'courier';

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameCtrl.text = widget.customer!.name;
      _phoneCtrl.text = widget.customer!.phone ?? '';
    } else {
      _phoneCtrl.text = '+998 ';
    }
  }

  double get _total => widget.cart.fold(0, (s, i) => s + i.price * i.qty);

  Future<void> _locateMe() async {
    setState(() { _locating = true; _err = ''; });
    try {
      final p = await GeoService.currentPosition();
      final addr = await GeoService.reverseGeocode(p.latitude, p.longitude);
      if (!mounted) return;
      setState(() {
        _lat = p.latitude;
        _lng = p.longitude;
        if (addr != null && addr.isNotEmpty) _addressCtrl.text = addr;
      });
    } catch (e) {
      if (mounted) setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickOnMap() async {
    final res = await Navigator.push<MapPickResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initial: (_lat != null && _lng != null) ? LatLng(_lat!, _lng!) : null,
        ),
      ),
    );
    if (res != null && mounted) {
      setState(() {
        _lat = res.point.latitude;
        _lng = res.point.longitude;
        if (res.address != null && res.address!.isNotEmpty) _addressCtrl.text = res.address!;
      });
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) { setState(() => _err = 'Ismingizni kiriting'); return; }
    final phone = normalizeUzPhone(_phoneCtrl.text);
    if (phone.replaceAll(RegExp(r'\D'), '').length < 9) { setState(() => _err = 'Telefon raqam kiriting'); return; }
    if (_isCourier && _addressCtrl.text.trim().isEmpty && _lat == null) {
      setState(() => _err = 'Manzil kiriting yoki xaritadan belgilang');
      return;
    }
    setState(() { _busy = true; _err = ''; });
    try {
      final order = await ApiService.submitOrder(
        name: _nameCtrl.text.trim(),
        phone: phone,
        note: _noteCtrl.text.trim(),
        cart: widget.cart,
        customerCode: widget.customer?.code,
        deliveryType: _delivery,
        paymentMethod: _payment,
        address: _isCourier ? _addressCtrl.text.trim() : null,
        landmark: _isCourier ? _landmarkCtrl.text.trim() : null,
        latitude: _isCourier ? _lat : null,
        longitude: _isCourier ? _lng : null,
      );
      if (mounted) { setState(() { _done = order; _busy = false; }); widget.onSuccess(order); }
    } catch (e) {
      if (mounted) setState(() { _busy = false; _err = friendlyError(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done != null) return _SuccessScreen(order: _done!, onClose: () => Navigator.pop(context));

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white, surfaceTintColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: kTextSub), onPressed: () => Navigator.pop(context)),
        title: const Text('Rasmiylashtirish', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kText)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: Color(0xFFF0F0F0))),
      ),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 170),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Yetkazib berish ──
            const _Label('YETKAZIB BERISH'),
            _SegToggle(
              options: const [('courier', 'Kuryer'), ('pickup', 'Olib ketaman')],
              value: _delivery,
              onChanged: (v) => setState(() => _delivery = v),
            ),

            if (_isCourier) ...[
              const SizedBox(height: 20),
              _Field(label: 'YANGI MANZIL', controller: _addressCtrl, hint: 'Ko\'cha, uy, xonadon', icon: Icons.location_on_outlined),
              const SizedBox(height: 14),
              _Field(label: 'MO\'LJAL (IXTIYORIY)', controller: _landmarkCtrl, hint: 'Masalan: maktab yonida', icon: Icons.push_pin_outlined),
              const SizedBox(height: 20),
              const _Label('JOYLASHUV'),
              Row(children: [
                Expanded(child: _LocBtn(
                  label: _locating ? 'Aniqlanmoqda...' : 'Meni topish',
                  icon: Icons.my_location,
                  active: false,
                  onTap: _locating ? null : _locateMe,
                )),
                const SizedBox(width: 12),
                Expanded(child: _LocBtn(
                  label: 'Xaritadan belgilash',
                  icon: Icons.map_outlined,
                  active: _lat != null,
                  onTap: _pickOnMap,
                )),
              ]),
              if (_lat != null) Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [
                  const Icon(Icons.check_circle, size: 15, color: kGreen),
                  const SizedBox(width: 6),
                  Expanded(child: Text(
                    _addressCtrl.text.trim().isNotEmpty
                        ? _addressCtrl.text.trim()
                        : 'Joylashuv belgilandi (${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)})',
                    style: const TextStyle(fontSize: 12, color: kTextSub), maxLines: 2, overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ],

            // ── To'lov usuli ──
            const SizedBox(height: 24),
            const _Label('TO\'LOV USULI'),
            _PayCard(
              title: 'Naqd pul',
              subtitle: 'Kuryerga qo\'lma-qo\'l topshirasiz',
              icon: Icons.payments_outlined,
              selected: _payment == 'cash',
              onTap: () => setState(() => _payment = 'cash'),
            ),
            const SizedBox(height: 10),
            _PayCard(
              title: 'Karta orqali',
              subtitle: 'Operator karta raqamini yuboradi',
              icon: Icons.credit_card_rounded,
              selected: _payment == 'card',
              onTap: () => setState(() => _payment = 'card'),
            ),

            // ── Izoh ──
            const SizedBox(height: 24),
            _Field(label: 'IZOH (IXTIYORIY)', controller: _noteCtrl, hint: 'Kuryerga yoki operatorga xabar', icon: Icons.notes_rounded, maxLines: 3),

            // ── Aloqa ──
            const SizedBox(height: 24),
            const _Label('ALOQA'),
            _Field(label: 'Ism familiya', controller: _nameCtrl, hint: 'To\'liq ismingiz', icon: Icons.person_outline_rounded),
            const SizedBox(height: 12),
            _Field(
              label: 'Telefon raqam', controller: _phoneCtrl, hint: '+998 90 000 00 00',
              icon: Icons.phone_outlined, keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d+\-\s()]'))],
            ),

            // ── Xulosa ──
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 16, offset: const Offset(0, 4))]),
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                Row(children: [
                  const Text('Mahsulotlar', style: TextStyle(fontSize: 14, color: kTextSub)),
                  const Spacer(),
                  Text(cartTotalStr(widget.cart), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Text('Yetkazib berish', style: TextStyle(fontSize: 14, color: kTextSub)),
                  const Spacer(),
                  Text(_isCourier ? 'Operator hisoblaydi' : 'Bepul',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText)),
                ]),
                const Divider(color: Color(0xFFF0F0F0), height: 22),
                Row(children: [
                  const Text('Jami', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kText)),
                  const Spacer(),
                  Text(cartTotalStr(widget.cart), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kText)),
                ]),
              ]),
            ),

            if (_err.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFF5F5),
                  border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, size: 18, color: kRed),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_err, style: const TextStyle(fontSize: 13, color: kRed))),
                ]),
              ),
            ],
          ]),
        ),

        // Pastki tugma
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            decoration: BoxDecoration(color: Colors.white, border: const Border(top: BorderSide(color: Color(0xFFF0F0F0)))),
            padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
            child: GestureDetector(
              onTap: _busy ? null : _submit,
              child: Container(
                height: 52, width: double.infinity,
                decoration: BoxDecoration(
                  color: _busy ? const Color(0xFFF0F0F0) : kAccent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _busy ? [] : [BoxShadow(color: kAccent.withAlpha(100), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Center(child: _busy
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Text('Buyurtmani tasdiqlash', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextSub, letterSpacing: .6)),
  );
}

class _SegToggle extends StatelessWidget {
  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChanged;
  const _SegToggle({required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
    children: options.map((o) {
      final active = o.$1 == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(o.$1),
          child: Container(
            margin: EdgeInsets.only(right: o == options.last ? 0 : 12),
            height: 52,
            decoration: BoxDecoration(
              color: active ? kAccent : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: active ? kAccent : kBorder, width: 1.5),
              boxShadow: active ? [BoxShadow(color: kAccent.withAlpha(80), blurRadius: 12, offset: const Offset(0, 3))] : [],
            ),
            child: Center(child: Text(o.$2,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: active ? Colors.white : kText))),
          ),
        ),
      );
    }).toList(),
  );
}

class _LocBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;
  const _LocBtn({required this.label, required this.icon, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        color: active ? kAccent : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? kAccent : kBorder, width: 1.5),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 18, color: active ? Colors.white : kTextSub),
        const SizedBox(width: 8),
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: active ? Colors.white : kText))),
      ]),
    ),
  );
}

class _PayCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _PayCard({required this.title, required this.subtitle, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? kAccent : kBorder, width: selected ? 2 : 1.5),
      ),
      child: Row(children: [
        Icon(icon, size: 24, color: kText),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: kTextSub)),
        ])),
        Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            size: 22, color: selected ? kAccent : kTextMuted),
      ]),
    ),
  );
}

class _Field extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({required this.label, required this.controller, required this.hint,
    required this.icon, this.maxLines = 1, this.keyboardType, this.inputFormatters});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextSub, letterSpacing: .4)),
    const SizedBox(height: 6),
    Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: kBorder, width: 1.5), borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 3))]),
      child: TextField(
        controller: controller, maxLines: maxLines, keyboardType: keyboardType, inputFormatters: inputFormatters,
        style: const TextStyle(fontSize: 15, color: kText),
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: kTextMuted),
          prefixIcon: Icon(icon, size: 18, color: kTextSub),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    ),
  ]);
}

class _SuccessScreen extends StatelessWidget {
  final OnlineOrder order;
  final VoidCallback onClose;
  const _SuccessScreen({required this.order, required this.onClose});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: kGreen.withAlpha(50), blurRadius: 24, spreadRadius: 4)]),
              child: const Icon(Icons.check_rounded, size: 52, color: kGreen),
            ),
            const SizedBox(height: 28),
            const Text('Buyurtma qabul qilindi!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kText), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('Sizning buyurtmangiz №${order.orderNo} raqam bilan ro\'yxatdan o\'tdi',
              style: const TextStyle(fontSize: 14, color: kTextSub, height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: onClose,
              child: Container(
                width: double.infinity, height: 52,
                decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: kAccent.withAlpha(100), blurRadius: 16, offset: const Offset(0, 4))]),
                child: const Center(child: Text('Katalogga qaytish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
              ),
            ),
          ]),
        ),
      ),
    ),
  );
}
