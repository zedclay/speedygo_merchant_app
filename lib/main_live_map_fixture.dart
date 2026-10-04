import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/features/access/presentation/location_picker_screen.dart';

/// Isolated live-map fixture. Does not touch Finjan / auth / dossier.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const LocationPickerScreen(
          initialLatitude: 36.7538,
          initialLongitude: 3.0588,
          branchLabel: 'Live Map Fixture',
          addressHint: 'Alger test',
        ),
      ),
    ),
  );
}
