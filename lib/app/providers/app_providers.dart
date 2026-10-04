import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';

final appNameProvider = Provider<String>((ref) => AppStrings.appName);
