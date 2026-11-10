// Plan codes made on a phone (dart:io gzip) must open on the web version
// (pure-Dart gzip), and the other way round.
@TestOn('vm')
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:formazilla/core/gzip_io.dart' as phone;
import 'package:formazilla/core/gzip_web.dart' as browser;
import 'package:formazilla/data/storage.dart';
import 'package:formazilla/domain/shared_plan.dart';
import 'package:formazilla/state/app_store.dart';

void main() {
  final text = utf8.encode(jsonEncode({'v': 1, 'n': 'Push Pull Legs', 'note': 'é ✓ 37.5' * 40}));

  test('phone gzip opens in the browser codec', () {
    expect(browser.gzipDecode(phone.gzipEncode(text)), text);
  });

  test('browser gzip opens in the phone codec', () {
    expect(phone.gzipDecode(browser.gzipEncode(text)), text);
  });

  test('a whole split shared as FZ2 from the browser codec imports on the phone', () async {
    final store = await AppStore.open(MemoryStorage());
    final plan = store.planForSplit();
    final code = 'FZ2:${base64Url.encode(browser.gzipEncode(utf8.encode(jsonEncode(plan.toJson()))))}';
    final back = readPlan(code)!;
    expect(back.days.map((d) => d.name), plan.days.map((d) => d.name));
    expect(back.days.first.rotations.first.exercises, plan.days.first.rotations.first.exercises);
  });
}
