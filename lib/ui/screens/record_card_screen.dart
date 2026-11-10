import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/pr_share_card.dart';
import '../widgets/store_scope.dart';

/// Preview of the PR card with a Share button (share sheet also offers "Save").
class RecordCardScreen extends StatefulWidget {
  const RecordCardScreen({super.key, required this.exercise, this.subtitle, this.prsToday});

  final String exercise;
  final String? subtitle;
  final int? prsToday;

  @override
  State<RecordCardScreen> createState() => _RecordCardScreenState();
}

class _RecordCardScreenState extends State<RecordCardScreen> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary = _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final png = bytes!.buffer.asUint8List();
      final XFile shared;
      if (kIsWeb) {
        // The web has no files: share the image bytes directly.
        shared = XFile.fromData(png, mimeType: 'image/png', name: 'formazilla-pr.png');
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/formazilla-pr.png');
        await file.writeAsBytes(png, flush: true);
        shared = XFile(file.path, mimeType: 'image/png');
      }
      await SharePlus.instance.share(ShareParams(
        files: [shared],
        text: 'New PR on ${widget.exercise} 💪 #Formazilla',
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Couldn’t share the card: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final data = store.recordCard(widget.exercise);
    return Scaffold(
      appBar: AppBar(title: const Text('PR card')),
      body: data == null
          ? const EmptyState(title: 'No record yet', body: 'Log this exercise to get a PR card.')
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.lg),
                child: Column(children: [
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        child: RepaintBoundary(
                          key: _cardKey,
                          child: PrShareCard(
                            data: data,
                            date: DateTime.now(),
                            subtitle: widget.subtitle,
                            prsToday: widget.prsToday,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  Text('PR ${formatWeight(data.record)} · shares as a story-size image', style: AppText.small),
                  const SizedBox(height: AppSpace.sm),
                  PrimaryButton(_busy ? 'Preparing…' : 'Share or save', onPressed: _busy ? null : _share),
                ]),
              ),
            ),
    );
  }
}
