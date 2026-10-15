import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'services/ads/ads_controller.dart';
import 'services/photo_library_service.dart';
import 'state/app_scope.dart';
import 'state/library_store.dart';
import 'state/settings_controller.dart';

class SiftApp extends StatefulWidget {
  const SiftApp({super.key, required this.service, this.ads});

  /// Where photos come from: the device library in the app, sample data in tests.
  final PhotoLibraryService service;

  /// Banner ads. Null turns them off (tests).
  final AdsController? ads;

  @override
  State<SiftApp> createState() => _SiftAppState();
}

class _SiftAppState extends State<SiftApp> {
  late final SettingsController _settings = SettingsController();
  late final LibraryStore _store = LibraryStore(widget.service);
  late final AdsController _ads = widget.ads ?? AdsController(enabled: false);

  @override
  void dispose() {
    _settings.dispose();
    _store.dispose();
    _ads.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      controller: _settings,
      child: LibraryScope(
        store: _store,
        child: AdsScope(
          controller: _ads,
          child: ListenableBuilder(
            listenable: _settings,
            builder: (context, _) => MaterialApp(
              title: 'Sift',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: _settings.themeMode,
              themeAnimationDuration: const Duration(milliseconds: 350),
              home: const SplashScreen(),
            ),
          ),
        ),
      ),
    );
  }
}
