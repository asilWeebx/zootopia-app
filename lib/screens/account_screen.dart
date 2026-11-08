import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/store.dart';
import '../config/theme.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/currency.dart';
import '../services/storage.dart';
import '../services/units.dart';
import '../state/scope.dart';
import '../widgets/layout/page.dart';
import '../widgets/ui/basics.dart';
import '../widgets/ui/button.dart';
import 'navigation.dart';

/// `"2026-09-27T…"` → `"27 sentabr 2026"` / `"27 сентября 2026"`.
String formatDate(String? iso) {
  final d = iso == null || iso.isEmpty ? null : DateTime.tryParse(iso)?.toLocal();
  return d == null ? '' : '${d.day} ${tr.months[d.month - 1]} ${d.year}';
}

/// To'lov tizimlari nomi har tilda bir xil.
const _paymentBrands = {'click': 'Click', 'payme': 'Payme', 'uzum': 'Uzum', 'humo': 'Humo', 'uzcard': 'UzCard'};

String paymentLabel(String method) => tr.paymentMethods[method] ?? _paymentBrands[method] ?? (method.isEmpty ? '—' : method);

/// Buyurtma holati ranglari; yorlig'i — `tr.statuses`.
const _orderStatus = {
  'new': (Color(0xFFE8EFFB), Color(0xFF2554A8)),
  'confirmed': (kWarningSoft, kWarning),
  'sold': (kSuccessSoft, kSuccess),
  'cancelled': (kSurfaceMuted, kMuted),
};

/// Kabinet (dizayndagi "E · Kabinet"): kirgan mijozga to'q kartada ismi, ID
/// va hisobi, ostida xaridlar, buyurtmalar va to'lovlar, keyin sozlamalar.
/// Kirmaganga — do'kondagi mijoz ID bilan kirish.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.catalog;
    final customer = catalog.customer;
    return TabPage(
      slivers: [
        SliverToBoxAdapter(
          child: Gutter(
            extra: const EdgeInsets.only(top: kSpace2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!catalog.customerReady)
                  const Pulse(child: SkeletonBox(height: 220))
                else if (customer != null)
                  _CustomerPortal(key: ValueKey(customer.customerCode), customer: customer)
                else
                  const _LoginCard(),
                const SizedBox(height: kSpace4),
                _Settings(signedIn: catalog.customerReady && customer != null),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// To'q yashil karta — kirish formasi ham, mijoz hisobi ham shu qolipda.
class _DarkCard extends StatelessWidget {
  final Widget child;
  const _DarkCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(kSpace4),
        decoration: BoxDecoration(color: kDark, borderRadius: BorderRadius.circular(kRadiusXl)),
        child: child,
      );
}

class _Avatar extends StatelessWidget {
  final IconData icon;
  const _Avatar(this.icon);

  @override
  Widget build(BuildContext context) => Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(color: kSun, shape: BoxShape.circle),
        child: Icon(icon, size: 26, color: kOnSun),
      );
}

/// Do'konda berilgan ID (CUST-XXXXXX) bilan kirish.
class _LoginCard extends StatefulWidget {
  const _LoginCard();

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  String _error = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _error = tr.idRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      final customer = await ApiService.login(code);
      if (!mounted) return;
      await context.readCatalog.signIn(customer);
    } catch (e) {
      if (mounted) setState(() => _error = e is StorefrontError || e is NetworkError ? e.toString() : tr.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _DarkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const _Avatar(LucideIcons.idCard),
                const SizedBox(width: kSpace3),
                Expanded(child: Text(tr.loginTitle, style: display(20, color: kOnDark, height: 1.2))),
              ],
            ),
            const SizedBox(height: kSpace3),
            Text(
              tr.loginText,
              style: sans(13, color: kOnDarkMuted, height: 1.5),
            ),
            const SizedBox(height: kSpace4),
            AnimatedContainer(
              duration: kDuration,
              height: 52,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: kSpace4),
              decoration: BoxDecoration(
                color: kDarkRaised,
                borderRadius: BorderRadius.circular(kRadiusFull),
                border: Border.all(color: _focus.hasFocus ? kSun : kDarkLine, width: 1.5),
              ),
              child: TextField(
                controller: _code,
                focusNode: _focus,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.go,
                cursorColor: kSun,
                style: display(kTextLg, color: kOnDark, letterSpacing: kTextLg * .1),
                decoration: InputDecoration.collapsed(
                  hintText: 'CUST-XXXXXX',
                  hintStyle: display(kTextLg, color: kOnDarkMuted.withValues(alpha: .6), letterSpacing: kTextLg * .1),
                ),
                onChanged: (v) {
                  final upper = v.toUpperCase();
                  if (upper != v) _code.value = _code.value.copyWith(text: upper);
                },
                onSubmitted: (_) => _submit(),
                onTapOutside: (_) => _focus.unfocus(),
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: kSpace3),
              Container(
                padding: const EdgeInsets.all(kSpace3),
                decoration: BoxDecoration(color: kDangerSoft, borderRadius: BorderRadius.circular(kRadiusMd)),
                child: Text(_error, textAlign: TextAlign.center, style: sans(13, weight: FontWeight.w600, color: kDanger)),
              ),
            ],
            const SizedBox(height: kSpace3),
            AppButton(label: _busy ? tr.checking : tr.signIn, size: ButtonSize.lg, block: true, onPressed: _busy ? null : _submit),
          ],
        ),
      );
}

