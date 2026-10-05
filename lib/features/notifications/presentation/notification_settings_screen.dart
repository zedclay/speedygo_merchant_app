import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/application/order_alert_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/notification_preferences.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_messaging_gateway.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_registration.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  MerchantNotificationPreferences _prefs =
      const MerchantNotificationPreferences();
  PermissionStatus _os = PermissionStatus.denied;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await MerchantNotificationPreferences.load();
    final os = await MerchantPushRegistration().osPermissionStatus();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _os = os;
      _loading = false;
    });
  }

  Future<void> _requestOs() async {
    final status = await MerchantPushRegistration().requestOsPermission();
    if (!mounted) return;
    setState(() => _os = status);
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    await ref.read(merchantPushControllerProvider.notifier).syncRegistration();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _prefs.save();
    await ref.read(orderAlertControllerProvider.notifier).reloadPreferences();
    await ref.read(merchantPushControllerProvider.notifier).syncRegistration();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.notifSettingsSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final push = ref.watch(merchantPushControllerProvider);
    final pushConfigured = push.available;
    final caption = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    return MerchantScaffold(
      title: AppStrings.notifSettingsTitle,
      headerColor: AppColors.surface,
      headerHeight: 64,
      headerDivider: true,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      bodyPadding: EdgeInsets.zero,
      bottom: _loading
          ? null
          : MerchantStickyBar(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  key: const Key('notif-settings-save'),
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(_saving ? '…' : AppStrings.notifSettingsSave),
                ),
              ),
            ),
      body: _loading
          ? const LoadingBody()
          : ListView(
              key: const Key('notification-settings-screen'),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _OsBanner(
                  permission: pushConfigured
                      ? _fromPush(push.authorization)
                      : _fromHandler(_os),
                  pushConfigured: pushConfigured,
                  onOpenSettings: _requestOs,
                ),
                const _CriticalWarning(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionLabel(AppStrings.notifSettingsInAppSection),
                      _GroupCard(
                        children: [
                          _ToggleRow(
                            key: const Key('notif-pref-foreground'),
                            title: AppStrings.notifSettingsForeground,
                            subtitle: AppStrings.notifSettingsSwitchesNote,
                            value: _prefs.foregroundAlertsEnabled,
                            onChanged: (v) => setState(
                              () => _prefs = _prefs.copyWith(
                                foregroundAlertsEnabled: v,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel(AppStrings.notifSettingsSoundSection),
                      _GroupCard(
                        children: [
                          _ToggleRow(
                            key: const Key('notif-pref-sound'),
                            title: AppStrings.notifSettingsSound,
                            value: _prefs.soundEnabled,
                            onChanged: (v) => setState(
                              () => _prefs = _prefs.copyWith(soundEnabled: v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel(
                        AppStrings.notifSettingsVibrationSection,
                      ),
                      _GroupCard(
                        children: [
                          _ToggleRow(
                            key: const Key('notif-pref-vibration'),
                            title: AppStrings.notifSettingsVibration,
                            value: _prefs.vibrationEnabled,
                            onChanged: (v) => setState(
                              () =>
                                  _prefs = _prefs.copyWith(vibrationEnabled: v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel(AppStrings.notifSettingsPushSection),
                      if (!pushConfigured)
                        _GroupCard(
                          key: const Key('notif-push-unavailable'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          AppStrings.notifSettingsNativePush,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusBadge(
                                        label: AppStrings
                                            .notifSettingsPushNotConfigured,
                                        tone: StatusTone.neutral,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppStrings.notifSettingsPushBlocked,
                                    style: caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        _GroupCard(
                          children: [
                            _ToggleRow(
                              key: const Key('notif-pref-native-push'),
                              title: AppStrings.notifSettingsNativePush,
                              subtitle: AppStrings.notifSettingsNativePushSub,
                              value: _prefs.nativePushEnabled,
                              onChanged: (v) => setState(
                                () => _prefs = _prefs.copyWith(
                                  nativePushEnabled: v,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _statusText(push.registration),
                                    key: const Key('notif-push-status'),
                                    style: caption?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppStrings.notifSettingsLockScreenNote,
                                    style: caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  static String _statusText(PushRegistrationStatus s) => switch (s) {
    PushRegistrationStatus.registered => AppStrings.notifPushStatusRegistered,
    PushRegistrationStatus.permissionDenied => AppStrings.notifPushStatusDenied,
    PushRegistrationStatus.disabledByUser => AppStrings.notifPushStatusDisabled,
    PushRegistrationStatus.tokenUnavailable =>
      AppStrings.notifPushStatusTokenUnavailable,
    PushRegistrationStatus.failed => AppStrings.notifPushStatusFailed,
    PushRegistrationStatus.idle ||
    PushRegistrationStatus.unavailable => AppStrings.notifPushStatusPending,
  };
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Reference group: white, 8 px radius, outline-variant border and dividers.
class _GroupCard extends StatelessWidget {
  const _GroupCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppColors.outlineVariant),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
      value: value,
      activeThumbColor: AppColors.onPrimary,
      activeTrackColor: AppColors.primaryContainer,
      thumbIcon: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Icon(Icons.check, color: AppColors.primaryContainer)
            : null,
      ),
      onChanged: onChanged,
    );
  }
}

class _CriticalWarning extends StatelessWidget {
  const _CriticalWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('notif-critical-warning'),
      color: AppColors.errorContainer.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.warning_amber_outlined,
              size: 18,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.notifSettingsCriticalWarning,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

enum _OsPermission { allowed, denied, notAsked }

_OsPermission _fromPush(PushAuthorization auth) => switch (auth) {
  PushAuthorization.authorized ||
  PushAuthorization.provisional => _OsPermission.allowed,
  PushAuthorization.denied => _OsPermission.denied,
  PushAuthorization.notDetermined => _OsPermission.notAsked,
};

/// iOS reports `denied` before the first prompt and `permanentlyDenied`
/// after an explicit refusal.
_OsPermission _fromHandler(PermissionStatus status) {
  if (status.isGranted || status.isLimited || status.isProvisional) {
    return _OsPermission.allowed;
  }
  if (status.isPermanentlyDenied || status.isRestricted) {
    return _OsPermission.denied;
  }
  return _OsPermission.notAsked;
}

class _OsBanner extends StatelessWidget {
  const _OsBanner({
    required this.permission,
    required this.pushConfigured,
    required this.onOpenSettings,
  });
  final _OsPermission permission;
  final bool pushConfigured;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final allowed = permission == _OsPermission.allowed;
    final String message = switch (permission) {
      _OsPermission.allowed =>
        pushConfigured
            ? AppStrings.notifSettingsOsEnabledPush
            : AppStrings.notifSettingsOsEnabled,
      _OsPermission.denied =>
        pushConfigured
            ? AppStrings.notifSettingsOsDeniedPush
            : AppStrings.notifSettingsOsDenied,
      _OsPermission.notAsked => AppStrings.notifSettingsOsNotAsked,
    };
    final theme = Theme.of(context);
    return Container(
      key: const Key('notif-os-banner'),
      color: AppColors.surfaceVariant,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              allowed ? Icons.info_outline : Icons.warning_amber_outlined,
              color: allowed ? AppColors.primary : AppColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  key: const Key('notif-os-banner-text'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                if (!pushConfigured) ...[
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.notifSettingsPushUnavailable,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                InkWell(
                  key: const Key('notif-os-open-settings'),
                  onTap: onOpenSettings,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      AppStrings.notifSettingsOsOpen,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
