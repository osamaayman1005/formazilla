/// "Ask your AI coach": pick a question, see exactly what will be sent, and
/// share it to your own AI app. The app never talks to an AI itself.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../domain/ai_context.dart';
import '../../state/app_store.dart';
import '../navigation.dart';

/// Remembered for the next time the sheet opens (this run only).
AiQuestion? _lastQuestion;

Future<void> showAskAiSheet(BuildContext context, AppStore store) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AskAiSheet(store: store, parent: context),
    );

class _AskAiSheet extends StatefulWidget {
  const _AskAiSheet({required this.store, required this.parent});

  final AppStore store;

  /// The screen under the sheet: replies and snackbars open there.
  final BuildContext parent;

  @override
  State<_AskAiSheet> createState() => _AskAiSheetState();
}

class _AskAiSheetState extends State<_AskAiSheet> {
  final _extra = TextEditingController();
  final _own = TextEditingController();
  late final List<String> _lifts = [
    for (final e in widget.store.exerciseSummaries())
      if (!widget.store.isCardio(e.name)) e.name,
  ];
  late final bool _canReview = widget.store.history.length >= 2;
  late final bool _hasToday = widget.store.finishedTodaySession != null;
  late AiQuestion _q = _initial();
  late String? _lift = _lifts.firstOrNull;
  bool _showText = false;

  AiQuestion _initial() {
    final last = _lastQuestion;
    if (last != null && _available(last)) return last;
    return _canReview ? AiQuestion.review : AiQuestion.newPlan;
  }

  bool _available(AiQuestion q) => switch (q) {
        AiQuestion.review => _canReview,
        AiQuestion.stuck => _lifts.isNotEmpty,
        AiQuestion.today => _hasToday,
        AiQuestion.newPlan || AiQuestion.own => true,
      };

  @override
  void dispose() {
    _extra.dispose();
    _own.dispose();
    super.dispose();
  }

  String get _prompt => widget.store.aiPrompt(_q, extra: _extra.text, exercise: _lift, own: _own.text);

  Future<void> _share() async {
    _lastQuestion = _q;
    final text = _prompt;
    final messenger = ScaffoldMessenger.of(widget.parent);
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) Navigator.pop(context);
    await SharePlus.instance.share(ShareParams(text: text));
    messenger.showSnackBar(const SnackBar(
      content: Text('Copied too. Paste it if your AI app isn’t in the list. Then copy the answer and tap Paste AI reply.'),
      duration: Duration(seconds: 6),
    ));
  }

  Future<void> _paste() async {
    _lastQuestion = _q;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    Navigator.pop(context);
    final text = data?.text?.trim() ?? '';
    if (text.startsWith('I use Formazilla, an offline gym logbook')) {
      ScaffoldMessenger.of(widget.parent).showSnackBar(const SnackBar(
        content: Text('That’s your question, not the answer. Copy your AI’s answer, then tap Paste AI reply.'),
      ));
      return;
    }
    if (text.isEmpty) {
      ScaffoldMessenger.of(widget.parent).showSnackBar(const SnackBar(
        content: Text('Nothing copied yet. Copy your AI’s whole answer, then tap Paste AI reply.'),
      ));
      return;
    }
    if (widget.parent.mounted) await openAiReply(widget.parent, text);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.lg + bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('What should your AI help with?', style: AppText.title),
            const SizedBox(height: 4),
            const Text('Works with ChatGPT, Claude, Gemini or any AI app.', style: AppText.caption),
            const SizedBox(height: AppSpace.md),
            for (final q in AiQuestion.values)
              if (_available(q)) _option(q),
            if (_q == AiQuestion.own) ...[
              const SizedBox(height: AppSpace.xs),
              TextField(
                controller: _own,
                maxLength: 500,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Should I train legs twice a week?', counterText: ''),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: AppSpace.md),
            TextField(
              controller: _extra,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Anything to add?',
                hintText: '4 days, home gym',
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _showText = !_showText),
                icon: Icon(_showText ? Icons.expand_less : Icons.visibility_outlined, size: 20),
                label: Text(_showText ? 'Hide the text' : 'See exactly what will be sent'),
              ),
            ),
            if (_showText)
              Container(
                constraints: const BoxConstraints(maxHeight: 260),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(color: AppColors.divider),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(_prompt, style: AppText.small.copyWith(color: AppColors.text, height: 1.4)),
                ),
              ),
            const SizedBox(height: AppSpace.md),
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _paste,
                    icon: const Icon(Icons.content_paste, size: 20),
                    label: const Text('Paste AI reply', maxLines: 1),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.send_rounded, size: 20),
                    label: const Text('Share to my AI', maxLines: 1),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.onAccent),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _option(AiQuestion q) {
    final selected = _q == q;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        onTap: () => setState(() => _q = q),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 22, color: selected ? AppColors.accentLight : AppColors.muted),
            const SizedBox(width: 12),
            Flexible(child: Text(aiQuestionLabel(q), style: AppText.body)),
            if (q == AiQuestion.stuck && _lifts.isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(
                child: DropdownButton<String>(
                  value: _lift,
                  isExpanded: true,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  dropdownColor: AppColors.chip,
                  style: AppText.body.copyWith(color: AppColors.accentLight, fontWeight: FontWeight.w600),
                  items: [for (final l in _lifts) DropdownMenuItem(value: l, child: Text(l, overflow: TextOverflow.ellipsis))],
                  onChanged: (v) => setState(() {
                    _lift = v;
                    _q = AiQuestion.stuck;
                  }),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