enum AccountSection { sales, orders, payments }

class _CustomerPortal extends StatefulWidget {
  final Customer customer;
  const _CustomerPortal({super.key, required this.customer});

  @override
  State<_CustomerPortal> createState() => _CustomerPortalState();
}

class _CustomerPortalState extends State<_CustomerPortal> {
  CustomerAccount? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getCustomer(widget.customer.customerCode);
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e is StorefrontError || e is NetworkError ? e.toString() : tr.loadFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final profile = data?.customer.raw.isNotEmpty == true ? data!.customer : widget.customer;
    final code = widget.customer.customerCode;
    final name = profile.displayName.isNotEmpty ? profile.displayName : code;

    Widget tile(String label, String value, {Map<String, double> extra = const {}, bool wide = false, Color tone = kOnDark}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: kSpace3, vertical: 10),
          decoration: BoxDecoration(color: kDarkRaised, borderRadius: BorderRadius.circular(kRadiusMd)),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(child: Text(label, style: sans(kTextXs, color: kOnDarkMuted))),
                    Text(value, style: display(17, color: tone)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: sans(kTextXs, color: kOnDarkMuted)),
                    const SizedBox(height: 1),
                    FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: display(17, color: tone))),
                    for (final e in extra.entries) Text(money(e.value, e.key), style: sans(kTextXs, weight: FontWeight.w600, color: tone)),
                  ],
                ),
        );

    final debtOn = profile.debt > 0 || profile.currencyDebts.values.any((v) => v > 0);
    final creditOn = profile.credit > 0 || profile.currencyCredits.values.any((v) => v > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const _Avatar(LucideIcons.user),
                  const SizedBox(width: kSpace3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: display(20, color: kOnDark, height: 1.2)),
                        const SizedBox(height: 2),
                        Text(tr.customerId(profile.code.isNotEmpty ? profile.code : code), style: sans(13, color: kOnDarkMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_error != null)
                Text(_error!, style: sans(13, weight: FontWeight.w600, color: kSun))
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: tile(tr.debt, som(profile.debt), extra: profile.currencyDebts, tone: debtOn ? kSun : kOnDark)),
                    const SizedBox(width: kSpace2),
                    Expanded(child: tile(tr.credit, som(profile.credit), extra: profile.currencyCredits, tone: creditOn ? kSun : kOnDark)),
                  ],
                ),
                const SizedBox(height: kSpace2),
                tile(tr.totalSales, data == null ? '…' : som(data.sales.fold<double>(0, (s, x) => s + x.total)), wide: true),
              ],
            ],
          ),
        ),
        const SizedBox(height: kSpace4),
        _MenuCard(rows: [
          _MenuRow(
            icon: LucideIcons.receiptText,
            label: tr.sales,
            count: data?.sales.length,
            onTap: data == null ? null : () => openAccountSection(AccountSection.sales, data),
          ),
          _MenuRow(
            icon: LucideIcons.package,
            label: tr.orders,
            count: data?.onlineOrders.length,
            onTap: data == null ? null : () => openAccountSection(AccountSection.orders, data),
          ),
          _MenuRow(
            icon: LucideIcons.creditCard,
            label: tr.payments,
            count: data?.payments.length,
            onTap: data == null ? null : () => openAccountSection(AccountSection.payments, data),
          ),
        ]),
      ],
    );
  }
}

