import 'package:flutter/widgets.dart';

import '../../state/app_store.dart';

/// Makes the [AppStore] available to the widget tree and rebuilds dependents
/// when it changes. Use `StoreScope.of(context)`.
class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child}) : super(notifier: store);

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  /// Read without subscribing (for callbacks).
  static AppStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
