import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../state/app_scope.dart';
import '../../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

  late final Animation<double> _logoIn = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.45, curve: Curves.easeOutBack),
  );
  late final Animation<double> _tilt = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.35, 0.75, curve: Curves.easeInOutCubic),
  );
  late final Animation<double> _textIn = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.4, 0.85, curve: AppCurves.emphasized),
  );

  @override
  void initState() {
    super.initState();
    // Warm up the library while the splash plays.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LibraryScope.read(context).refreshAccess();
    });
    _c.forward().then((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (mounted) AppRouter.toOnboarding(context);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(center: const Alignment(0, -0.2), radius: 1.1, colors: [c.accentSoft, c.background]),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 0.6 + 0.4 * _logoIn.value,
                  child: Opacity(
                    opacity: _logoIn.value.clamp(0.0, 1.0),
                    child: AppLogo(size: 96, tilt: _tilt.value),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Opacity(
                  opacity: _textIn.value,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - _textIn.value)),
                    child: Column(
                      children: [
                        Text('Sift', style: context.text.displayMedium),
                        const SizedBox(height: AppSpacing.xxs),
                        Text('Keep what matters', style: context.text.bodyLarge),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
