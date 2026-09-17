import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/theme.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final List<CartItem> cart;
  final void Function(Product, ProductUnit, [Offset?]) onAdd;
  final void Function(Product) onDetail;
  final void Function(Offset)? onOrb;
  final void Function(Product, ProductUnit, double qty)? onSetQty;
  final bool isFav;
  final VoidCallback? onFav;

  const ProductCard({super.key, required this.product, required this.cart,
    required this.onAdd, required this.onDetail, this.onOrb, this.onSetQty,
    this.isFav = false, this.onFav});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late int _unitIdx;
  bool _added = false;
  final _addKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (!p.hasVariants && p.stockType == 'tracked' && p.units.isNotEmpty) {
      final idx = p.units.indexWhere((u) => (p.stock / u.multiplier).floor() > 0);
      _unitIdx = idx >= 0 ? idx : 0;
    } else {
      _unitIdx = 0;
    }
  }

  void _handleAdd() {
    if (widget.onOrb != null) {
      final box = _addKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final pos = box.localToGlobal(box.size.center(Offset.zero));
        widget.onOrb!(pos);
      }
    }
    widget.onAdd(widget.product, _unit);
    setState(() => _added = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _added = false);
    });
  }

  ProductUnit get _unit => widget.product.units.isNotEmpty ? widget.product.units[_unitIdx] : ProductUnit(unitId: 0, unitName: 'dona', price: 0, multiplier: 1);

  double get _displayPrice {
    final p = widget.product;
    if (p.hasVariants && p.variants.isNotEmpty) return p.variants.first.price;
    return _unit.price;
  }
  String get _dispCur { final p = widget.product; return (p.hasVariants && p.variants.isNotEmpty) ? p.variants.first.currency : _unit.currency; }
  double get _dispCurVal { final p = widget.product; return (p.hasVariants && p.variants.isNotEmpty) ? p.variants.first.curPrice : _unit.curPrice; }

  int get _maxQty {
    final p = widget.product;
    if (p.hasVariants) return p.variants.any((v) => v.inStock) ? 1 : 0;
    if (p.stockType == 'tracked') return (p.stock / _unit.multiplier).floor();
    return 9999;
  }

  double get _inCart {
    final key = '${widget.product.id}_${_unit.unitId}';
    return widget.cart.where((c) => c.key == key).fold(0.0, (s, c) => s + c.qty);
  }

  bool get _out => _maxQty <= 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onDetail(widget.product),
      child: Container(
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (fills remaining space — overflowsiz)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: kImgBg, borderRadius: BorderRadius.circular(14)),
                child: Stack(
                  children: [
                    Center(child: Padding(padding: const EdgeInsets.all(10), child: _buildImage())),
                    if (_out)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(color: Colors.white.withAlpha(150), borderRadius: BorderRadius.circular(14)),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFEDEAE0), borderRadius: BorderRadius.circular(999)),
                              child: const Text('Tugadi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kTextSub)),
                            ),
                          ),
                        ),
                      ),
                    // Sevimli (yurakcha) — chap yuqori
                    if (widget.onFav != null)
                      Positioned(
                        top: 6, left: 6,
                        child: GestureDetector(
                          onTap: widget.onFav,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(235), shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 6)],
                            ),
                            child: Icon(widget.isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 17, color: widget.isFav ? kRed : kTextSub),
                          ),
                        ),
                      ),
                    // Savatda soni — o'ng yuqori
                    if (_inCart > 0)
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(color: kAccent, shape: BoxShape.circle),
                          child: Center(child: Text(fmtQty(_inCart), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Name
            Text(widget.product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText, height: 1.3)),
            const SizedBox(height: 6),
            // Narx — o'z qatorida (hech qachon kichraymaydi)
            Text(
              widget.product.hasVariants ? 'dan ${moneyFormat(_dispCurVal, _dispCur)}' : moneyFormat(_dispCurVal, _dispCur),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kAccent),
            ),
            const SizedBox(height: 8),
            // Boshqaruv: savatda bo'lsa — to'liq kenglikdagi stepper, aks holda o'ngda dumaloq "+"
            SizedBox(
              width: double.infinity, height: 40,
              child: (!widget.product.hasVariants && !_out && _inCart > 0)
                  ? _control()
                  : Align(alignment: Alignment.centerRight, child: _control()),
            ),
          ],
        ),
      ),
    );
  }

  // Narx yonidagi boshqaruv: dumaloq "+" / stepper / variant / tugadi
  Widget _control() {
    if (widget.product.hasVariants) {
      return _circle(
        icon: _out ? Icons.block_rounded : Icons.add_rounded,
        enabled: !_out,
        onTap: _out ? null : () => widget.onDetail(widget.product),
      );
    }
    if (_out) {
      return _circle(icon: Icons.block_rounded, enabled: false, onTap: null);
    }
    if (_inCart > 0) return _stepper();
    return _circle(icon: _added ? Icons.check_rounded : Icons.add_rounded,
      enabled: true, added: _added, addKey: _addKey, onTap: _added ? null : _handleAdd);
  }

  Widget _circle({required IconData icon, required bool enabled, bool added = false, Key? addKey, VoidCallback? onTap}) {
    return GestureDetector(
      key: addKey,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: !enabled ? const Color(0xFFECEAE2) : (added ? kGreen : kAccent),
          shape: BoxShape.circle,
          boxShadow: !enabled ? [] : [BoxShadow(color: (added ? kGreen : kAccent).withAlpha(70), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, size: 22, color: !enabled ? kTextMuted : Colors.white),
      ),
    );
  }

  // To'liq kenglikdagi +/- stepper (savatga qo'shilgach) — − chapda, son o'rtada, + o'ngda
  Widget _stepper() => Container(
        height: 40,
        decoration: BoxDecoration(
          color: kAccent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: kAccent.withAlpha(70), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _StepBtn(Icons.remove_rounded, () => widget.onSetQty?.call(widget.product, _unit, _inCart - 1)),
          Text(fmtQty(_inCart), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          GestureDetector(
            key: _addKey,
            behavior: HitTestBehavior.opaque,
            onTap: (_maxQty - _inCart) > 0 ? _handleAdd : null,
            child: SizedBox(width: 46, height: 40, child: Icon(Icons.add_rounded, size: 20,
                color: (_maxQty - _inCart) > 0 ? Colors.white : Colors.white.withAlpha(110))),
          ),
        ]),
      );

  Widget _buildImage() {
    final url = ApiService.mediaUrl(widget.product.image);
    if (url.isEmpty) return const Icon(Icons.inventory_2_outlined, size: 44, color: Color(0xFFCFC8B6));
    return CachedNetworkImage(
      imageUrl: url, fit: BoxFit.contain,
      errorWidget: (_, __, ___) => const Icon(Icons.inventory_2_outlined, size: 44, color: Color(0xFFCFC8B6)),
      placeholder: (_, __) => const SizedBox.shrink(),
      imageBuilder: (ctx, img) => Image(image: img, fit: BoxFit.contain),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(width: 46, height: 40, child: Icon(icon, size: 20, color: Colors.white)),
      );
}
