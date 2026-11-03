import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../domain/shared_plan.dart';

/// A big QR of the plan for a friend standing next to you to scan in
/// Formazilla (Templates → Import plan → Scan QR code).
class PlanQrScreen extends StatelessWidget {
  const PlanQrScreen({super.key, required this.plan});

  final SharedPlan plan;

  @override
  Widget build(BuildContext context) {
    final size = math.min(MediaQuery.sizeOf(context).width - 2 * AppSpace.xl - 32, 340.0);
    return Scaffold(
      appBar: AppBar(
        title: Text(plan.title),
        actions: [
          IconButton(
            tooltip: 'Send as message',
            icon: const Icon(Icons.ios_share),
            onPressed: () => SharePlus.instance.share(ShareParams(text: planMessage(plan, withCode: true))),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.text, borderRadius: BorderRadius.circular(20)),
                child: QrImageView(
                  data: planCode(plan),
                  version: QrVersions.auto,
                  size: size,
                  backgroundColor: AppColors.text,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(plan.title, style: AppText.title, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(plan.summary, style: AppText.caption),
              const SizedBox(height: AppSpace.md),
              const Text(
                'Your friend scans it in Formazilla → Templates → Import plan → Scan QR code.\n'
                'Turn your screen brightness up if it won’t scan.',
                style: AppText.small,
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
