/// All screen-to-screen navigation in one place.
library;

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../domain/shared_plan.dart';
import 'screens/ai_reply_screen.dart';
import 'screens/exercise_detail_screen.dart';
import 'screens/plan_card_screen.dart';
import 'screens/plan_qr_screen.dart';
import 'screens/record_card_screen.dart';
import 'screens/rotation_detail_screen.dart';
import 'screens/scan_plan_screen.dart';
import 'screens/session_detail_screen.dart';
import 'screens/session_screen.dart';
import 'screens/split_days_screen.dart';

Future<void> openSession(BuildContext context, Session s, {bool replace = false}) {
  final route = MaterialPageRoute<void>(builder: (_) => SessionScreen(sessionId: s.id));
  return replace ? Navigator.of(context).pushReplacement(route) : Navigator.of(context).push(route);
}

Future<void> openExercise(BuildContext context, String name) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ExerciseDetailScreen(name: name)));

Future<void> openRotation(BuildContext context, Rotation rotation) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => RotationDetailScreen(rotationId: rotation.id)));

Future<void> openSessionDetail(BuildContext context, Session s) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SessionDetailScreen(sessionId: s.id)));

Future<void> openRecordCard(BuildContext context, String exercise,
    {String? subtitle, int? prsToday, bool replace = false}) {
  final route = MaterialPageRoute<void>(
    builder: (_) => RecordCardScreen(exercise: exercise, subtitle: subtitle, prsToday: prsToday),
  );
  return replace ? Navigator.of(context).pushReplacement(route) : Navigator.of(context).push(route);
}

Future<void> openSplitDays(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SplitDaysScreen()));

Future<void> openPlanCard(BuildContext context, SharedPlan plan) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlanCardScreen(plan: plan)));

Future<void> openPlanQr(BuildContext context, SharedPlan plan) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlanQrScreen(plan: plan)));

/// Opens the camera; returns the scanned plan text, or null.
Future<String?> scanPlanQr(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<String>(builder: (_) => const ScanPlanScreen()));

/// An AI's answer, pasted back.
Future<void> openAiReply(BuildContext context, String text) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AiReplyScreen(text: text)));
