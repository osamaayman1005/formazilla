import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme.dart';
import '../../domain/shared_plan.dart';

/// Camera view that closes as soon as it sees a Formazilla plan QR and
/// returns the scanned text (null if the user backs out).
class ScanPlanScreen extends StatefulWidget {
  const ScanPlanScreen({super.key});

  @override
  State<ScanPlanScreen> createState() => _ScanPlanScreenState();
}

class _ScanPlanScreenState extends State<ScanPlanScreen> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _done = false;
  bool _wrongCode = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final code in capture.barcodes) {
      final raw = code.rawValue;
      if (readPlan(raw) != null) {
        _done = true;
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(raw);
        return;
      }
    }
    if (!_wrongCode && capture.barcodes.isNotEmpty) setState(() => _wrongCode = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR code')),
      body: Stack(alignment: Alignment.center, children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),
        IgnorePointer(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accentLight, width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Positioned(
          left: AppSpace.xl,
          right: AppSpace.xl,
          bottom: AppSpace.xl,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.card)),
            child: Text(
              _wrongCode
                  ? 'That QR isn’t a Formazilla plan. Ask your friend to open Share → QR code.'
                  : 'Point at the QR on your friend’s phone',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ]),
    );
  }
}
