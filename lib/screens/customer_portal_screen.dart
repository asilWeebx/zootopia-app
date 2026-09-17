import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/theme.dart';

class CustomerPortalScreen extends StatefulWidget {
  final Customer customer;
  final VoidCallback onLogout;
  const CustomerPortalScreen({super.key, required this.customer, required this.onLogout});
  @override
  State<CustomerPortalScreen> createState() => _CustomerPortalScreenState();
}

class _CustomerPortalScreenState extends State<CustomerPortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  CustomerData? _data;
  bool _loading = true;
  String _err = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _err = ''; });
    try {
      final data = await ApiService.getCustomerData(widget.customer.code);
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _err = friendlyError(e); _loading = false; });
    }
  }

  Future<void> _refresh() => _loadData();

  // App Store 5.1.1(v): hisobni o'chirish — tasdiq dialogi bilan
  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Hisobni o'chirish", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kText)),
        content: const Text(
          "Hisobingiz o'chiriladi va ilovaga qayta kira olmaysiz.\n\n"
          "Xarid va qarz yozuvlari qonuniy hisob yuritish uchun do'konda saqlanadi.\n\n"
          "Davom etasizmi?",
          style: TextStyle(fontSize: 13.5, color: kTextSub, height: 1.45),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish', style: TextStyle(color: kTextSub, fontWeight: FontWeight.w600))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text("O'chirish", style: TextStyle(color: kRed, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ApiService.deleteAccount(widget.customer.code);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Xatolik: $e", style: const TextStyle(fontSize: 13)),
        backgroundColor: kRed,
      ));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Hisobingiz o'chirildi", style: TextStyle(fontSize: 13)),
    ));
    widget.onLogout();
    Navigator.pop(context);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(
      backgroundColor: Colors.white, surfaceTintColor: Colors.white, elevation: 0,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: kTextSub), onPressed: () => Navigator.pop(context)),
      title: const Text('Mening hisobim', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kText)),
      actions: [
        TextButton(
          onPressed: () { widget.onLogout(); Navigator.pop(context); },
          child: const Text('Chiqish', style: TextStyle(color: kRed, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(49), child: Column(children: [
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        TabBar(
          controller: _tabs,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          labelColor: kText, unselectedLabelColor: kTextSub,
          indicatorColor: kAccent, indicatorWeight: 2.5,
          tabs: const [Tab(text: 'Hisobim'), Tab(text: 'Xaridlar'), Tab(text: 'Zakazlar'), Tab(text: "To'lovlar")],
        ),
      ])),
    ),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2))
      : _err.isNotEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('😕', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(_err, style: const TextStyle(color: kTextMuted, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(onPressed: () { setState(() => _loading = true); _loadData(); },
              child: const Text('Qayta urinish', style: TextStyle(color: kAccentDark))),
          ]))
        : RefreshIndicator(
            onRefresh: _refresh,
            color: kAccent,
            child: TabBarView(
              controller: _tabs,
              children: [
                _ProfileTab(customer: widget.customer, data: _data, onDeleteAccount: _deleteAccount),
                _SalesTab(sales: _data?.sales ?? [], onRefresh: _refresh),
                _OrdersTab(orders: _data?.orders ?? [], onRefresh: _refresh),
                _PaymentsTab(payments: _data?.payments ?? [], onRefresh: _refresh),
              ],
            ),
          ),
  );
}

// ── Profile Tab ──────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final Customer customer;
  final CustomerData? data;
  final VoidCallback onDeleteAccount;
  const _ProfileTab({required this.customer, this.data, required this.onDeleteAccount});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Clean white profile card
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0F0F0), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 14, offset: const Offset(0, 3))]),
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          CircleAvatar(radius: 28, backgroundColor: kAccent,
            child: Text(customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('MIJOZ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kTextMuted, letterSpacing: .6)),
            const SizedBox(height: 2),
            Text(customer.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kText),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              [customer.code, if (customer.phone != null && customer.phone!.isNotEmpty) customer.phone!].join(' · '),
              style: const TextStyle(fontSize: 12, color: kTextSub),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ])),
        ]),
      ),
      const SizedBox(height: 14),

      // Debt / Credit cards — use data.customer (has real debt/credit from portal API)
      if (data != null) ...[
        Row(children: [
          Expanded(child: _FinCard(
            label: 'Qarz',
            value: somFormat(data!.customer.debt),
            bg: data!.customer.debt > 0 ? const Color(0xFFFFF5F5) : const Color(0xFFF8F8F8),
            border: data!.customer.debt > 0 ? const Color(0xFFFFCDD2) : const Color(0xFFF0F0F0),
            color: data!.customer.debt > 0 ? kRed : kTextMuted,
            icon: Icons.account_balance_wallet_outlined,
          )),
          const SizedBox(width: 12),
          Expanded(child: _FinCard(
            label: "Ortiqcha to'lov",
            value: somFormat(data!.customer.credit),
            bg: data!.customer.credit > 0 ? const Color(0xFFF0FDF4) : const Color(0xFFF8F8F8),
            border: data!.customer.credit > 0 ? const Color(0xFFBBF7D0) : const Color(0xFFF0F0F0),
            color: data!.customer.credit > 0 ? kGreen : kTextMuted,
            icon: Icons.check_circle_outline_rounded,
          )),
        ]),
        const SizedBox(height: 12),

        // Total spent
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF0F0F0), width: 1.5)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            const Text('Jami xarid qilingan', style: TextStyle(fontSize: 13, color: kTextSub, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(somFormat(data!.totalSpent), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kText)),
          ]),
        ),
        const SizedBox(height: 12),

        // Activity counts
        Row(children: [
          _CountCard('Xaridlar', data!.sales.length),
          const SizedBox(width: 10),
          _CountCard('Zakazlar', data!.orders.length),
          const SizedBox(width: 10),
          _CountCard("To'lovlar", data!.payments.length),
        ]),
      ],
      const SizedBox(height: 24),

      // App Store 5.1.1(v): hisobni o'chirish tugmasi
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onDeleteAccount,
          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: kRed),
          label: const Text("Hisobni o'chirish",
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kRed)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13),
            side: const BorderSide(color: Color(0xFFFFCDD2), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Center(child: Text(
        "Xarid va qarz yozuvlari qonuniy hisob yuritish uchun do'konda saqlanadi",
        style: TextStyle(fontSize: 10.5, color: kTextMuted),
        textAlign: TextAlign.center,
      )),
    ]),
  );
}

