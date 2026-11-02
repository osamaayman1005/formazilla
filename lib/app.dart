import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'state/app_store.dart';
import 'ui/screens/history_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/progress_screen.dart';
import 'ui/screens/templates_screen.dart';
import 'ui/widgets/kaiju.dart';
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

/// Bottom bar. The active tab wears a small spike crest (the mascot's back).
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
        border: Border(top: BorderSide(color: AppColors.chip)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: Semantics(
                  selected: i == selected,
                  button: true,
                  child: InkWell(
                    onTap: () => onSelect(i),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      AnimatedScale(
                        duration: fast,
                        scale: i == selected ? 1 : 0,
                        curve: Motion.pop,
                        child: const SpikeCrest(),
                      ),
                      const SizedBox(height: 4),
                      Icon(icons[i], size: 22, color: i == selected ? AppColors.accentLight : AppColors.muted),
                      const SizedBox(height: 2),
                      Text(tabs[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: i == selected ? FontWeight.w600 : FontWeight.w400,
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
