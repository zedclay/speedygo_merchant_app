/// Local merchant notification preferences (device-only).
/// Distinct from OS notification permission and from server inbox.
library;

import 'package:shared_preferences/shared_preferences.dart';

class MerchantNotificationPreferences {
  const MerchantNotificationPreferences({
    this.foregroundAlertsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.nativePushEnabled = true,
  });

  /// In-app overlay/sound/vibration while the app is open (foreground only).
  final bool foregroundAlertsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;

  /// Native Push on this device (outside the app). Off → this install's
  /// DeviceToken is deactivated on the server. Lock-screen previews follow
  /// the OS notification settings.
  final bool nativePushEnabled;

  MerchantNotificationPreferences copyWith({
    bool? foregroundAlertsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? nativePushEnabled,
  }) {
    return MerchantNotificationPreferences(
      foregroundAlertsEnabled:
          foregroundAlertsEnabled ?? this.foregroundAlertsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      nativePushEnabled: nativePushEnabled ?? this.nativePushEnabled,
    );
  }

  static const _prefix = 'merchant_notif_pref_';

  static Future<MerchantNotificationPreferences> load() async {
    final p = await SharedPreferences.getInstance();
    return MerchantNotificationPreferences(
      foregroundAlertsEnabled: p.getBool('${_prefix}fg') ?? true,
      soundEnabled: p.getBool('${_prefix}sound') ?? true,
      vibrationEnabled: p.getBool('${_prefix}vib') ?? true,
      nativePushEnabled: p.getBool('${_prefix}native') ?? true,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('${_prefix}fg', foregroundAlertsEnabled);
    await p.setBool('${_prefix}sound', soundEnabled);
    await p.setBool('${_prefix}vib', vibrationEnabled);
    await p.setBool('${_prefix}native', nativePushEnabled);
  }
}