class _FinCard extends StatelessWidget {
  final String label, value;
  final Color bg, border, color;
  final IconData icon;
  const _FinCard({required this.label, required this.value, required this.bg, required this.border, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 1.5)),
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: .3)),
      ]),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

class _CountCard extends StatelessWidget {
  final String label;
  final int count;
  const _CountCard(this.label, this.count);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1.5)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(children: [
        Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kText)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: kTextSub, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ── Sales Tab ────────────────────────────────────────────────────────────────
class _SalesTab extends StatelessWidget {
  final List<Sale> sales;
  final Future<void> Function() onRefresh;
  const _SalesTab({required this.sales, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) return _scrollableEmpty('🛍', 'Xaridlar yo\'q hali');
    final total = sales.fold<double>(0, (s, x) => s + x.total);
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      itemCount: sales.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF1E40AF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Jami xaridlar', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(somFormat(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            ])),
            Text('${sales.length} ta', style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600)),
          ]),
        );
        return Padding(padding: const EdgeInsets.only(bottom: 10), child: _SaleCard(sale: sales[i - 1]));
      },
    );
  }
}

class _SaleCard extends StatefulWidget {
  final Sale sale;
  const _SaleCard({required this.sale});
  @override
  State<_SaleCard> createState() => _SaleCardState();
}

class _SaleCardState extends State<_SaleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _expanded ? const Color(0xFFBFDBFE) : const Color(0xFFF0F0F0), width: 1.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF2563EB), size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                widget.sale.receiptNumber.isNotEmpty ? widget.sale.receiptNumber : 'Xarid #${widget.sale.id}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, runSpacing: 3, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.calendar_today_outlined, size: 11, color: kTextMuted),
                  const SizedBox(width: 4),
                  Text(fmtDate(widget.sale.date), style: const TextStyle(fontSize: 11, color: kTextMuted)),
                  if (widget.sale.items.isNotEmpty) ...[
                    const Text('  ·  ', style: TextStyle(fontSize: 11, color: kTextMuted)),
                    Text('${widget.sale.items.length} mahsulot', style: const TextStyle(fontSize: 11, color: kTextMuted)),
                  ],
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(5)),
                  child: Text(paymentMethodLabel(widget.sale.paymentMethod),
                    style: const TextStyle(fontSize: 10, color: kTextSub, fontWeight: FontWeight.w600)),
                ),
              ]),
            ])),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(somFormat(widget.sale.total), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kText)),
              if (widget.sale.debt > 0) ...[
                const SizedBox(height: 2),
                Text('Qarz: ${somFormat(widget.sale.debt)}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kRed)),
              ],
              const SizedBox(height: 4),
              AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: _expanded ? .5 : 0,
                child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: kTextMuted)),
            ]),
          ]),
        ),
      ),
      if (_expanded && widget.sale.items.isNotEmpty) ...[
        const Divider(height: 1, color: Color(0xFFF0F8FF)),
        Container(
          color: const Color(0xFFF8FBFF),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: widget.sale.items.map((it) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF93C5FD), shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(
                '${it.productName}  ×  ${_fmtQty(it)} ${it.unitName}',
                style: const TextStyle(fontSize: 12, color: kTextSub, fontWeight: FontWeight.w500),
              )),
              Text(somFormat(it.price * it.quantity),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText)),
            ]),
          )).toList()),
        ),
        // To'lov xulosasi
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Column(children: [
            _payRow("To'lov usuli", paymentMethodLabel(widget.sale.paymentMethod)),
            // Aralash to'lovda har bir usul alohida
            if (widget.sale.paymentBreakdown.length > 1)
              ...widget.sale.paymentBreakdown.map((b) => Padding(
                padding: const EdgeInsets.only(top: 3),
                child: _payRow(
                  '   · ${paymentMethodLabel(b['method']?.toString() ?? '')}',
                  somFormat(double.tryParse('${b['amount'] ?? 0}') ?? 0),
                ),
              )),
            const SizedBox(height: 3),
            _payRow("To'landi", somFormat(widget.sale.paid)),
            if (widget.sale.debt > 0) ...[
              const SizedBox(height: 3),
              _payRow('Nasiya (qarz)', somFormat(widget.sale.debt), red: true),
            ],
          ]),
        ),
        const SizedBox(height: 4),
      ],
    ]),
  );

  Widget _payRow(String label, String value, {bool red = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: kTextMuted)),
      Text(value, style: TextStyle(
        fontSize: 11.5, fontWeight: FontWeight.w700, color: red ? kRed : kText)),
    ],
  );

  String _fmtQty(SaleItem it) {
    final q = it.quantity;
    return q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(2);
  }
}

