import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../config/theme.dart';
import '../../l10n/strings.dart';
import '../../services/currency.dart';

/// − qiymat + va qiymatni yozish mumkin. Yozilgani faqat fokus ketganda yoki
/// Enter'da qo'llanadi — "1"ni o'chirib "2000" yozganda oraliq qiymatlardan
/// sakramaydi.
class QtyStepper extends StatefulWidget {
  final double value;
  final ValueChanged<int> onStep;
  /// Yozilgan matnni oladi; qiymatni ota widget hal qiladi.
  final ValueChanged<String> onCommit;
  final bool canDecrease;
  final bool canIncrease;
  /// O'lchanadigan mahsulot "2,5"ni oladi.
  final bool decimal;
  final String? suffix;
  final bool small;
  /// Ota kengligini to'liq egallaydi (kartadagi kabi).
  final bool expand;
  /// Fonsiz, chegarali ko'rinish (savat qatori).
  final bool outlined;

  const QtyStepper({
    super.key,
    required this.value,
    required this.onStep,
    required this.onCommit,
    this.canDecrease = true,
    this.canIncrease = true,
    this.decimal = false,
    this.suffix,
    this.small = false,
    this.expand = false,
    this.outlined = false,
  });

  @override
  State<QtyStepper> createState() => _QtyStepperState();
}

class _QtyStepperState extends State<QtyStepper> {
  final _focus = FocusNode();
  final _ctrl = TextEditingController();
  bool _editing = false;

  String get _shown => fmtNumber(widget.value).replaceAll(' ', '');

  @override
  void initState() {
    super.initState();
    _ctrl.text = _shown;
    _focus.addListener(() {
      if (_focus.hasFocus) {
        setState(() => _editing = true);
        _ctrl.text = _shown;
        _ctrl.selection = TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
      } else {
        _commit();
      }
    });
  }

  @override
  void didUpdateWidget(QtyStepper old) {
    super.didUpdateWidget(old);
    if (!_editing && old.value != widget.value) _ctrl.text = _shown;
  }

  void _commit() {
    if (!_editing) return;
    final draft = _ctrl.text;
    setState(() => _editing = false);
    widget.onCommit(draft);
    _ctrl.text = _shown;
  }

  @override
  void dispose() {
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.outlined ? 36.0 : (widget.small ? 38.0 : 50.0);
    final buttonWidth = widget.outlined ? 34.0 : (widget.small ? 38.0 : 44.0);
    final fontSize = widget.outlined ? 13.0 : (widget.small ? kTextMd : kTextLg);
    final iconColor = widget.outlined ? kInk : kBrand;
    final style = display(fontSize, color: kInk).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final chars = (_editing ? _ctrl.text : _shown).length;
    final painter = TextPainter(
      text: TextSpan(text: '0' * (chars < 2 ? 2 : chars), style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final fieldWidth = painter.width + 6;

    Widget button(IconData icon, bool enabled, int direction, String label) => Semantics(
          button: true,
          label: label,
          enabled: enabled,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled
                ? () {
                    if (_focus.hasFocus) _focus.unfocus();
                    widget.onStep(direction);
                  }
                : null,
            child: SizedBox(
              width: buttonWidth,
              height: height,
              child: Icon(icon, size: widget.outlined ? 14 : 16, color: enabled ? iconColor : kFaint),
            ),
          ),
        );

    return Container(
      height: height,
      constraints: BoxConstraints(minWidth: widget.outlined ? 104 : (widget.small ? 120 : 160)),
      decoration: widget.outlined
          ? BoxDecoration(borderRadius: BorderRadius.circular(kRadiusFull), border: Border.all(color: kBorderStrong, width: 1.5))
          : BoxDecoration(color: kBrandSoft, borderRadius: BorderRadius.circular(kRadiusFull)),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          button(LucideIcons.minus, widget.canDecrease, -1, tr.decrease),
          Flexible(
            child: GestureDetector(
              onTap: () => _focus.requestFocus(),
              // Tor kartada ("12.5 kg", katta shrift) qiymat biroz kichrayadi — chiqib ketmaydi.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: widget.outlined ? 36 : 56),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        textAlign: TextAlign.center,
                        style: style,
                        keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
                        textInputAction: TextInputAction.done,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(widget.decimal ? r'[0-9.,]' : r'[0-9]'))],
                        decoration: const InputDecoration.collapsed(hintText: ''),
                        onSubmitted: (_) => _focus.unfocus(),
                        onTapOutside: (_) => _focus.unfocus(),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (widget.suffix != null) ...[
                      const SizedBox(width: 3),
                      Text(widget.suffix!, style: sans(kTextXs, weight: FontWeight.w600, color: kMuted)),
                    ],
                  ],
                ),
                ),
              ),
            ),
          ),
          button(LucideIcons.plus, widget.canIncrease, 1, tr.increase),
        ],
      ),
    );
  }
}
