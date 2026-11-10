import 'package:flutter/material.dart';

import 'app.dart';
import 'data/platform_storage.dart';
import 'state/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await AppStore.open(defaultStorage());
  runApp(FormazillaApp(store: store));
}
