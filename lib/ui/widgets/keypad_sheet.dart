import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import 'common.dart';

/// What the keypad returns. [deleted] means "remove this set".
class KeypadResult {
  final double? weight;
  final bool dropSet;
  final bool deleted;
  const KeypadResult({this.weight, this.dropSet = false, this.deleted = false});
}

/// Bottom sheet number pad. No system keyboard, big keys, quick ± buttons.
Future<KeypadResult?> showWeightKeypad(
  BuildContext context, {
  required String title,
  double? initial,
  bool dropSet = false,
  bool allowDelete = false,
}) {
  return showModalBottomSheet<KeypadResult>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _Keypad(title: title, initial: initial, dropSet: dropSet, allowDelete: allowDelete),
  );
}

class _Keypad extends StatefulWidget {
  const _Keypad({required this.title, this.initial, required this.dropSet, required this.allowDelete});

  final String title;
  final double? initial;
  final bool dropSet;
  final bool allowDelete;

  @override
  State<_Keypad> createState() => _KeypadState();
}

class _KeypadState extends State<_Keypad> {
  late String _text = widget.initial == null ? '' : formatWeight(widget.initial!);
  late bool _dropSet = widget.dropSet;

  double? get _value => double.tryParse(_text);

  void _press(String key) {
    setState(() {
      if (key == '⌫') {
        if (_text.isNotEmpty) _text = _text.substring(0, _text.length - 1);
      } else if (key == '.') {
        if (!_text.contains('.')) _text = _text.isEmpty ? '0.' : '$_text.';
      } else if (_text.length < 7) {
        _text = _text == '0' ? key : '$_text$key';
      }
    });
  }

  void _bump(double delta) {
    final v = ((_value ?? 0) + delta).clamp(0, 99999).toDouble();
    setState(() => _text = formatWeight(v));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: AppText.caption, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              _text.isEmpty ? '0' : _text,
              textAlign: TextAlign.center,
              style: AppText.display.copyWith(
                fontSize: 48,
                color: _text.isEmpty ? AppColors.muted : AppColors.text,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Row(children: [
              for (final d in const [-5.0, -2.5, 2.5, 5.0])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _Key(label: d > 0 ? '+${formatWeight(d)}' : formatWeight(d), small: true, onTap: () => _bump(d)),
                  ),
                ),
            ]),
            const SizedBox(height: AppSpace.sm),
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['.', '0', '⌫'],
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  for (final k in row)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _Key(label: k, onTap: () => _press(k)),
                      ),
                    ),
                ]),
              ),
            const SizedBox(height: AppSpace.xs),
            Row(children: [
              Expanded(
                child: FilterChip(
                  label: const Text('Drop set'),
                  selected: _dropSet,
                  onSelected: (v) => setState(() => _dropSet = v),
                ),
              ),
              if (widget.allowDelete)
                TextButton.icon(
                  onPressed: () => Navigator.pop(context, const KeypadResult(deleted: true)),
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  label: const Text('Delete set', style: TextStyle(color: AppColors.danger)),
                ),
            ]),
            const SizedBox(height: AppSpace.md),
            PrimaryButton(
              'Save',
              onPressed: _value == null
                  ? null
                  : () => Navigator.pop(context, KeypadResult(weight: _value, dropSet: _dropSet)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap, this.small = false});

  final String label;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: small ? AppColors.bg : AppColors.chip,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: small ? 40 : 54,
          child: Center(
            child: Text(label,
                style: TextStyle(
                  fontSize: small ? 15 : 22,
                  fontWeight: FontWeight.w600,
                  color: small ? AppColors.accentLight : AppColors.text,
                )),
          ),
        ),
      ),
    );
  }
}
