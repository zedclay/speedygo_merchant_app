import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_messaging_gateway.dart';
import 'package:speedygo_merchant_app/features/notifications/presentation/notification_settings_screen.dart';

class _StubPush extends MerchantPushController {
  _StubPush(this.initial);
  final MerchantPushState initial;

  @override
  MerchantPushState build() => initial;

  @override
  Future<void> syncRegistration({bool prompt = false}) async {}
}

const _permissions = MethodChannel('flutter.baseflow.com/permissions/methods');

// permission_handler PermissionStatus indices.
const _denied = 0;
const _granted = 1;
const _permanentlyDenied = 4;

Future<void> _pump(
  WidgetTester tester, {
  required MerchantPushState push,
  required int handlerStatus,
}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_permissions, (call) async {
    if (call.method == 'checkPermissionStatus') return handlerStatus;
    return null;
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        merchantPushControllerProvider.overrideWith(() => _StubPush(push)),
      ],
      child: const MaterialApp(home: NotificationSettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

String _banner(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('notif-os-banner-text'))).data!;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_permissions, null);
  });

  group('push unavailable (permission_handler status)', () {
    testWidgets('never asked is not reported as refused', (tester) async {
      await _pump(tester, push: const MerchantPushState(), handlerStatus: _denied);
      expect(_banner(tester), AppStrings.notifSettingsOsNotAsked);
      expect(find.text(AppStrings.notifSettingsPushUnavailable), findsOneWidget);
    });

    testWidgets('explicit refusal is reported as refused', (tester) async {
      await _pump(
        tester,
        push: const MerchantPushState(),
        handlerStatus: _permanentlyDenied,
      );
      expect(_banner(tester), AppStrings.notifSettingsOsDenied);
    });

    testWidgets('granted', (tester) async {
      await _pump(tester, push: const MerchantPushState(), handlerStatus: _granted);
      expect(_banner(tester), AppStrings.notifSettingsOsEnabled);
    });
  });

  group('push configured (provider authorization)', () {
    MerchantPushState state(PushAuthorization auth) => MerchantPushState(
          available: true,
          authorization: auth,
          registration: PushRegistrationStatus.idle,
        );

    testWidgets('notDetermined → not yet authorized', (tester) async {
      await _pump(
        tester,
        push: state(PushAuthorization.notDetermined),
        handlerStatus: _denied,
      );
      expect(_banner(tester), AppStrings.notifSettingsOsNotAsked);
      expect(find.text(AppStrings.notifSettingsPushUnavailable), findsNothing);
    });

    testWidgets('denied → refused with Push copy', (tester) async {
      await _pump(
        tester,
        push: state(PushAuthorization.denied),
        handlerStatus: _permanentlyDenied,
      );
      expect(_banner(tester), AppStrings.notifSettingsOsDeniedPush);
    });

    testWidgets('authorized → allowed with Push copy', (tester) async {
      await _pump(
        tester,
        push: state(PushAuthorization.authorized),
        handlerStatus: _granted,
      );
      expect(_banner(tester), AppStrings.notifSettingsOsEnabledPush);
    });
  });

  testWidgets(
    'short copy keeps foreground, OS permission and native push distinct',
    (tester) async {
      await _pump(tester, push: const MerchantPushState(), handlerStatus: _granted);
      expect(find.text(AppStrings.notifSettingsForeground), findsOneWidget);
      expect(find.text(AppStrings.notifSettingsSwitchesNote), findsOneWidget);
      expect(AppStrings.notifSettingsSwitchesNote, contains('ouverte'));
      expect(_banner(tester), contains('Permission iOS'));
      expect(_banner(tester), contains('Push natif'));
      expect(AppStrings.notifSettingsOsDenied, contains('Push natif'));
      expect(AppStrings.notifSettingsNativePushSub, contains('fermée'));
      expect(AppStrings.notifSettingsPushBlocked, contains('APNs/FCM'));
      expect(AppStrings.notifSettingsPushBlocked, contains('permission iOS'));
      for (final s in [
        AppStrings.notifSettingsSwitchesNote,
        AppStrings.notifSettingsNativePushSub,
        AppStrings.notifSettingsOsEnabled,
        AppStrings.notifSettingsOsDenied,
        AppStrings.notifSettingsPushBlocked,
        AppStrings.notifSettingsLockScreenNote,
      ]) {
        expect(s.length, lessThanOrEqualTo(90), reason: s);
      }
    },
  );
}