// ── Orders Tab ────────────────────────────────────────────────────────────────
class _OrdersTab extends StatelessWidget {
  final List<OnlineOrder> orders;
  final Future<void> Function() onRefresh;
  const _OrdersTab({required this.orders, required this.onRefresh});

  String _statusLabel(String s) => switch(s) {
    'pending'    => 'Kutilmoqda',
    'confirmed'  => 'Tasdiqlandi',
    'delivered'  => 'Yetkazildi',
    'cancelled'  => 'Bekor qilindi',
    _ => s,
  };

  Color _statusColor(String s) => switch(s) {
    'confirmed'  => kGreen,
    'delivered'  => const Color(0xFF2563EB),
    'cancelled'  => kRed,
    _ => kTextSub,
  };

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return _scrollableEmpty('📦', 'Zakazlar yo\'q hali');
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      itemCount: orders.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Onlayn zakazlar', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text('${orders.length} ta zakaz', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            ])),
          ]),
        );
        final o = orders[i - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F0F0), width: 1.5)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: _statusColor(o.status).withAlpha(20), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.local_shipping_rounded, color: _statusColor(o.status), size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Zakaz ${o.orderNo.isNotEmpty ? "#${o.orderNo}" : ""}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText)),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 11, color: kTextMuted),
                  const SizedBox(width: 4),
                  Text(fmtDate(o.createdAt ?? ''), style: const TextStyle(fontSize: 11, color: kTextMuted)),
                ]),
                if (o.note != null && o.note!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(o.note!, style: const TextStyle(fontSize: 11, color: kTextMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ])),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _statusColor(o.status).withAlpha(20), borderRadius: BorderRadius.circular(999)),
                  child: Text(_statusLabel(o.status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor(o.status))),
                ),
                const SizedBox(height: 6),
                Text(somFormat(o.totalAmount ?? 0), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kText)),
              ]),
            ]),
          ),
        );
      },
    );
  }
}

// ── Payments Tab ──────────────────────────────────────────────────────────────
class _PaymentsTab extends StatelessWidget {
  final List<Payment> payments;
  final Future<void> Function() onRefresh;
  const _PaymentsTab({required this.payments, required this.onRefresh});

  static String _label(String t) => switch(t.toLowerCase()) {
    'cash'     => 'Naqd pul',
    'card'     => 'Karta',
    'transfer' => "Bank o'tkazmasi",
    _ => t.isNotEmpty ? t : "To'lov",
  };

  static IconData _icon(String t) => switch(t.toLowerCase()) {
    'cash'     => Icons.payments_rounded,
    'card'     => Icons.credit_card_rounded,
    'transfer' => Icons.account_balance_rounded,
    _ => Icons.attach_money_rounded,
  };

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) return _scrollableEmpty('💳', "To'lovlar yo'q hali");

    final total = payments.fold<double>(0, (s, p) => s + p.amount);

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      itemCount: payments.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          // Summary header
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Jami to'lovlar", style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(somFormat(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              ])),
              Text('${payments.length} ta', style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600)),
            ]),
          );
        }
        final p = payments[i - 1];
        final label = _label(p.type);
        final icon = _icon(p.type);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F0F0), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: kGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText)),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 11, color: kTextMuted),
                  const SizedBox(width: 4),
                  Text(fmtDate(p.date), style: const TextStyle(fontSize: 12, color: kTextMuted)),
                ]),
              ])),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('+${somFormat(p.amount)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kGreen)),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(999)),
                  child: const Text("To'landi", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kGreen)),
                ),
              ]),
            ]),
          ),
        );
      },
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String icon, label;
  const _EmptyState({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Text(icon, style: const TextStyle(fontSize: 48)),
    const SizedBox(height: 12),
    Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextMuted)),
    const SizedBox(height: 8),
    const Text('Yangilash uchun pastga torting', style: TextStyle(fontSize: 12, color: kTextMuted)),
  ]));
}

// Scrollable empty state for RefreshIndicator compatibility
Widget _scrollableEmpty(String icon, String label) => CustomScrollView(
  physics: const AlwaysScrollableScrollPhysics(),
  slivers: [SliverFillRemaining(child: _EmptyState(icon: icon, label: label))],
);
