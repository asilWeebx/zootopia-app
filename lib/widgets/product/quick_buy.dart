import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../l10n/strings.dart';
import '../../models/models.dart';
import '../../screens/navigation.dart';
import '../../services/groups.dart';
import '../../services/options.dart';
import '../../state/scope.dart';
import '../ui/sheet.dart';
import 'buy_box.dart';
import 'group_picker.dart';
import 'option_picker.dart';

/// Kartadan ta'm yoki birlik tanlash — ro'yxatdan chiqmasdan.
Future<void> showQuickBuy(BuildContext context, Product product, BuyOption initial) => showSiteSheet(
      context,
      title: product.name,
      name: '/sheet/quick-buy',
      builder: (_) => _QuickBuy(product: product, initial: initial),
    );

/// Ta'mlar guruhi uchun: plitkalar ochiq, birini tanlasa narxi va miqdori chiqadi.
Future<void> showGroupQuickBuy(BuildContext context, ProductGroup group, Product lead) => showSiteSheet(
      context,
      title: group.title,
      name: '/sheet/quick-buy',
      builder: (_) => _GroupQuickBuy(group: group, lead: lead),
    );

class _QuickBuy extends StatefulWidget {
  final Product product;
  final BuyOption initial;
  const _QuickBuy({required this.product, required this.initial});

  @override
  State<_QuickBuy> createState() => _QuickBuyState();
}

class _QuickBuyState extends State<_QuickBuy> {
  late String _key = widget.initial.key;

  @override
  Widget build(BuildContext context) {
    final showStock = context.catalog.showStock;
    final options = productOptions(widget.product);
    final option = options.where((o) => o.key == _key).firstOrNull ?? options.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OptionPicker(
          options: options,
          selectedKey: _key,
          productImage: widget.product.image,
          showStock: showStock,
          onSelect: (o) => setState(() => _key = o.key),
        ),
        const SizedBox(height: kSpace5),
        BuyBox(key: ValueKey(_key), product: widget.product, option: option, showStock: showStock),
        const SizedBox(height: kSpace5),
        _Details(onTap: () => openProduct(widget.product, optionKey: option.key == 'base' ? null : option.key)),
      ],
    );
  }
}

class _GroupQuickBuy extends StatefulWidget {
  final ProductGroup group;
  final Product lead;
  const _GroupQuickBuy({required this.group, required this.lead});

  @override
  State<_GroupQuickBuy> createState() => _GroupQuickBuyState();
}

class _GroupQuickBuyState extends State<_GroupQuickBuy> {
  late int _activeId = widget.lead.id;
  String? _key;

  @override
  Widget build(BuildContext context) {
    final showStock = context.catalog.showStock;
    final active = widget.group.members.where((m) => m.product.id == _activeId).firstOrNull?.product ?? widget.lead;
    final options = productOptions(active);
    final option = options.where((o) => o.key == _key).firstOrNull ?? defaultOption(options);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlavourPicker(
          group: widget.group,
          activeId: active.id,
          onSelect: (id) => setState(() {
            _activeId = id;
            _key = null;
          }),
        ),
        if (option != null && options.length > 1) ...[
          const SizedBox(height: kSpace5),
          OptionPicker(
            options: options,
            selectedKey: option.key,
            productImage: active.image,
            showStock: showStock,
            onSelect: (o) => setState(() => _key = o.key),
          ),
        ],
        const SizedBox(height: kSpace5),
        if (option != null) BuyBox(key: ValueKey('${active.id}_${option.key}'), product: active, option: option, showStock: showStock),
        const SizedBox(height: kSpace5),
        _Details(onTap: () => openProduct(active)),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  final VoidCallback onTap;
  const _Details({required this.onTap});

  @override
  Widget build(BuildContext context) => Center(
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(kSpace2),
            child: Text(tr.moreDetails, style: sans(kTextMd, weight: FontWeight.w700, color: kAccentInk)),
          ),
        ),
      );
}
