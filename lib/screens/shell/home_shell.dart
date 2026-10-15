import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../state/app_scope.dart';
import '../../widgets/ad_banner_slot.dart';
import '../categories/categories_screen.dart';
import '../home/home_screen.dart';
import '../permission/photo_access_view.dart';
import '../settings/settings_screen.dart';
import '../statistics/statistics_screen.dart';

/// Bottom-navigation shell for the four primary destinations.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.startCleaning = false});

  /// Opens a swipe session right away (coming from onboarding).
  final bool startCleaning;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  int _index = 0;
  bool _adVisible = false;
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    // Consent (where required) and ads start once the user reaches the app.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AdsScope.of(context).start();
    });
    if (widget.startCleaning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) AppRouter.toCleaning(context);
        });
      });
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _index) return;
    AppHaptics.selection(context);
    setState(() => _index = i);
    _fade.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final store = LibraryScope.of(context);
    // Access was revoked (e.g. in system Settings): ask again before anything else.
    if (store.access != null && !store.hasAccess) return const PhotoAccessView();

    final tabs = [
      HomeScreen(onOpenTab: _select),
      const CategoriesScreen(),
      const StatisticsScreen(),
      const SettingsScreen(),
    ];

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: Scaffold(
        body: FadeTransition(
          opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.012),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: _fade, curve: Curves.easeOutCubic)),
            child: IndexedStack(index: _index, children: tabs),
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // When the banner shows, it sits below the bar and takes over the
            // system-navigation padding; otherwise the bar keeps it.
            MediaQuery.removePadding(
              context: context,
              removeBottom: _adVisible,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.border.withValues(alpha: 0.6))),
                ),
                child: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.grid_view_outlined),
                      selectedIcon: Icon(Icons.grid_view_rounded),
                      label: 'Library',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.insights_outlined),
                      selectedIcon: Icon(Icons.insights_rounded),
                      label: 'Insights',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
            AdBannerSlot(onVisibleChanged: (v) => setState(() => _adVisible = v)),
          ],
        ),
      ),
    );
  }
}
