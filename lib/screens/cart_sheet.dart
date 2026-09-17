import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/theme.dart';

class CartSheet extends StatelessWidget {
  final List<CartItem> items;
  final void Function(String, double) setQty;
  final void Function(String) remove;
  final VoidCallback onCheckout;

  const CartSheet({super.key, required this.items, required this.setQty, required this.remove, required this.onCheckout});

  double get _total => items.fold(0, (s, i) => s + i.price * i.qty);
  int get _count => items.length;

  // kg tovar miqdorini kasr bilan tahrirlash (dialog)
  void _editWeightQty(BuildContext context, CartItem it) {
    final ctrl = TextEditingController(text: fmtQty(it.qty));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${it.name} — og\'irlik', style: const TextStyle(fontSize: 15)),
        content: TextField(
          controller: ctrl, autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(suffixText: it.unitName, hintText: '0.5', border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor')),
          TextButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;
              Navigator.pop(context);
              setQty(it.key, v);
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(color: kSurface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 14, bottom: 0),
          decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(children: [
            const Text('Savatcha', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kText)),
            if (_count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(999)),
                child: Text('$_count ta', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextSub)),
              ),
            ],
            const Spacer(),
            GestureDetector(onTap: () => Navigator.pop(context),
              child: Container(width: 30, height: 30, decoration: BoxDecoration(color: const Color(0xFFF2F2F2), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 16, color: kTextSub))),
          ]),
        ),

        // Items
        Flexible(
          child: items.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Column(children: [
                  const Text('🛒', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  const Text('Savat bo\'sh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTextMuted)),
                  const SizedBox(height: 6),
                  const Text('Mahsulot qo\'shish uchun katalogga qayting', style: TextStyle(fontSize: 13, color: kTextMuted)),
                ]),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF5F5F5), indent: 20, endIndent: 20),
                itemBuilder: (_, idx) {
                  final it = items[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(children: [
                      // Thumb
                      Container(width: 60, height: 60,
                        decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(14)),
                        child: ClipRRect(borderRadius: BorderRadius.circular(14),
                          child: _buildThumb(it.image))),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(it.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kText)),
                        const SizedBox(height: 3),
                        Text(moneyFormat(it.curPrice * it.qty, it.currency), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kAccentDark)),
                        Text('${moneyFormat(it.curPrice, it.currency)} × ${fmtQty(it.qty)} ${it.unitName}', style: const TextStyle(fontSize: 11, color: kTextMuted)),
                      ])),
                      const SizedBox(width: 8),
                      // Qty controls — kg tovarda kasr (tap → tahrir), oddiyda +/-
                      if (it.weight)
                        Row(children: [
                          InkWell(
                            onTap: () => _editWeightQty(context, it),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(border: Border.all(color: kBorder, width: 1.5), borderRadius: BorderRadius.circular(9)),
                              child: Text('${fmtQty(it.qty)} ${it.unitName}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _CQBtn(color: const Color(0xFFFEE2E2), icon: Icons.close_rounded, iconColor: kRed, onTap: () => remove(it.key)),
                        ])
                      else
                        Row(children: [
                          _CQBtn(
                            color: it.qty == 1 ? const Color(0xFFFEE2E2) : null,
                            icon: it.qty == 1 ? Icons.close_rounded : Icons.remove_rounded,
                            iconColor: it.qty == 1 ? kRed : const Color(0xFF333333),
                            onTap: () => it.qty == 1 ? remove(it.key) : setQty(it.key, it.qty - 1),
                          ),
                          SizedBox(width: 28, child: Center(
                            child: Text(fmtQty(it.qty), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kText)))),
                          _CQBtn(icon: Icons.add_rounded, onTap: () => setQty(it.key, it.qty + 1)),
                        ]),
                    ]),
                  );
                },
              ),
        ),

        // Footer
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 16),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFFBEB), Color(0xFFFFF8D6)]),
                border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                const Text('Jami summa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF92740A))),
                const Spacer(),
                Text(cartTotalStr(items), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kText)),
              ]),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: items.isEmpty ? null : () { Navigator.pop(context); onCheckout(); },
              child: Container(
                width: double.infinity, height: 52,
                decoration: BoxDecoration(
                  color: items.isEmpty ? const Color(0xFFF0F0F0) : kAccent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: items.isEmpty ? [] : [BoxShadow(color: kAccent.withAlpha(100), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Buyurtma berish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: items.isEmpty ? const Color(0xFFBBBBBB) : Colors.white)),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18, color: items.isEmpty ? const Color(0xFFBBBBBB) : Colors.white),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

Widget _buildThumb(String? image) {
  const placeholder = Icon(Icons.inventory_2_outlined, size: 28, color: Color(0xFFD0D0D0));
  final url = ApiService.mediaUrl(image);
  if (url.isEmpty) return placeholder;
  return CachedNetworkImage(
    imageUrl: url, fit: BoxFit.contain,
    errorWidget: (_, __, ___) => placeholder,
    placeholder: (_, __) => const SizedBox.shrink(),
  );
}

class _CQBtn extends StatelessWidget {
  final IconData icon; final Color? color; final Color? iconColor; final VoidCallback onTap;
  const _CQBtn({required this.icon, this.color, this.iconColor, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30, margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color ?? kSurface, borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color != null ? Colors.transparent : kBorder, width: 1.5)),
      child: Icon(icon, size: 14, color: iconColor ?? const Color(0xFF333333)),
    ),
  );
}
