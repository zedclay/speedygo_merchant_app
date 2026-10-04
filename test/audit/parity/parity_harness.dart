import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';
import 'package:speedygo_merchant_app/features/shell/merchant_shell.dart';

import '../../features/phase1_flow_test.dart';

/// Mocked parity captures (fixture data, never live).
const parityOut =
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/parity/mocked';

const parityRootKey = Key('capture-root');

/// Reference logical width (45 of 75 Stitch PNGs are 780 px = 390 pt @2x).
const parityRefWidth = 390.0;

/// Small-screen width used for the text-scale 1.35 capture.
const paritySmallWidth = 375.0;

/// One capture variant: normal text at the reference width, or 1.35 text on
/// a small screen.
typedef ParityVariant = ({double width, double textScale, String suffix});

const parityVariants = <ParityVariant>[
  (width: parityRefWidth, textScale: 1.0, suffix: 'w390'),
  (width: paritySmallWidth, textScale: 1.35, suffix: 'w375_t135'),
];

Future<void> parityCapture(WidgetTester tester, String name) async {
  await tester.pump();
  final renderObject = tester.renderObject(find.byKey(parityRootKey));
  if (renderObject is! RenderRepaintBoundary) {
    throw StateError('capture root is not a RepaintBoundary');
  }
  await tester.runAsync(() async {
    final image = await renderObject.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$parityOut/$name.png');
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Future<ProviderContainer> parityReady(
  FakeMerchantApi merchant, {
  String branchName = 'Dar El Benna',
  String branchStatus = 'ACTIVE',
  List<Override> overrides = const [],
}) async {
  final store = MemorySessionStore()
    ..value = const TokenPair(
      accessToken: 'a',
      refreshToken: 'r',
      expiresIn: 900,
      tokenType: 'Bearer',
    );
  final container =
      testContainer(
    auth: FakeAuthApi(),
    merchant: merchant,
    store: store,
    overrides: overrides,
  );
  container.read(tokenCacheProvider).current = store.value;
  await restoreAndResolve(container);
  await container
      .read(accessControllerProvider.notifier)
      .selectBranch(branch('b1', name: branchName, status: branchStatus));
  return container;
}

/// Pumps [child] at [variant] width and [height], optionally inside the real
/// [MerchantBottomNav] (tab roots only). With [includeOverlays] the capture
/// root wraps the navigator so modal sheets and dialogs are captured too.
/// With [pushed] the child sits above a blank route, as a pushed secondary
/// screen does in the app, so its back button is rendered.
Future<void> parityPump(
  WidgetTester tester, {
  required ProviderContainer container,
  required ParityVariant variant,
  required double height,
  required Widget child,
  int? tabIndex,
  bool includeOverlays = false,
  bool pushed = false,
  double bottomInset = 0,
}) async {
  final wrapNavigator = includeOverlays || pushed;
  final size = Size(variant.width, height);
  tester.view.physicalSize = Size(size.width * 2, size.height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final body = tabIndex == null
      ? child
      : Scaffold(
          backgroundColor: AppColors.background,
          body: child,
          bottomNavigationBar:
              MerchantBottomNav(currentIndex: tabIndex, onSelect: (_) {}),
        );
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(variant.textScale),
        padding: EdgeInsets.only(bottom: bottomInset),
        viewPadding: EdgeInsets.only(bottom: bottomInset),
      ),
      child: UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(locale: const Locale('fr')),
          builder: wrapNavigator
              ? (context, nav) =>
                  RepaintBoundary(key: parityRootKey, child: nav)
              : null,
          home: pushed
              ? null
              : SizedBox(
                  width: size.width,
                  height: size.height,
                  child: wrapNavigator
                      ? body
                      : RepaintBoundary(key: parityRootKey, child: body),
                ),
          initialRoute: pushed ? '/pushed' : null,
          onGenerateRoute: pushed
              ? (settings) => MaterialPageRoute<void>(
                    settings: settings,
                    builder: (_) => const SizedBox.shrink(),
                  )
              : null,
          onGenerateInitialRoutes: pushed
              ? (_) => [
                    MaterialPageRoute<void>(
                      builder: (_) => const SizedBox.shrink(),
                    ),
                    MaterialPageRoute<void>(builder: (_) => body),
                  ]
              : null,
        ),
      ),
    ),
  );
  await tester.pump();
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Pumps at [baseHeight], then re-pumps tall enough to show the whole
/// primary vertical scroll view without scrolling.
Future<void> parityPumpFull(
  WidgetTester tester, {
  required ProviderContainer container,
  required ParityVariant variant,
  required Widget child,
  double baseHeight = 844,
  int? tabIndex,
  bool pushed = false,
}) async {
  await parityPump(
    tester,
    container: container,
    variant: variant,
    height: baseHeight,
    child: child,
    tabIndex: tabIndex,
    pushed: pushed,
  );
  var height = baseHeight;
  var previous = double.infinity;
  // Content can keep growing after the first measure (late async loads);
  // stop when the overflow no longer shrinks (viewport-dependent content).
  for (var attempt = 0; attempt < 3; attempt++) {
    var extra = 0.0;
    for (final state
        in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
      final position = state.position;
      if (position.axis == Axis.vertical && position.hasContentDimensions) {
        if (position.maxScrollExtent > extra) extra = position.maxScrollExtent;
      }
    }
    if (extra < 1 || extra >= previous) return;
    previous = extra;
    height += extra.ceilToDouble();
    await parityPump(
      tester,
      container: container,
      variant: variant,
      height: height,
      child: child,
      tabIndex: tabIndex,
      pushed: pushed,
    );
  }
}

extension ParityMembershipX on MerchantMembership {
  MerchantMembership parityWith({
    String? name,
    bool? attention,
  }) {
    return MerchantMembership(
      merchantId: merchantId,
      role: role,
      profileComplete: profileComplete,
      hasBranch: hasBranch,
      branchReady: branchReady,
      approved: approved,
      operationalReady: operationalReady,
      verificationReady: verificationReady,
      verificationSubmitted: verificationSubmitted,
      verificationAttentionRequired:
          attention ?? verificationAttentionRequired,
      merchantName: name ?? merchantName,
      merchantStatus: merchantStatus,
      merchantPublicReference: merchantPublicReference,
      verifiedAt: verifiedAt,
      branches: branches,
      evidenceChecklist: evidenceChecklist,
    );
  }
}
