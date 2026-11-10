import 'package:flutter/material.dart';
import '../design/design.dart';
import '../widgets/common/main_tab_bar.dart';
import 'home_screen.dart';
import 'my_donations_screen.dart';
import 'settings_screen.dart';

/// Root of the signed-in/guest app: one Scaffold that owns the liquid-glass
/// tab bar and keeps Home, My Donations and Settings alive side by side, so
/// the bar's lens can travel between tabs and each tab keeps its state.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  /// Switches the nearest shell to [index]. Returns false when there is no
  /// shell above [context] (e.g. a screen pushed on its own), so callers can
  /// fall back to normal navigation.
  static bool selectTab(BuildContext context, int index) {
    final scope = context.getInheritedWidgetOfExactType<_ShellScope>();
    if (scope == null) return false;
    scope.select(index);
    return true;
  }

  /// Space the tab bar occupies at the bottom of a tab's content: the bar
  /// plus safe area inside the shell, just the safe area outside it.
  static double bottomReserve(BuildContext context) {
    final inside = context.getInheritedWidgetOfExactType<_ShellScope>() != null;
    final safe = MediaQuery.paddingOf(context).bottom;
    return inside ? AppTabBar.barHeight + safe : safe;
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _ShellScope extends InheritedWidget {
  const _ShellScope({required this.select, required super.child});

  final ValueChanged<int> select;

  @override
  bool updateShouldNotify(_ShellScope old) => false;
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;
  late final Set<int> _visited = {widget.initialIndex};

  /// Bumped on every visit to My Donations so the list reloads, as it did
  /// when the tab was a separate screen.
  int _donationsEpoch = 0;

  void _select(int index) {
    if (index < 0 || index > 2) return;
    setState(() {
      if (index == 1) _donationsEpoch++;
      _index = index;
      _visited.add(index);
    });
  }

  Widget _page(int i) {
    if (!_visited.contains(i)) return const SizedBox.shrink();
    return switch (i) {
      0 => const HomeScreen(),
      1 => MyDonationsScreen(key: ValueKey('donations-$_donationsEpoch')),
      _ => const SettingsScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return _ShellScope(
      select: _select,
      child: PopScope(
        // Back from Donations/Settings goes to Home before leaving the app.
        canPop: _index == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _select(0);
        },
        child: Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: _index,
            children: [for (var i = 0; i < 3; i++) _page(i)],
          ),
          bottomNavigationBar: MainTabBar(
            currentIndex: _index,
            onTap: _select,
          ),
        ),
      ),
    );
  }
}
