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

/// Bottom sheet number pad. No system keyboard, big keys.
///
/// With no [initial] it opens clean: nothing to erase, just type. [hint]
/// (e.g. "Last time 35") is shown as information only, never prefilled.
/// With an [initial] value (editing a logged set) the number starts selected,
/// so the first key replaces it; the ± nudges are shown.
Future<KeypadResult?> showWeightKeypad(
  BuildContext context, {
  required String title,
  double? initial,
  bool dropSet = false,
  bool allowDelete = false,
  bool showDropSet = true,
  List<double> bumps = const [-5, -2.5, 2.5, 5],
  String? unit,
  String deleteLabel = 'Delete set',
  String? hint,
}) {
  return showModalBottomSheet<KeypadResult>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _Keypad(
      title: title,
      initial: initial,
      dropSet: dropSet,
      allowDelete: allowDelete,
      showDropSet: showDropSet,
      bumps: bumps,
      unit: unit,
      deleteLabel: deleteLabel,
      hint: hint,
    ),
  );
}

/// Minutes keypad for cardio: ±1 / ±5, no drop set.
Future<KeypadResult?> showMinutesKeypad(BuildContext context, {required String title, double? initial}) =>
    showWeightKeypad(
      context,
      title: title,
      initial: initial,
      allowDelete: initial != null,
      showDropSet: false,
      bumps: const [-5, -1, 1, 5],
      unit: 'min',
      deleteLabel: 'Clear time',
    );

class _Keypad extends StatefulWidget {
  const _Keypad({
    required this.title,
    this.initial,
    required this.dropSet,
    required this.allowDelete,
    required this.showDropSet,
    required this.bumps,
    this.unit,
    required this.deleteLabel,
    this.hint,
  });

  final String title;
  final double? initial;
  final bool dropSet;
  final bool allowDelete;
  final bool showDropSet;
  final List<double> bumps;
  final String? unit;
  final String deleteLabel;
  final String? hint;

  @override
  State<_Keypad> createState() => _KeypadState();
}

class _KeypadState extends State<_Keypad> {
  late String _text = widget.initial == null ? '' : formatWeight(widget.initial!);
  late bool _dropSet = widget.dropSet;

  /// True while an existing value is shown "selected": the next key replaces it.
  late bool _replace = widget.initial != null;

  double? get _value => double.tryParse(_text);

  void _press(String key) {
    setState(() {
      if (_replace) {
        _replace = false;
        if (key == '⌫') {
          _text = '';
          return;
        }
        _text = '';
      }
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
    setState(() {
      _replace = false;
      _text = formatWeight(v);
    });
  }

  Widget _preview() {
    final caption = widget.unit ?? (widget.initial != null ? null : 'type the weight');
    if (_text.isEmpty) {
      return DashedBorder(
        radius: 8,
        color: AppColors.accentLight,
        child: SizedBox(
          width: 132,
          height: 132,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 3, height: 48, decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 10),
            Text(caption ?? 'type the weight',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
          ]),
        ),
      );
    }
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        color: AppColors.stickerFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.stickerEdge, width: 2),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _replace ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(_text, style: AppText.sticker.copyWith(fontSize: 60, color: AppColors.stickerInk)),
          ),
        ),
        if (widget.unit != null) ...[
          const SizedBox(height: 8),
          Text(widget.unit!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.stickerCaption)),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    final value = _value;
    final hint = editing
        ? (_replace ? 'Type to replace it, or nudge it' : null)
        : widget.hint;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.lg),
        // Scrolls only on very short screens or large text, so Save is never cut off.
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.lg),
            Semantics(
              liveRegion: true,
              label: _text.isEmpty ? 'Weight, empty' : 'Weight $_text',
              child: Center(child: _preview()),
            ),
            SizedBox(
              height: 32,
              child: Center(
                child: hint == null ? null : Text(hint, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
              ),
            ),
            if (editing) ...[
              Row(children: [
                for (final d in widget.bumps)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        onPressed: () => _bump(d),
                        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                        child: Text(d > 0 ? '+${formatWeight(d)}' : '−${formatWeight(-d)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: AppSpace.md),
            ],
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['.', '0', '⌫'],
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  for (final k in row)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _Key(label: k, onTap: () => _press(k)),
                      ),
                    ),
                ]),
              ),
            const SizedBox(height: AppSpace.sm),
            Row(children: [
              if (widget.showDropSet) ...[
                SizedBox(
                  height: 56,
                  child: _dropSet
                      ? FilledButton.icon(
                          onPressed: () => setState(() => _dropSet = false),
                          icon: const Icon(Icons.arrow_downward, size: 18),
                          label: const Text('Drop set'),
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.chip, foregroundColor: AppColors.accentLight),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => setState(() => _dropSet = true),
                          icon: const Icon(Icons.arrow_downward, size: 18),
                          label: const Text('Drop set'),
                        ),
                ),
                const SizedBox(width: AppSpace.sm),
              ],
              if (widget.allowDelete) ...[
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, const KeypadResult(deleted: true)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.dangerOutline),
                    ),
                    child: Text(widget.deleteLabel == 'Delete set' ? 'Delete' : widget.deleteLabel),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
              ],
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: value == null
                        ? null
                        : () => Navigator.pop(context, KeypadResult(weight: value, dropSet: _dropSet)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                      disabledBackgroundColor: AppColors.chip,
                      disabledForegroundColor: AppColors.muted,
                    ),
                    child: Text(value == null ? 'Type a weight to save' : 'Save ${formatWeight(value)}',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
            ]),
          ],
        ),
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.chip,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 58,
          child: Center(
            child: label == '⌫'
                ? const Icon(Icons.backspace_outlined, size: 26, color: AppColors.text, semanticLabel: 'Delete last digit')
                : Text(label,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.text, fontFeatures: [FontFeature.tabularFigures()])),
          ),
        ),
      ),
    );
  }
}
