import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Text field with exercise-name autocomplete. Submitting free text works too:
/// unknown names are added to the library by the store.
class ExerciseInput extends StatefulWidget {
  const ExerciseInput({
    super.key,
    required this.search,
    required this.onSubmit,
    this.hint = 'Add exercise…',
    this.openUp = true,
  });

  final List<String> Function(String query) search;
  final ValueChanged<String> onSubmit;
  final String hint;
  final bool openUp;

  @override
  State<ExerciseInput> createState() => _ExerciseInputState();
}

class _ExerciseInputState extends State<ExerciseInput> {
  TextEditingController? _controller;
  FocusNode? _focus;

  void _submit(String value) {
    final v = value.trim();
    if (v.isEmpty) return;
    widget.onSubmit(v);
    _controller?.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsViewOpenDirection: widget.openUp ? OptionsViewOpenDirection.up : OptionsViewOpenDirection.down,
      optionsBuilder: (value) => widget.search(value.text),
      onSelected: (name) {
        _submit(name);
        _focus?.requestFocus();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _controller = controller;
        _focus = focusNode;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          style: AppText.body,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.add, color: AppColors.accentLight),
          ),
          onSubmitted: _submit,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: widget.openUp ? Alignment.bottomLeft : Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Material(
              color: AppColors.card,
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 260,
                  maxWidth: MediaQuery.sizeOf(context).width - 2 * AppSpace.screen,
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  children: [
                    for (final o in options)
                      ListTile(
                        dense: true,
                        title: Text(o, style: AppText.body),
                        onTap: () => onSelected(o),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
