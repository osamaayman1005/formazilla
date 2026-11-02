import 'package:flutter/material.dart';

import 'app.dart';
import 'data/storage.dart';
import 'state/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await AppStore.open(FileStorage());
  runApp(FormazillaApp(store: store));
}
