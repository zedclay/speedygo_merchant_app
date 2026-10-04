import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/shell/profile_settings_screen.dart';
import 'package:speedygo_merchant_app/features/team/data/team_models.dart';
import 'package:speedygo_merchant_app/features/team/presentation/my_invitations_screen.dart';
import 'package:speedygo_merchant_app/features/team/presentation/team_screen.dart';

import '../audit/parity/parity_harness.dart';
import 'phase1_flow_test.dart';

class _StubPush extends MerchantPushController {
  @override
  MerchantPushState build() => const MerchantPushState();

  @override
  Future<void> syncRegistration({bool prompt = false}) async {}
}

const _owner = TeamMember(
  id: 'm-owner',
  phone: '+213550000001',
  role: 'OWNER',
  isSelf: true,
  version: 1,
);
const _manager = TeamMember(
  id: 'm-mgr',
  phone: '+213661123456',
  role: 'MANAGER',
  isSelf: false,
  version: 3,
);
const _staff = TeamMember(
  id: 'm-staff',
  phone: '+213770987654',
  role: 'STAFF',
  isSelf: false,
  version: 2,
);

TeamInvitation _invite({
  String id = 'inv-1',
  String phone = '+213551234567',
  String role = 'STAFF',
  String status = 'PENDING',
  int version = 2,
}) => TeamInvitation(
  id: id,
  phone: phone,
  role: role,
  status: status,
  version: version,
  expiresAt: DateTime.utc(2026, 10, 11, 12),
);

MerchantTeam _team({
  bool canManage = true,
  List<TeamMember>? members,
  List<TeamInvitation>? invitations,
}) => MerchantTeam(
  merchantId: 'm-1',
  members: members ?? const [_owner, _manager, _staff],
  invitations: invitations ?? [_invite()],
  canManage: canManage,
);

FakeMerchantApi _api({
  String role = 'OWNER',
  MerchantTeam? team,
  List<MyTeamInvitation> mine = const [],
}) {
  final base = membership(
    role: role,
    branches: [branch('b1', name: 'Dar El Benna')],
  ).parityWith(name: 'Dar El Benna');
  return FakeMerchantApi(
      meHandler: () async =>
          MerchantMe(merchantMembershipExists: true, memberships: [base]),
    )
    ..team = team ?? _team(canManage: role == 'OWNER')
    ..myTeamInvitations = mine;
}

Future<ProviderContainer> _container(FakeMerchantApi api) => parityReady(
  api,
  overrides: [merchantPushControllerProvider.overrideWith(_StubPush.new)],
);

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester,
  FakeMerchantApi api, {
  Widget child = const TeamScreen(),
  ParityVariant? variant,
  double height = 844,
  double bottomInset = 0,
}) async {
  final container = await _container(api);
  addTearDown(container.dispose);
  await parityPump(
    tester,
    container: container,
    variant: variant ?? parityVariants.first,
    height: height,
    child: child,
    pushed: true,
    bottomInset: bottomInset,
  );
  return container;
}

