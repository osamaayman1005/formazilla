import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'state/app_store.dart';
import 'ui/screens/history_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/progress_screen.dart';
import 'ui/screens/templates_screen.dart';
import 'ui/widgets/motion.dart';
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
      bottomNavigationBar: _BottomNav(
        tabs: _tabs,
        icons: _icons,
        selected: _tab,
        onSelect: (i) => setState(() => _tab = i),
      ),
    );
  }
}

/// Material 3 navigation bar: the active tab gets a navy pill behind its icon.
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.tabs, required this.icons, required this.selected, required this.onSelect});

  final List<String> tabs;
  final List<IconData> icons;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final fast = Motion.of(context, Motion.fast);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.card,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: Semantics(
                  selected: i == selected,
                  button: true,
                  child: InkWell(
                    onTap: () => onSelect(i),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      AnimatedContainer(
                        duration: fast,
                        curve: Curves.easeOutCubic,
                        width: 64,
                        height: 32,
                        decoration: BoxDecoration(
                          color: i == selected ? AppColors.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icons[i], size: 24, color: i == selected ? AppColors.onAccent : AppColors.muted),
                      ),
                      const SizedBox(height: 4),
                      Text(tabs[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: i == selected ? FontWeight.w700 : FontWeight.w500,
                            color: i == selected ? AppColors.text : AppColors.muted,
                          )),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
