import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/team/data/team_models.dart';
import 'package:speedygo_merchant_app/features/team/presentation/team_screen.dart';

import '../../features/phase1_flow_test.dart';
import 'parity_harness.dart';

class _StubPush extends MerchantPushController {
  @override
  MerchantPushState build() => const MerchantPushState();

  @override
  Future<void> syncRegistration({bool prompt = false}) async {}
}

const _safeBottom = 34.0;
const _height = 700.0;

final _team = MerchantTeam(
  merchantId: 'm-1',
  canManage: true,
  members: const [
    TeamMember(
      id: 'm-owner',
      phone: '+213550000001',
      role: 'OWNER',
      isSelf: true,
      version: 1,
    ),
    TeamMember(
      id: 'm-mgr',
      phone: '+213661123456',
      role: 'MANAGER',
      isSelf: false,
      version: 3,
    ),
    TeamMember(
      id: 'm-staff',
      phone: '+213770987654',
      role: 'STAFF',
      isSelf: false,
      version: 2,
    ),
  ],
  invitations: [
    TeamInvitation(
      id: 'inv-1',
      phone: '+213551234567',
      role: 'STAFF',
      status: 'PENDING',
      version: 2,
      expiresAt: DateTime.utc(2026, 10, 11, 12),
    ),
    TeamInvitation(
      id: 'inv-2',
      phone: '+213699887766',
      role: 'MANAGER',
      status: 'EXPIRED',
      version: 1,
      expiresAt: DateTime.utc(2026, 9, 28, 12),
    ),
  ],
);

FakeMerchantApi _api() {
  final base = membership(
    role: 'OWNER',
    branches: [branch('b1', name: 'Dar El Benna')],
  ).parityWith(name: 'Dar El Benna');
  return FakeMerchantApi(
    meHandler: () async =>
        MerchantMe(merchantMembershipExists: true, memberships: [base]),
  )..team = _team;
}

Future<ProviderContainer> _ready() => parityReady(
  _api(),
  overrides: [merchantPushControllerProvider.overrideWith(_StubPush.new)],
);

void main() {
  group('batch 6 team captures', () {
    for (final v in parityVariants) {
      testWidgets('team top ${v.suffix}', (tester) async {
        final container = await _ready();
        addTearDown(container.dispose);
        await parityPump(
          tester,
          container: container,
          variant: v,
          height: _height,
          child: const TeamScreen(),
          pushed: true,
          bottomInset: _safeBottom,
        );
        await parityCapture(tester, 'b6_team_top_${v.suffix}');
      });

      testWidgets('team end ${v.suffix}', (tester) async {
        final container = await _ready();
        addTearDown(container.dispose);
        await parityPump(
          tester,
          container: container,
          variant: v,
          height: _height,
          child: const TeamScreen(),
          pushed: true,
          bottomInset: _safeBottom,
        );
        final scrollable = find.descendant(
          of: find.byKey(const Key('team-screen')),
          matching: find.byType(Scrollable),
        );
        final position = tester.state<ScrollableState>(scrollable).position;
        for (var i = 0; i < 6; i++) {
          position.jumpTo(position.maxScrollExtent);
          await tester.pumpAndSettle();
          if (position.pixels >= position.maxScrollExtent) break;
        }
        await parityCapture(tester, 'b6_team_end_${v.suffix}');
      });

      testWidgets('team invite sheet ${v.suffix}', (tester) async {
        final container = await _ready();
        addTearDown(container.dispose);
        await parityPump(
          tester,
          container: container,
          variant: v,
          height: _height,
          child: const TeamScreen(),
          pushed: true,
          bottomInset: _safeBottom,
        );
        await tester.tap(find.byKey(const Key('team-invite-fab')));
        await tester.pumpAndSettle();
        await parityCapture(tester, 'b6_team_invite_sheet_${v.suffix}');
      });
    }
  });
}
