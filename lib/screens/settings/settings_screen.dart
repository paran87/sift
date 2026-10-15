import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/haptics.dart';
import '../../models/photo_album.dart';
import '../../services/photo_library_service.dart';
import '../../state/app_scope.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/pressable.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final c = context.colors;
    final store = LibraryScope.of(context);

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xxl),
            children: [
              Text('Settings', style: context.text.headlineLarge),
              const SizedBox(height: AppSpacing.xl),
              const _GroupLabel('Appearance'),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: _ThemePicker(value: s.themeMode, onChanged: (v) => s.themeMode = v),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _GroupLabel('Interaction'),
              _Group(
                children: [
                  _SwitchTile(
                    icon: Icons.vibration_rounded,
                    color: c.accent,
                    title: 'Haptic feedback',
                    subtitle: 'Gentle taps when you swipe',
                    value: s.haptics,
                    onChanged: (v) => s.haptics = v,
                  ),
                  _SliderTile(
                    icon: Icons.swipe_rounded,
                    color: c.keep,
                    title: 'Swipe sensitivity',
                    value: s.sensitivity,
                    onChanged: (v) => s.sensitivity = v,
                  ),
                  _SwitchTile(
                    icon: Icons.animation_rounded,
                    color: c.warning,
                    title: 'Reduce motion',
                    subtitle: 'Shorter, simpler animations',
                    value: s.reduceMotion,
                    onChanged: (v) => s.reduceMotion = v,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const _GroupLabel('Cleaning'),
              _Group(
                children: [
                  _NavTile(
                    icon: Icons.photo_library_outlined,
                    color: c.keep,
                    title: 'Photo access',
                    trailing: switch (store.access) {
                      LibraryAccess.granted => 'All photos',
                      LibraryAccess.limited => 'Selected photos',
                      _ => 'Off',
                    },
                    onTap: () =>
                        store.access == LibraryAccess.limited ? store.manageLimitedAccess() : store.openSettings(),
                  ),
                  _SwitchTile(
                    icon: Icons.verified_user_outlined,
                    color: c.delete,
                    title: 'Confirm before deleting',
                    subtitle: 'Ask before emptying Trash',
                    value: s.confirmBeforeDelete,
                    onChanged: (v) => s.confirmBeforeDelete = v,
                  ),
                  _NavTile(
                    icon: Icons.undo_rounded,
                    color: c.accent,
                    title: 'Undo history',
                    trailing: '${s.undoSteps} steps',
                    onTap: () => _pickUndo(context, s),
                  ),
                  _NavTile(
                    icon: Icons.sort_rounded,
                    color: c.warning,
                    title: 'Photo order',
                    trailing: s.photoOrder.label,
                    onTap: () => _pickOrder(context, s),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const _GroupLabel('Other'),
              _Group(
                children: [
                  _NavTile(
                    icon: Icons.lock_outline_rounded,
                    color: c.keep,
                    title: 'Privacy',
                    onTap: () => _info(
                      context,
                      'Privacy',
                      'Sift works entirely on your device. Your photos are never uploaded, analysed in the cloud, or shared.',
                    ),
                  ),
                  _NavTile(
                    icon: Icons.help_outline_rounded,
                    color: c.accent,
                    title: 'Help',
                    onTap: () => AppRouter.toOnboarding(context),
                    trailing: 'Replay tour',
                  ),
                  _NavTile(
                    icon: Icons.star_outline_rounded,
                    color: c.warning,
                    title: 'Rate the app',
                    onTap: () => showAppSnack(context, 'Thanks! Rating opens in the store version.'),
                  ),
                  _NavTile(
                    icon: Icons.ios_share_rounded,
                    color: c.textSecondary,
                    title: 'Share the app',
                    onTap: () => showAppSnack(context, 'Sharing opens in the store version.'),
                  ),
                  _NavTile(
                    icon: Icons.info_outline_rounded,
                    color: c.textSecondary,
                    title: 'About',
                    trailing: 'v1.0.0',
                    onTap: () => _about(context),
                  ),
                ],
              ),
              // Only where the law requires it (e.g. EEA/UK): change ad consent.
              ValueListenableBuilder<bool>(
                valueListenable: AdsScope.of(context).privacyOptionsRequired,
                builder: (context, required, _) => !required
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: _Group(
                          children: [
                            _NavTile(
                              icon: Icons.privacy_tip_outlined,
                              color: c.accent,
                              title: 'Ad privacy choices',
                              onTap: AdsScope.of(context).showPrivacyOptions,
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    showAppSnack(context, 'Rescanning your library…');
                    await LibraryScope.read(context).reset();
                    if (context.mounted) showAppSnack(context, 'Library rescanned');
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Rescan library'),
                  style: TextButton.styleFrom(foregroundColor: c.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickOrder(BuildContext context, SettingsController s) {
    AppSheet.show<void>(
      context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Photo order', style: context.text.titleLarge),
          const SizedBox(height: 4),
          Text(
            'The order of albums and cleaning sessions, by the date each photo was taken.',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final order in PhotoOrder.values)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              leading: Icon(
                order == PhotoOrder.newestFirst ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              ),
              title: Text(order.label),
              trailing: s.photoOrder == order ? Icon(Icons.check_rounded, color: context.colors.accent) : null,
              onTap: () {
                s.photoOrder = order;
                Navigator.of(sheetContext).pop();
              },
            ),
        ],
      ),
    );
  }

  void _pickUndo(BuildContext context, SettingsController s) {
    AppSheet.show<void>(
      context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Undo history', style: context.text.titleLarge),
          const SizedBox(height: 4),
          Text('How many recent swipes you can take back.', style: context.text.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          for (final n in const [1, 5, 10, 25])
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              title: Text(n == 1 ? 'Last swipe only' : '$n swipes'),
              trailing: s.undoSteps == n ? Icon(Icons.check_rounded, color: context.colors.accent) : null,
              onTap: () {
                s.undoSteps = n;
                Navigator.of(sheetContext).pop();
              },
            ),
        ],
      ),
    );
  }

  void _info(BuildContext context, String title, String body) {
    AppSheet.show<void>(
      context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: context.text.bodyLarge),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  void _about(BuildContext context) {
    AppSheet.show<void>(
      context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogo(size: 72),
          const SizedBox(height: AppSpacing.md),
          Text('Sift', style: context.text.headlineMedium),
          Text('Version 1.0.0 · UI preview', style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Text(
            'A calmer way to clean up your photo library.',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xxs, bottom: AppSpacing.xs),
      child: Text(
        text.toUpperCase(),
        style: context.text.labelSmall?.copyWith(color: context.colors.textTertiary, letterSpacing: 1.2),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(indent: 64, color: context.colors.border.withValues(alpha: 0.6)),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const options = [
      (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
      (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
      (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
    ];
    return Row(
      children: [
        for (final (mode, icon, label) in options)
          Expanded(
            child: Pressable(
              onTap: () => onChanged(mode),
              semanticLabel: '$label theme${value == mode ? ', selected' : ''}',
              child: AnimatedContainer(
                duration: AppDurations.medium,
                curve: AppCurves.emphasized,
                margin: const EdgeInsets.all(2),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: value == mode ? c.accentSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: value == mode ? c.accent : c.textTertiary),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: context.text.labelMedium?.copyWith(color: value == mode ? c.textPrimary : c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        leading: IconTile(icon: icon, color: color, size: 36),
        title: Text(title, style: context.text.titleSmall),
        subtitle: subtitle == null ? null : Text(subtitle!, style: context.text.bodySmall),
        trailing: Switch(
          value: value,
          onChanged: (v) {
            AppHaptics.selection(context);
            onChanged(v);
          },
        ),
        onTap: () => onChanged(!value),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.icon, required this.color, required this.title, required this.onTap, this.trailing});

  final IconData icon;
  final Color color;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      leading: IconTile(icon: icon, color: color, size: 36),
      title: Text(title, style: context.text.titleSmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) Text(trailing!, style: context.text.bodySmall),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: c.textTertiary),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final String title;
  final SwipeSensitivity value;
  final ValueChanged<SwipeSensitivity> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Relaxed', 'Normal', 'Quick'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
      child: Column(
        children: [
          Row(
            children: [
              IconTile(icon: icon, color: color, size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: context.text.titleSmall)),
              Text(labels[value.index], style: context.text.labelMedium?.copyWith(color: context.colors.accent)),
            ],
          ),
          Slider(
            value: value.index.toDouble(),
            min: 0,
            max: 2,
            divisions: 2,
            label: labels[value.index],
            onChanged: (v) {
              final next = SwipeSensitivity.values[v.round()];
              if (next != value) {
                AppHaptics.selection(context);
                onChanged(next);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Longer swipe', style: context.text.bodySmall),
                Text('Shorter swipe', style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
