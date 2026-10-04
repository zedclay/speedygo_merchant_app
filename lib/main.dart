import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_messaging_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final push = await FirebasePushMessagingGateway.bootstrap();
  runApp(
    ProviderScope(
      overrides: [pushMessagingGatewayProvider.overrideWithValue(push)],
      child: const SpeedyGoApp(),
    ),
  );
}
