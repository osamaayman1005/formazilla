import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'state/app_store.dart';
import 'ui/screens/history_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/progress_screen.dart';
import 'ui/screens/templates_screen.dart';
import 'ui/widgets/store_scope.dart';

class FormazillaApp extends StatelessWidget {
  const FormazillaApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'Formazilla',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const AppShell(),
      ),
    );
  }
}

/// Bottom-nav shell: Home, History, Progress, Templates.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  static const _tabs = ['Home', 'History', 'Progress', 'Templates'];
  static const _icons = [Icons.home_outlined, Icons.history, Icons.show_chart, Icons.view_list_outlined];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: const [HomeScreen(), HistoryScreen(), ProgressScreen(), TemplatesScreen()],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.chip))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == _tab,
                    button: true,
                    child: InkWell(
                      onTap: () => setState(() => _tab = i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_icons[i], size: 22, color: i == _tab ? AppColors.accentLight : AppColors.muted),
                          const SizedBox(height: 4),
                          Text(_tabs[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: i == _tab ? FontWeight.w600 : FontWeight.w400,
                                color: i == _tab ? AppColors.text : AppColors.muted,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