Future<void> _tap(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

bool _exceeds(WidgetTester tester, Finder finder) =>
    tester.renderObject<RenderParagraph>(finder).didExceedMaxLines;

Finder _labelIn(Key key, String label) =>
    find.descendant(of: find.byKey(key), matching: find.text(label));

final _geometry = parityVariants.last;

/// Lazy lists estimate their extent: keep jumping until the end is reached.
Future<void> _scrollToEnd(WidgetTester tester, ScrollPosition position) async {
  for (var i = 0; i < 6; i++) {
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
    if (position.pixels >= position.maxScrollExtent) return;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('models', () {
    test('parses roster, invitations and capabilities', () {
      final team = MerchantTeam.fromJson({
        'merchantId': 'm-1',
        'members': [
          {
            'id': 'a',
            'phone': '+213550000001',
            'role': 'OWNER',
            'branchScope': 'ALL_MERCHANT_BRANCHES',
            'isSelf': true,
            'version': 1,
            'createdAt': '2026-10-01T10:00:00.000Z',
          },
          {'id': 'b', 'phone': null, 'role': 'STAFF', 'version': 4},
        ],
        'invitations': [
          {
            'id': 'i',
            'phone': '+213551234567',
            'role': 'MANAGER',
            'status': 'PENDING',
            'expiresAt': '2026-10-11T12:00:00.000Z',
            'version': 2,
          },
          {
            'id': 'j',
            'phone': '+213551234568',
            'role': 'STAFF',
            'status': 'CANCELLED',
          },
        ],
        'capabilities': {'canManage': true},
      });
      expect(team.canManage, isTrue);
      expect(team.members.first.isSelf, isTrue);
      expect(team.members.first.isOwner, isTrue);
      expect(team.members.last.phone, isNull);
      expect(team.members.last.isMutable, isTrue);
      expect(team.outstandingInvitations.map((i) => i.id), ['i']);
    });

    test('normalizes Algerian mobile numbers to E.164', () {
      expect(normalizeTeamPhone('0551234567'), '+213551234567');
      expect(normalizeTeamPhone('551 23 45 67'), '+213551234567');
      expect(normalizeTeamPhone('+213 551 23 45 67'), '+213551234567');
      expect(normalizeTeamPhone('00213551234567'), '+213551234567');
      expect(normalizeTeamPhone(''), isNull);
      expect(normalizeTeamPhone('55123'), isNull);
      expect(normalizeTeamPhone('0251234567'), isNull);
      expect(normalizeTeamPhone('+33612345678'), isNull);
    });

    test('formats phones for display', () {
      expect(formatTeamPhone('+213661123456'), '+213 661 12 34 56');
      expect(formatTeamPhone('+33612345678'), '+33612345678');
      expect(formatTeamPhone(null), '');
    });
  });

  group('roster as OWNER', () {
    testWidgets('truthful hierarchy: phones, roles, owner badge, no presence', (
      tester,
    ) async {
      await _pumpScreen(tester, _api());

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Personnel et Accès'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('team-store-card')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('team-store-name'))).data,
        'Dar El Benna',
      );
      expect(find.text('Gestion de l’équipe'), findsOneWidget);
      expect(find.text('Membres actifs'), findsOneWidget);

      Text text(String key) => tester.widget<Text>(find.byKey(Key(key)));
      expect(text('team-member-phone-m-owner').data, '+213 550 00 00 01');
      expect(text('team-member-phone-m-mgr').data, '+213 661 12 34 56');
      expect(text('team-member-role-label-m-owner').data, 'Propriétaire');
      expect(text('team-member-role-label-m-mgr').data, 'Gestionnaire');
      expect(text('team-member-role-label-m-staff').data, 'Équipe');

      expect(find.byKey(const Key('team-owner-badge-m-owner')), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.byKey(const Key('team-member-self-m-owner')), findsOneWidget);
      expect(find.byKey(const Key('team-member-revoke-m-owner')), findsNothing);
      expect(find.byKey(const Key('team-member-role-m-owner')), findsNothing);
      expect(find.byKey(const Key('team-member-revoke-m-mgr')), findsOneWidget);
      expect(
        find.byKey(const Key('team-member-revoke-m-staff')),
        findsOneWidget,
      );

      for (final fabricated in const [
        'Actif maintenant',
        'Dernière activité',
        'Opérateur',
        'catalogue',
        'Renvoyer',
        'Envoyée',
      ]) {
        expect(
          find.textContaining(fabricated),
          findsNothing,
          reason: fabricated,
        );
      }
    });

    testWidgets('pending invitations: phone, role, regenerate, cancel', (
      tester,
    ) async {
      await _pumpScreen(tester, _api());
      await tester.ensureVisible(find.byKey(const Key('team-invites-title')));
      await tester.pump();

      expect(find.text('Invitations en attente'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('team-invite-phone-inv-1')))
            .data,
        '+213 551 23 45 67',
      );
      expect(find.text('Rôle : Équipe'), findsOneWidget);
      expect(find.text('Expire le 11/10/2026'), findsOneWidget);
      expect(
        _labelIn(
          const Key('team-invite-regenerate-inv-1'),
          'Régénérer le code',
        ),
        findsOneWidget,
      );
      expect(
        _labelIn(const Key('team-invite-cancel-inv-1'), 'Annuler'),
        findsOneWidget,
      );
    });

    testWidgets('roles summary is the truthful OWNER/MANAGER/STAFF matrix', (
      tester,
    ) async {
      await _pumpScreen(tester, _api());
      await tester.ensureVisible(find.byKey(const Key('team-roles-summary')));
      await tester.pump();

      expect(find.text('Résumé des rôles'), findsOneWidget);
      for (final role in const ['OWNER', 'MANAGER', 'STAFF', 'SCOPE']) {
        expect(find.byKey(Key('team-role-summary-$role')), findsOneWidget);
      }
      expect(find.textContaining('Ne peut ni inviter'), findsOneWidget);
      expect(find.textContaining('par établissement'), findsOneWidget);
    });

    testWidgets('FAB invite is present', (tester) async {
      await _pumpScreen(tester, _api());
      expect(find.byKey(const Key('team-invite-fab')), findsOneWidget);
      expect(
        _labelIn(const Key('team-invite-fab'), 'Inviter un membre'),
        findsOneWidget,
      );
    });

    testWidgets('revoke needs confirmation then refreshes the roster', (
      tester,
    ) async {
      final api = _api();
      await _pumpScreen(tester, api);

      await _tap(tester, const Key('team-member-revoke-m-staff'));
      expect(find.byKey(const Key('team-revoke-dialog')), findsOneWidget);
      expect(api.teamCalls, isEmpty);

      await _tap(tester, const Key('team-revoke-keep'));
      expect(api.teamCalls, isEmpty);
      expect(find.byKey(const Key('team-member-m-staff')), findsOneWidget);

      await _tap(tester, const Key('team-member-revoke-m-staff'));
      await _tap(tester, const Key('team-revoke-confirm'));
      expect(api.teamCalls, ['revoke:m-staff:2']);
      expect(find.byKey(const Key('team-member-m-staff')), findsNothing);
      expect(find.text(AppStrings.teamRevoked), findsOneWidget);
    });

    testWidgets('role change sends the member version', (tester) async {
      final api = _api();
      await _pumpScreen(tester, api);

      await _tap(tester, const Key('team-member-role-m-mgr'));
      expect(find.byKey(const Key('team-role-sheet')), findsOneWidget);
      await _tap(tester, const Key('team-role-option-STAFF'));
      await _tap(tester, const Key('team-role-save'));

      expect(api.teamCalls, ['role:m-mgr:STAFF:3']);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('team-member-role-label-m-mgr')))
            .data,
        'Équipe',
      );
    });

    testWidgets('cancel invitation confirms and removes it', (tester) async {
      final api = _api();
      await _pumpScreen(tester, api);

      await _tap(tester, const Key('team-invite-cancel-inv-1'));
      expect(
        find.byKey(const Key('team-cancel-invite-dialog')),
        findsOneWidget,
      );
      await _tap(tester, const Key('team-cancel-invite-confirm'));

      expect(api.teamCalls, ['cancel:inv-1:2']);
      expect(find.byKey(const Key('team-invite-inv-1')), findsNothing);
      expect(find.byKey(const Key('team-invites-empty')), findsOneWidget);
    });

    testWidgets('regenerate shows the new code and never claims delivery', (
      tester,
    ) async {
      final api = _api()..teamAcceptCode = 'b' * 64;
      await _pumpScreen(tester, api);

      await _tap(tester, const Key('team-invite-regenerate-inv-1'));

      expect(api.teamCalls, ['regenerate:inv-1:2']);
      expect(find.byKey(const Key('team-accept-code-sheet')), findsOneWidget);
      expect(find.text('b' * 64), findsOneWidget);
      expect(find.text(AppStrings.teamCodeRegeneratedTitle), findsOneWidget);
      expect(find.textContaining('envoy'), findsNothing);
    });

    testWidgets('version conflict refreshes the roster and explains', (
      tester,
    ) async {
      final api = _api()
        ..teamMutationError = const ApiException(
          'conflict',
          code: 'TEAM_VERSION_CONFLICT',
          statusCode: 409,
        );
      await _pumpScreen(tester, api);
      final fetchesBefore = api.teamFetches;

      await _tap(tester, const Key('team-member-revoke-m-mgr'));
      await _tap(tester, const Key('team-revoke-confirm'));

      expect(api.teamFetches, greaterThan(fetchesBefore));
      expect(find.text(AppStrings.teamErrorConflict), findsOneWidget);
      expect(find.byKey(const Key('team-member-m-mgr')), findsOneWidget);
    });
  });

  group('invite flow', () {
    Future<void> openSheet(WidgetTester tester) async {
      await _tap(tester, const Key('team-invite-fab'));
      expect(find.byKey(const Key('team-invite-sheet')), findsOneWidget);
    }

    testWidgets('validates the phone before calling the API', (tester) async {
      final api = _api();
      await _pumpScreen(tester, api);
      await openSheet(tester);

      expect(find.text(AppStrings.teamInvitePhoneInvalid), findsNothing);
      await _tap(tester, const Key('team-invite-submit'));
      expect(find.text(AppStrings.teamInvitePhoneInvalid), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('team-invite-phone')),
        '55123',
      );
      await _tap(tester, const Key('team-invite-submit'));
      expect(find.text(AppStrings.teamInvitePhoneInvalid), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('team-invite-phone')),
        '0251234567',
      );
      await _tap(tester, const Key('team-invite-submit'));
      expect(find.text(AppStrings.teamInvitePhoneInvalid), findsOneWidget);
      expect(api.teamCalls, isEmpty);
    });

    testWidgets('only MANAGER and STAFF are offered; STAFF by default', (
      tester,
    ) async {
      await _pumpScreen(tester, _api());
      await openSheet(tester);

      expect(find.byKey(const Key('team-invite-role-MANAGER')), findsOneWidget);
      expect(find.byKey(const Key('team-invite-role-STAFF')), findsOneWidget);
      expect(find.byKey(const Key('team-invite-role-OWNER')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('team-invite-role-STAFF')),
          matching: find.byIcon(Icons.radio_button_checked),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'success shows the accept code with a manual-share instruction',
      (tester) async {
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String?;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        final api = _api(team: _team(invitations: const []));
        await _pumpScreen(tester, api);
        await openSheet(tester);

        await tester.enterText(
          find.byKey(const Key('team-invite-phone')),
          '0551 23 45 67',
        );
        await _tap(tester, const Key('team-invite-role-MANAGER'));
        await _tap(tester, const Key('team-invite-submit'));

        expect(api.teamCalls, ['invite:+213551234567:MANAGER']);
        expect(find.byKey(const Key('team-accept-code-sheet')), findsOneWidget);
        expect(find.text('a' * 64), findsOneWidget);
        final instruction = tester
            .widget<Text>(find.byKey(const Key('team-accept-code-instruction')))
            .data!;
        expect(instruction, contains('transmettez-le vous-même'));
        expect(instruction, contains('+213 551 23 45 67'));
        expect(find.textContaining('envoy'), findsNothing);
        expect(find.textContaining('Invitation envoyée'), findsNothing);

        await _tap(tester, const Key('team-accept-code-copy'));
        expect(copied, 'a' * 64);
        expect(find.text(AppStrings.teamCodeCopied), findsOneWidget);

        await _tap(tester, const Key('team-accept-code-done'));
        expect(find.byKey(const Key('team-accept-code-sheet')), findsNothing);
        expect(find.byKey(const Key('team-invite-inv-1')), findsOneWidget);
        expect(find.text('a' * 64), findsNothing);
      },
    );

    testWidgets('conflict keeps the draft in the sheet', (tester) async {
      final api = _api()
        ..teamMutationError = const ApiException(
          'dup',
          code: 'TEAM_DUPLICATE_INVITE',
          statusCode: 409,
        );
      await _pumpScreen(tester, api);
      await openSheet(tester);

      await tester.enterText(
        find.byKey(const Key('team-invite-phone')),
        '0551234567',
      );
      await _tap(tester, const Key('team-invite-role-MANAGER'));
      final fetchesBefore = api.teamFetches;
      await _tap(tester, const Key('team-invite-submit'));

      expect(find.byKey(const Key('team-invite-sheet')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('team-invite-error'))).data,
        AppStrings.teamErrorDuplicateInvite,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('team-invite-phone')))
            .controller!
            .text,
        '0551234567',
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('team-invite-role-MANAGER')),
          matching: find.byIcon(Icons.radio_button_checked),
        ),
        findsOneWidget,
      );
      expect(api.teamFetches, greaterThan(fetchesBefore));
      expect(find.byKey(const Key('team-accept-code-sheet')), findsNothing);
    });
  });

  group('roster as MANAGER', () {
    testWidgets('read-only: no FAB, no revoke, no invitation actions', (
      tester,
    ) async {
      final api = _api(role: 'MANAGER');
      await _pumpScreen(tester, api);

      expect(api.teamFetches, 1);
      expect(find.byKey(const Key('team-member-m-mgr')), findsOneWidget);
      expect(find.byKey(const Key('team-member-m-staff')), findsOneWidget);
      expect(find.byKey(const Key('team-invite-fab')), findsNothing);
      expect(find.text('Révoquer'), findsNothing);
      expect(find.text('Modifier le rôle'), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('team-invite-inv-1')));
      await tester.pump();
      expect(find.byKey(const Key('team-invite-inv-1')), findsOneWidget);
      expect(find.text('Régénérer le code'), findsNothing);
      expect(find.byKey(const Key('team-invite-cancel-inv-1')), findsNothing);
    });
  });

  group('roster as STAFF', () {
    testWidgets('forbidden state without calling the API', (tester) async {
      final api = _api(role: 'STAFF');
      await _pumpScreen(tester, api);

      expect(find.byKey(const Key('team-forbidden')), findsOneWidget);
      expect(find.text(AppStrings.teamForbiddenBody), findsOneWidget);
      expect(find.byKey(const Key('team-invite-fab')), findsNothing);
      expect(find.byKey(const Key('team-screen')), findsNothing);
      expect(api.teamFetches, 0);
    });

    testWidgets('a server 403 also lands on the forbidden state', (
      tester,
    ) async {
      final api = _api(role: 'MANAGER')
        ..teamHandler = () async => throw const ApiException(
          'forbidden',
          code: 'MERCHANT_ROLE_FORBIDDEN',
          statusCode: 403,
        );
      await _pumpScreen(tester, api);

      expect(find.byKey(const Key('team-forbidden')), findsOneWidget);
      expect(find.byKey(const Key('team-retry')), findsNothing);
    });
  });

  group('states', () {
    testWidgets('loading', (tester) async {
      final gate = Completer<MerchantTeam>();
      final api = _api()..teamHandler = () => gate.future;
      await _pumpScreen(tester, api);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('team-screen')), findsNothing);
      expect(find.byKey(const Key('team-invite-fab')), findsNothing);

      gate.complete(_team());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('team-screen')), findsOneWidget);
    });

    testWidgets('empty roster and no invitations', (tester) async {
      await _pumpScreen(
        tester,
        _api(
          team: _team(members: const [], invitations: const []),
        ),
      );

      expect(find.byKey(const Key('team-members-empty')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('team-invites-empty')));
      await tester.pump();
      expect(find.byKey(const Key('team-invites-empty')), findsOneWidget);
      expect(find.byKey(const Key('team-invite-fab')), findsOneWidget);
    });

    testWidgets('error then retry', (tester) async {
      var calls = 0;
      final api = _api()
        ..teamHandler = () async {
          calls += 1;
          if (calls == 1) {
            throw const ApiException('boom', code: 'INTERNAL', statusCode: 500);
          }
          return _team();
        };
      await _pumpScreen(tester, api);

      expect(find.byKey(const Key('team-error')), findsOneWidget);
      expect(find.byKey(const Key('team-invite-fab')), findsNothing);
      await _tap(tester, const Key('team-retry'));
      expect(find.byKey(const Key('team-screen')), findsOneWidget);
      expect(calls, 2);
    });

    testWidgets('a very long phone wraps without overflow', (tester) async {
      const longPhone = '+4412345678901234567890123456789';
      final api = _api(
        team: _team(
          members: const [
            _owner,
            TeamMember(
              id: 'm-long',
              phone: longPhone,
              role: 'MANAGER',
              isSelf: false,
              version: 1,
            ),
          ],
          invitations: [_invite(phone: longPhone)],
        ),
      );
      await _pumpScreen(tester, api, variant: _geometry);

      expect(tester.takeException(), isNull);
      final phone = find.byKey(const Key('team-member-phone-m-long'));
      expect(phone, findsOneWidget);
      final card = tester.getRect(find.byKey(const Key('team-member-m-long')));
      expect(tester.getRect(phone).right, lessThanOrEqualTo(card.right));
      expect(_exceeds(tester, phone), isFalse);
    });
  });

  group('settings entry', () {
    Future<void> pumpSettings(WidgetTester tester, String role) async {
      final container = await _container(_api(role: role));
      addTearDown(container.dispose);
      await parityPumpFull(
        tester,
        container: container,
        variant: parityVariants.first,
        child: const ProfileSettingsScreen(),
        pushed: true,
      );
    }

    testWidgets('OWNER and MANAGER see Gestion de l’équipe', (tester) async {
      for (final role in const ['OWNER', 'MANAGER']) {
        await pumpSettings(tester, role);
        expect(
          find.byKey(const Key('settings-team')),
          findsOneWidget,
          reason: role,
        );
        expect(
          _labelIn(const Key('settings-team'), 'Gestion de l’équipe'),
          findsOneWidget,
        );
      }
    });

    testWidgets('STAFF does not see Gestion de l’équipe', (tester) async {
      await pumpSettings(tester, 'STAFF');
      expect(find.byKey(const Key('settings-team')), findsNothing);
      expect(
        find.byKey(const Key('settings-team-invitations')),
        findsOneWidget,
      );
    });

    testWidgets('rows navigate to the team routes', (tester) async {
      final container = await _container(_api());
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        initialLocation: AppRoutes.settings,
        routes: [
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, _) => const ProfileSettingsScreen(),
          ),
          GoRoute(path: AppRoutes.team, builder: (_, _) => const TeamScreen()),
          GoRoute(
            path: AppRoutes.teamInvitations,
            builder: (_, _) => const MyInvitationsScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(AppRoutes.team, '/app/profile/team');
      expect(AppRoutes.teamInvitations, '/app/profile/team-invitations');
      await _tap(tester, const Key('settings-team'));
      expect(find.byKey(const Key('team-screen')), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await _tap(tester, const Key('settings-team-invitations'));
      expect(find.byKey(const Key('my-invitations-empty')), findsOneWidget);
    });
  });

  group('received invitations', () {
    final mine = [
      MyTeamInvitation(
        id: 'mi-1',
        merchantId: 'm-9',
        merchantName: 'Boulangerie Ziryab',
        role: 'MANAGER',
        expiresAt: DateTime.utc(2026, 10, 11, 12),
      ),
    ];

    testWidgets('empty state', (tester) async {
      await _pumpScreen(tester, _api(), child: const MyInvitationsScreen());
      expect(find.byKey(const Key('my-invitations-empty')), findsOneWidget);
    });

    testWidgets('lists the merchant and role, never a fabricated name', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        _api(mine: mine),
        child: const MyInvitationsScreen(),
      );
      expect(find.text('Boulangerie Ziryab'), findsOneWidget);
      expect(find.text('Rôle : Gestionnaire'), findsOneWidget);
      expect(find.text('Expire le 11/10/2026'), findsOneWidget);
    });

    testWidgets('accept validates the code then calls the API', (tester) async {
      final api = _api(mine: mine);
      await _pumpScreen(tester, api, child: const MyInvitationsScreen());

      await _tap(tester, const Key('my-invitation-accept-mi-1'));
      await _tap(tester, const Key('my-invitation-code-submit'));
      expect(find.text(AppStrings.teamAcceptCodeInvalid), findsOneWidget);
      expect(api.teamCalls, isEmpty);

      await tester.enterText(
        find.byKey(const Key('my-invitation-code')),
        'xyz',
      );
      await _tap(tester, const Key('my-invitation-code-submit'));
      expect(api.teamCalls, isEmpty);

      await tester.enterText(
        find.byKey(const Key('my-invitation-code')),
        'ab12' * 16,
      );
      await _tap(tester, const Key('my-invitation-code-submit'));

      expect(api.teamCalls, ['accept:mi-1:${'ab12' * 16}']);
      expect(find.byKey(const Key('my-invitation-mi-1')), findsNothing);
      expect(find.byKey(const Key('my-invitations-empty')), findsOneWidget);
      expect(
        find.text(AppStrings.teamAccepted('Boulangerie Ziryab')),
        findsOneWidget,
      );
    });

    testWidgets('a wrong code keeps the typed value', (tester) async {
      final api = _api(mine: mine)
        ..teamMutationError = const ApiException(
          'bad',
          code: 'TEAM_INVITE_CODE_INVALID',
          statusCode: 400,
        );
      await _pumpScreen(tester, api, child: const MyInvitationsScreen());

      await _tap(tester, const Key('my-invitation-accept-mi-1'));
      await tester.enterText(
        find.byKey(const Key('my-invitation-code')),
        'cd34' * 16,
      );
      await _tap(tester, const Key('my-invitation-code-submit'));

      expect(
        tester.widget<Text>(find.byKey(const Key('my-invitation-error'))).data,
        AppStrings.teamErrorCodeInvalid,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('my-invitation-code')))
            .controller!
            .text,
        'cd34' * 16,
      );
      expect(find.byKey(const Key('my-invitation-mi-1')), findsOneWidget);
    });
  });

  group('geometry at 1.35', () {
    testWidgets('title readable, FAB and CTA labels complete', (tester) async {
      await _pumpScreen(
        tester,
        _api(),
        variant: _geometry,
        height: 640,
        bottomInset: 34,
      );
      expect(_geometry.textScale, 1.35);

      final title = find.descendant(
        of: find.byType(AppBar),
        matching: find.text(AppStrings.teamTitle),
      );
      expect(_exceeds(tester, title), isFalse);
      expect(tester.getRect(title).width, greaterThan(150));

      final fab = find.byKey(const Key('team-invite-fab'));
      final fabRect = tester.getRect(fab);
      expect(fabRect.left, greaterThanOrEqualTo(0));
      expect(fabRect.right, lessThanOrEqualTo(_geometry.width));
      expect(fabRect.bottom, lessThanOrEqualTo(640 - 34));
      expect(
        _exceeds(
          tester,
          find.descendant(
            of: fab,
            matching: find.text(AppStrings.teamInviteMember),
          ),
        ),
        isFalse,
      );

      for (final entry in {
        const Key('team-member-role-m-mgr'): AppStrings.teamChangeRole,
        const Key('team-member-revoke-m-mgr'): AppStrings.teamRevoke,
      }.entries) {
        final label = _labelIn(entry.key, entry.value);
        await tester.ensureVisible(find.byKey(entry.key));
        await tester.pump();
        expect(label, findsOneWidget);
        expect(_exceeds(tester, label), isFalse, reason: entry.value);
        expect(
          tester.getRect(find.byKey(entry.key)).right,
          lessThanOrEqualTo(_geometry.width),
        );
      }

      for (final entry in {
        const Key('team-invite-regenerate-inv-1'):
            AppStrings.teamRegenerateCode,
        const Key('team-invite-cancel-inv-1'): AppStrings.teamCancelInvitation,
      }.entries) {
        await tester.ensureVisible(find.byKey(entry.key));
        await tester.pump();
        final label = _labelIn(entry.key, entry.value);
        expect(label, findsOneWidget);
        expect(_exceeds(tester, label), isFalse, reason: entry.value);
        final rect = tester.getRect(find.byKey(entry.key));
        expect(rect.right, lessThanOrEqualTo(_geometry.width));
        expect(rect.height, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('last content stays above the FAB and safe area', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        _api(),
        variant: _geometry,
        height: 640,
        bottomInset: 34,
      );

      final scrollable = find.descendant(
        of: find.byKey(const Key('team-screen')),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent, greaterThan(0));
      await _scrollToEnd(tester, position);

      final last = tester.getRect(find.byKey(const Key('team-roles-summary')));
      final fab = tester.getRect(find.byKey(const Key('team-invite-fab')));
      expect(last.bottom, lessThanOrEqualTo(fab.top), reason: '$last vs $fab');
    });

    for (final width in const [390.0, 375.0]) {
      testWidgets(
        'at width $width text 1.35 the roles card clears the measured FAB',
        (tester) async {
          final ParityVariant variant = (
            width: width,
            textScale: 1.35,
            suffix: 'geom_${width.toInt()}_t135',
          );
          await _pumpScreen(
            tester,
            _api(),
            variant: variant,
            height: 700,
            bottomInset: 34,
          );
          // Let MerchantSizeReporter publish the extended FAB height and
          // rebuild list end padding from the measured value.
          await tester.pumpAndSettle();

          final scrollable = find.descendant(
            of: find.byKey(const Key('team-screen')),
            matching: find.byType(Scrollable),
          );
          final position = tester.state<ScrollableState>(scrollable).position;
          expect(position.maxScrollExtent, greaterThan(0));
          await _scrollToEnd(tester, position);

          final summary = find.byKey(const Key('team-roles-summary'));
          final scope = find.byKey(const Key('team-role-summary-SCOPE'));
          final fab = find.byKey(const Key('team-invite-fab'));
          expect(summary, findsOneWidget);
          expect(scope, findsOneWidget);
          expect(fab, findsOneWidget);

          final summaryRect = tester.getRect(summary);
          final scopeRect = tester.getRect(scope);
          final fabRect = tester.getRect(fab);
          expect(
            summaryRect.bottom,
            lessThanOrEqualTo(fabRect.top - 8),
            reason: 'summary $summaryRect must clear FAB $fabRect with gap',
          );
          expect(
            scopeRect.bottom,
            lessThanOrEqualTo(fabRect.top - 8),
            reason:
                'branch-access line $scopeRect must stay readable above FAB '
                '$fabRect',
          );
          expect(
            find.text(AppStrings.teamSummaryScope),
            findsOneWidget,
            reason: 'scope explanation must remain fully laid out (no clamp)',
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    for (final width in const [390.0, 375.0]) {
      testWidgets(
        'at width $width text 1.0 the roles card clears the FAB',
        (tester) async {
          final ParityVariant variant = (
            width: width,
            textScale: 1.0,
            suffix: 'geom_${width.toInt()}_t100',
          );
          await _pumpScreen(
            tester,
            _api(),
            variant: variant,
            height: 700,
            bottomInset: 34,
          );
          await tester.pumpAndSettle();
          final scrollable = find.descendant(
            of: find.byKey(const Key('team-screen')),
            matching: find.byType(Scrollable),
          );
          final position = tester.state<ScrollableState>(scrollable).position;
          await _scrollToEnd(tester, position);
          final last = tester.getRect(
            find.byKey(const Key('team-roles-summary')),
          );
          final fab = tester.getRect(find.byKey(const Key('team-invite-fab')));
          expect(
            last.bottom,
            lessThanOrEqualTo(fab.top - 8),
            reason: '$last vs $fab',
          );
        },
      );
    }

    testWidgets('read-only roster ends above the safe area without FAB', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        _api(role: 'MANAGER'),
        variant: _geometry,
        height: 640,
        bottomInset: 34,
      );
      final scrollable = find.descendant(
        of: find.byKey(const Key('team-screen')),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      await _scrollToEnd(tester, position);
      final last = tester.getRect(find.byKey(const Key('team-roles-summary')));
      expect(last.bottom, lessThanOrEqualTo(640 - 34));
    });

    testWidgets('owner badge stacks under the role instead of squeezing', (
      tester,
    ) async {
      await _pumpScreen(tester, _api(), variant: _geometry);
      final phone = tester.getRect(
        find.byKey(const Key('team-member-phone-m-owner')),
      );
      final badge = tester.getRect(
        find.byKey(const Key('team-owner-badge-m-owner')),
      );
      expect(badge.top, greaterThanOrEqualTo(phone.bottom));
      expect(
        _exceeds(tester, find.byKey(const Key('team-member-phone-m-owner'))),
        isFalse,
      );
    });
  });
}