/// Oq kartadagi qatorlar, orasida chiziq.
class _MenuCard extends StatelessWidget {
  final List<Widget> rows;
  const _MenuCard({required this.rows});

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(kRadiusXl), boxShadow: kShadowSm),
        child: Column(
          children: [
            for (final (i, row) in rows.indexed) ...[if (i > 0) const Divider(height: 1, thickness: 1, color: kBorder), row],
          ],
        ),
      );
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? detail;
  final int? count;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color iconBg;
  final Color iconColor;
  final Color textColor;
  const _MenuRow({
    required this.icon,
    required this.label,
    this.detail,
    this.count,
    this.onTap,
    this.trailing,
    this.iconBg = kBrandSoft,
    this.iconColor = kBrand,
    this.textColor = kInk,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: onTap != null,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpace4, vertical: kSpace2),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                    child: Icon(icon, size: 19, color: iconColor),
                  ),
                  const SizedBox(width: kSpace3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: sans(kTextSm, weight: FontWeight.w600, color: textColor, height: 1.3)),
                        if (detail != null) Text(detail!, style: sans(kTextXs, color: kMuted)),
                      ],
                    ),
                  ),
                  if (count != null) ...[
                    Text('$count', style: sans(13, weight: FontWeight.w600, color: kMuted)),
                    const SizedBox(width: kSpace1),
                  ],
                  trailing ?? (onTap != null ? const Icon(LucideIcons.chevronRight, size: 18, color: kMuted) : const SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Til, tebranish, do'kon telefoni, maxfiylik va (kirganda) chiqish.
class _Settings extends StatelessWidget {
  final bool signedIn;
  const _Settings({required this.signedIn});

  @override
  Widget build(BuildContext context) {
    final haptics = context.haptics;
    final phone = StoreContact.phones.firstOrNull;
    void toggle() {
      haptics.value = !haptics.value;
      Storage.saveHaptics(haptics.value);
    }

    return _MenuCard(rows: [
      _MenuRow(
        icon: LucideIcons.languages,
        label: tr.language,
        iconBg: kSurfaceMuted,
        iconColor: kInkSoft,
        trailing: const _LangSwitch(),
      ),
      _MenuRow(
        icon: LucideIcons.vibrate,
        label: tr.haptics,
        iconBg: kSurfaceMuted,
        iconColor: kInkSoft,
        onTap: toggle,
        trailing: _Switch(on: haptics.value),
      ),
      if (phone != null)
        _MenuRow(
          icon: LucideIcons.phone,
          label: tr.callShop,
          detail: phone,
          iconBg: kSurfaceMuted,
          iconColor: kInkSoft,
          onTap: () => openExternal(telHref(phone)),
        ),
      _MenuRow(icon: LucideIcons.shieldCheck, label: tr.privacy, iconBg: kSurfaceMuted, iconColor: kInkSoft, onTap: openPrivacy),
      if (signedIn)
        _MenuRow(
          icon: LucideIcons.logOut,
          label: tr.logout,
          iconBg: kDangerSoft,
          iconColor: kDanger,
          textColor: kDanger,
          trailing: const SizedBox.shrink(),
          onTap: () async {
            await context.readCatalog.signOut();
          },
        ),
    ]);
  }
}

/// "Русский | O‘zbekcha": tanlangani yashil. Tanlov darhol butun ilovaga
/// qo'llanadi va qurilmada saqlanadi.
class _LangSwitch extends StatelessWidget {
  const _LangSwitch();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AppLang>(
        valueListenable: appLang,
        builder: (context, current, _) => Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: kSurfaceMuted, borderRadius: BorderRadius.circular(kRadiusFull)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, lang) in AppLang.values.indexed) ...[
                if (i > 0) const SizedBox(width: 2),
                Semantics(
                  button: true,
                  selected: lang == current,
                  excludeSemantics: true,
                  label: langName(lang),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: lang == current
                        ? null
                        : () {
                            appLang.value = lang;
                            Storage.saveLang(lang);
                          },
                    child: AnimatedContainer(
                      duration: kDuration,
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: kSpace3),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: lang == current ? kBrand : Colors.transparent, borderRadius: BorderRadius.circular(kRadiusFull)),
                      child: Text(
                        langName(lang),
                        style: sans(13, weight: lang == current ? FontWeight.w700 : FontWeight.w600, color: lang == current ? kOnBrand : kInkSoft),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

class _Switch extends StatelessWidget {
  final bool on;
  const _Switch({required this.on});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: kDuration,
        width: 46,
        height: 28,
        padding: const EdgeInsets.all(3),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(color: on ? kBrand : kBorderStrong, borderRadius: BorderRadius.circular(kRadiusFull)),
        child: Container(width: 22, height: 22, decoration: const BoxDecoration(color: kSurface, shape: BoxShape.circle)),
      );
}

/// Kabinetning "Xaridlar", "Buyurtmalar" yoki "To'lovlar" sahifasi.
class AccountSectionScreen extends StatelessWidget {
  final AccountSection section;
  final CustomerAccount data;
  const AccountSectionScreen({super.key, required this.section, required this.data});

  Widget _empty(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: kSpace12),
        child: Column(
          children: [
            Icon(icon, size: 28, color: kMuted),
            const SizedBox(height: kSpace3),
            Text(text, style: sans(kTextMd, color: kMuted)),
          ],
        ),
      );

  Widget _rowCard({required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: kSpace2),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(kRadiusLg), boxShadow: kShadowSm),
        child: child,
      );

  Widget _summary({required String title, required Widget meta, required Widget right}) => Padding(
        padding: const EdgeInsets.all(kSpace4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(title, style: sans(kTextMd, weight: FontWeight.w700)), meta],
              ),
            ),
            const SizedBox(width: kSpace4),
            right,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final (title, Widget body) = switch (section) {
      AccountSection.sales => (
          tr.sales,
          data.sales.isEmpty
              ? _empty(LucideIcons.receiptText, tr.noSales)
              : Column(children: [for (final (i, s) in data.sales.indexed) _rowCard(child: _SaleRow(sale: s, index: i))]),
        ),
      AccountSection.orders => (
          tr.orders,
          data.onlineOrders.isEmpty
              ? _empty(LucideIcons.package, tr.noOrders)
              : Column(
                  children: [
                    for (final (i, o) in data.onlineOrders.indexed)
                      _rowCard(
                        child: _summary(
                          title: o.orderNo.isNotEmpty ? o.orderNo : tr.orderN(i + 1),
                          meta: Text(formatDate(o.createdAt), style: sans(kTextXs, color: kMuted)),
                          right: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(som(o.total), style: sans(kTextMd, weight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              () {
                                final (bg, fg) = _orderStatus[o.status] ?? (kSurfaceMuted, kMuted);
                                final label = tr.statuses[o.status] ?? (o.status.isEmpty ? '—' : o.status);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(kRadiusFull)),
                                  child: Text(label, style: sans(kTextXs, weight: FontWeight.w700, color: fg)),
                                );
                              }(),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      AccountSection.payments => (
          tr.payments,
          data.payments.isEmpty
              ? _empty(LucideIcons.creditCard, tr.noPayments)
              : Column(
                  children: [
                    for (final p in data.payments)
                      _rowCard(
                        child: _summary(
                          title: formatDate(p.createdAt),
                          meta: p.note.isNotEmpty ? Text(p.note, style: sans(kTextXs, color: kMuted)) : const SizedBox.shrink(),
                          right: Text('+${money(p.amount, p.currency)}', style: sans(kTextMd, weight: FontWeight.w700, color: kSuccess)),
                        ),
                      ),
                  ],
                ),
        ),
    };
    return DetailPage(title: title, slivers: [SliverToBoxAdapter(child: Gutter(child: body))]);
  }
}

class _MethodChip extends StatelessWidget {
  final String method;
  const _MethodChip(this.method);

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (method) {
      'cash' => (const Color(0xFFE4F2E8), const Color(0xFF246239)),
      'card' || 'transfer' => (const Color(0xFFE7EEF8), const Color(0xFF294C82)),
      'credit' || 'installment' => (const Color(0xFFF9EDDA), const Color(0xFF86571B)),
      _ => (kSurfaceMuted, kInk),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(kRadiusFull)),
      child: Text(paymentLabel(method), style: sans(11, weight: FontWeight.w700, color: fg)),
    );
  }
}

/// Bir xarid — bosilsa mahsulotlar va hisob-kitob ochiladi (saytdagi `<details>`).
class _SaleRow extends StatefulWidget {
  final CustomerSale sale;
  final int index;
  const _SaleRow({required this.sale, required this.index});

  @override
  State<_SaleRow> createState() => _SaleRowState();
}

class _SaleRowState extends State<_SaleRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.sale;
    final debtText = s.debtCurrency.isNotEmpty && (s.debtCurrencyAmount ?? 0) > 0 ? money(s.debtCurrencyAmount, s.debtCurrency) : som(s.debt);
    final hasDebt = (s.debt ?? 0) > 0 || (s.debtCurrencyAmount ?? 0) > 0;
    final small = sans(13);
    Widget line(Widget label, String value, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(child: label),
              Text(value, style: sans(13, weight: FontWeight.w600, color: color ?? kInk)),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.all(kSpace4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.receiptNumber.isNotEmpty ? s.receiptNumber : tr.saleN(widget.index + 1), style: sans(kTextMd, weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: kSpace1,
                        children: [
                          Text('${formatDate(s.createdAt)} ·', style: sans(kTextXs, color: kMuted)),
                          _MethodChip(s.paymentMethod),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: kSpace4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(som(s.total), style: sans(kTextMd, weight: FontWeight.w700)),
                    if (hasDebt) Text(tr.debtOf(debtText), style: sans(kTextXs, weight: FontWeight.w700, color: kDanger)),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_open) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(kSpace4, kSpace3, kSpace4, kSpace4),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorder))),
            child: Column(
              children: [
                for (final it in s.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: kSpace2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(it.name, style: sans(kTextSm, color: kInkSoft))),
                        const SizedBox(width: kSpace3),
                        Text('${fmtNumber(it.qty)} ${unitLabel(it.unit)} × ${som(it.price)}', style: sans(kTextSm)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(kSpace4, kSpace4, kSpace4, 6),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorder))),
            child: Column(
              children: [
                line(Text(tr.total, style: small), som(s.total)),
                for (final p in s.paymentBreakdown) line(Align(alignment: Alignment.centerLeft, child: _MethodChip(p.method)), som(p.amount)),
                if (s.paid != null) line(Text(tr.paid, style: small), som(s.paid), color: kSuccess),
                if (s.debt != null || s.debtCurrencyAmount != null)
                  line(Text(tr.debtLeft, style: sans(13, weight: FontWeight.w700, color: kDanger)), debtText, color: kDanger),
                if (s.debtCurrency.isNotEmpty && (s.debtCurrencyAmount ?? 0) > 0)
                  line(
                    Text(tr.debtIn(s.debtCurrency), style: small),
                    [if (s.debtRate != null) tr.rate(som(s.debtRate)), if (s.debt != null) '≈ ${som(s.debt)}'].join(' · '),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
