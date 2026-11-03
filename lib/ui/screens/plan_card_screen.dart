import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../domain/shared_plan.dart';
import '../widgets/common.dart';
import '../widgets/plan_share_card.dart';

/// Preview of a shared plan as an image, with Share (the share sheet also
/// offers saving). For a plan friends can import, use "Formazilla plan".
class PlanCardScreen extends StatefulWidget {
  const PlanCardScreen({super.key, required this.plan});

  final SharedPlan plan;

  @override
  State<PlanCardScreen> createState() => _PlanCardScreenState();
}

class _PlanCardScreenState extends State<PlanCardScreen> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary = _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/formazilla-plan.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: '${widget.plan.title} · #Formazilla',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Plan card')),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RepaintBoundary(key: _cardKey, child: PlanShareCard(plan: widget.plan)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.md, AppSpace.screen, AppSpace.lg),
            child: PrimaryButton(_busy ? 'Preparing…' : 'Share or save', onPressed: _busy ? null : _share),
          ),
        ]),
      ),
    );
  }
}
