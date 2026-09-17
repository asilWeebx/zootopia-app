import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final List<CartItem> cart;
  final void Function(Product, ProductUnit, [Offset?, double]) onAdd;
  final void Function(Product, ProductVariant, double) onAddVariant;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.cart,
    required this.onAdd,
    required this.onAddVariant,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late int _unitIdx;
  int? _selVariantId;
  double _qty = 1;
  bool _added = false;
  final TextEditingController _qtyCtrl = TextEditingController(text: '1'); // kg tovar uchun

  @override
  void dispose() { _qtyCtrl.dispose(); super.dispose(); }

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p.hasVariants && p.variants.isNotEmpty) {
      // Select first in-stock variant, or just first
      final firstInStock = p.variants.firstWhere((v) => v.inStock, orElse: () => p.variants.first);
      _selVariantId = firstInStock.id;
      _unitIdx = 0;
    } else if (p.stockType == 'tracked' && p.units.isNotEmpty) {
      final idx = p.units.indexWhere((u) => (p.stock / u.multiplier).floor() > 0);
      _unitIdx = idx >= 0 ? idx : 0;
    } else {
      _unitIdx = 0;
    }
  }

  ProductVariant? get _selVariant => widget.product.hasVariants
      ? widget.product.variants.firstWhere((v) => v.id == _selVariantId,
          orElse: () => widget.product.variants.first)
      : null;

  ProductUnit get _unit => widget.product.units.isNotEmpty
      ? widget.product.units[_unitIdx]
      : ProductUnit(unitId: 0, unitName: 'dona', price: 0, multiplier: 1);

  double get _displayPrice {
    if (widget.product.hasVariants) return _selVariant?.price ?? 0;
    return _unit.price;
  }

  // Og'irlik (kg) tovarmi — kasr miqdor
  bool get _isWeight => !widget.product.hasVariants && allowsFraction(_unit.unitName);

  double get _maxQty {
    if (widget.product.hasVariants) {
      final v = _selVariant;
      if (v == null || !v.inStock) return 0;
      return v.stock?.floorToDouble() ?? 9999;
    }
    if (widget.product.stockType == 'tracked') {
      final m = widget.product.stock / _unit.multiplier;
      return _isWeight ? m : m.floorToDouble();  // kg — floor qilmaymiz
    }
    return 9999;
  }

  double get _inCart {
    if (widget.product.hasVariants) {
      final key = '${widget.product.id}_v${_selVariantId}';
      return widget.cart.where((c) => c.key == key).fold(0.0, (s, c) => s + c.qty);
    }
    final key = '${widget.product.id}_${_unit.unitId}';
    return widget.cart.where((c) => c.key == key).fold(0.0, (s, c) => s + c.qty);
  }

  bool get _out => _maxQty <= 0;

  void _addToCartWithFeedback() {
    final p = widget.product;
    final q = _isWeight ? (_qty <= 0 ? 0.0 : _qty) : _qty.roundToDouble().clamp(1, 9999).toDouble();
    if (q <= 0) return;
    if (p.hasVariants) {
      final v = _selVariant;
      if (v == null) return;
      widget.onAddVariant(p, v, q);
    } else {
      widget.onAdd(p, _unit, null, q);   // onAdd endi qty (kasr) qabul qiladi
    }
    setState(() => _added = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _added = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: Column(children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Row(children: [
                  Icon(Icons.chevron_left_rounded, size: 22, color: kTextSub),
                  SizedBox(width: 4),
                  Text('Boshqa mahsulotlar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextSub)),
                ]),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(color: Color(0xFFF2F2F2), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, size: 18, color: kTextSub),
                ),
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                // Image
                Container(
                  width: double.infinity,
                  color: const Color(0xFFFAFAFA),
                  padding: const EdgeInsets.all(32),
                  child: Center(child: _buildImage()),
                ),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),

                // Info
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (p.categoryName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(p.categoryName!.toUpperCase(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextSub, letterSpacing: .5)),
                      ),
                    Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kText, height: 1.25)),
                    const SizedBox(height: 14),
                    Text(moneyFormat(_selVariant?.curPrice ?? _unit.curPrice, _selVariant?.currency ?? _unit.currency), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kText)),
                    const SizedBox(height: 16),

                    // Variant picker
                    if (p.hasVariants && p.variants.isNotEmpty) ...[
                      const Text('VARIANT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextSub, letterSpacing: .4)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: p.variants.map((v) {
                        final isActive = v.id == _selVariantId;
                        final unavailable = !v.inStock;
                        return GestureDetector(
                          onTap: unavailable ? null : () => setState(() { _selVariantId = v.id; _qty = 1; }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive ? kAccentBg : Colors.transparent,
                              border: Border.all(
                                color: isActive ? kAccent : unavailable ? const Color(0xFFDDDDDD) : kBorder,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(v.name,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: isActive ? kAccentDark : unavailable ? const Color(0xFFBBBBBB) : const Color(0xFF555555))),
                              const SizedBox(height: 2),
                              Text(moneyFormat(v.curPrice, v.currency),
                                style: TextStyle(fontSize: 11,
                                  color: isActive ? kAccentDark.withAlpha(180) : unavailable ? const Color(0xFFCCCCCC) : const Color(0xFF888888))),
                              if (v.stock != null)
                                Text('${v.stock!.floor()} ta',
                                  style: TextStyle(fontSize: 10,
                                    color: isActive ? kAccentDark.withAlpha(140) : const Color(0xFFAAAAAA))),
                            ]),
                          ),
                        );
                      }).toList()),
                      const SizedBox(height: 16),
                    ],

                    // Unit chips (non-variant)
                    if (!p.hasVariants && p.units.length > 1) ...[
                      const Text('BIRLIK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextSub, letterSpacing: .4)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: p.units.asMap().entries.map((e) {
                        final isActive = e.key == _unitIdx;
                        return GestureDetector(
                          onTap: () => setState(() { _unitIdx = e.key; _qty = 1; _qtyCtrl.text = '1'; }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive ? kAccentBg : Colors.transparent,
                              border: Border.all(color: isActive ? kAccent : kBorder, width: 2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(e.value.unitName,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                color: isActive ? kAccentDark : const Color(0xFF555555))),
                          ),
                        );
                      }).toList()),
                      const SizedBox(height: 16),
                    ],

                    // Stock info
                    if (_out)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(children: const [
                          Icon(Icons.cancel_outlined, size: 16, color: kRed),
                          SizedBox(width: 6),
                          Text("Stokda yo'q", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kRed)),
                        ]),
                      )
                    else if (!p.hasVariants && p.stockType == 'tracked')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 16, color: kGreen),
                          const SizedBox(width: 6),
                          Text('Stokda: ${fmtQty(_maxQty)} ${_unit.unitName}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kGreen)),
                        ]),
                      )
                    else if (p.hasVariants && _selVariant != null && _selVariant!.stock != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 16, color: kGreen),
                          const SizedBox(width: 6),
                          Text('Stokda: ${_selVariant!.stock!.floor()} ta',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kGreen)),
                        ]),
                      ),

                    // In cart badge
                    if (_inCart > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.check_rounded, size: 16, color: kGreen),
                          const SizedBox(width: 6),
                          Text('Savatda: ${fmtQty(_inCart)} ${_isWeight ? _unit.unitName : 'ta'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kGreen)),
                        ]),
                      ),

                    // Qty + Add
                    Row(children: [
                      if (_isWeight)
                        // kg tovar — kasr og'irlik kiritish
                        Container(
                          width: 132, height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(border: Border.all(color: kBorder, width: 2), borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            Expanded(child: TextField(
                              controller: _qtyCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: '0.5', contentPadding: EdgeInsets.zero),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kText),
                              onChanged: (v) => setState(() => _qty = double.tryParse(v.replaceAll(',', '.')) ?? 0),
                            )),
                            Text(_unit.unitName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kAccentDark)),
                          ]),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(border: Border.all(color: kBorder, width: 2), borderRadius: BorderRadius.circular(12)),
                          height: 50,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            _QBtn(Icons.remove_rounded, () => setState(() => _qty = (_qty - 1).clamp(1.0, 9999.0).toDouble())),
                            SizedBox(width: 40, child: Center(child: Text(fmtQty(_qty), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kText)))),
                            _QBtn(Icons.add_rounded, () => setState(() => _qty = (_qty + 1).clamp(1.0, (_maxQty - _inCart).clamp(1.0, 9999.0)).toDouble())),
                          ]),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: (_out || _added) ? null : _addToCartWithFeedback,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            height: 50,
                            decoration: BoxDecoration(
                              color: _out
                                  ? const Color(0xFFF0F0F0)
                                  : _added
                                      ? const Color(0xFF22C55E)
                                      : kAccent,
                              borderRadius: BorderRadius.circular(14),
                              border: _out ? null : Border.all(color: Colors.white.withAlpha(100), width: 2),
                              boxShadow: _out
                                  ? []
                                  : [BoxShadow(
                                      color: (_added ? const Color(0xFF22C55E) : kAccent).withAlpha(90),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    )],
                            ),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: _added
                                    ? const Icon(Icons.check_rounded, size: 20, color: Colors.white, key: ValueKey('check'))
                                    : Icon(Icons.shopping_cart_rounded, size: 20,
                                        color: _out ? const Color(0xFFCCCCCC) : Colors.white,
                                        key: const ValueKey('cart')),
                              ),
                              const SizedBox(width: 8),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  _out ? "Stokda yo'q" : _added ? "Qo'shildi!" : "Savatga qo'shish",
                                  key: ValueKey(_out ? 'out' : _added ? 'added' : 'add'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _out ? const Color(0xFFCCCCCC) : _added ? Colors.white : Colors.white,
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ]),

                    // Description
                    if (p.description != null && p.description!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Divider(color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 12),
                      Text(p.description!, style: const TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.6)),
                    ],
                    const SizedBox(height: 40),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildImage() {
    final url = ApiService.mediaUrl(widget.product.image);
    if (url.isEmpty) return const Icon(Icons.inventory_2_outlined, size: 100, color: Color(0xFFD0D0D0));
    return CachedNetworkImage(
      imageUrl: url, height: 280, fit: BoxFit.contain,
      errorWidget: (_, __, ___) => const Icon(Icons.inventory_2_outlined, size: 100, color: Color(0xFFD0D0D0)),
      placeholder: (_, __) => const SizedBox(height: 280),
    );
  }
}

class _QBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _QBtn(this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(width: 44, height: 50, child: Icon(icon, size: 20, color: const Color(0xFF555555))),
  );
}
