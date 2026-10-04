import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumps when bound product/cover bytes may have changed so thumbs and editors
/// re-fetch Merchant JWT streams instead of showing a stale in-memory preview.
class MerchantMediaEpoch extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final merchantMediaEpochProvider = NotifierProvider<MerchantMediaEpoch, int>(
  MerchantMediaEpoch.new,
);

void bumpMerchantMediaEpoch(WidgetRef ref) {
  ref.read(merchantMediaEpochProvider.notifier).bump();
}
