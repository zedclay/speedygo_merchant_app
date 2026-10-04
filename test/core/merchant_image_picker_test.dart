import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speedygo_merchant_app/core/media/merchant_image_picker.dart';

Uint8List _jpeg(int w, int h, {int quality = 90}) {
  final image = img.Image(width: w, height: h);
  img.fill(image, color: img.ColorRgb8(40, 120, 200));
  return Uint8List.fromList(img.encodeJpg(image, quality: quality));
}

void main() {
  test('prepareMerchantImage encodes jpeg under 2 MiB', () {
    final raw = _jpeg(2000, 1500, quality: 95);
    final prepared = prepareMerchantImage(raw);
    expect(prepared.contentType, 'image/jpeg');
    expect(prepared.filename, 'product.jpg');
    expect(prepared.bytes.length, lessThanOrEqualTo(kMerchantImageMaxBytes));
    expect(prepared.bytes[0], 0xff);
    expect(prepared.bytes[1], 0xd8);
  });

  test('prepareMerchantImage rejects tiny images', () {
    final raw = _jpeg(100, 100);
    expect(
      () => prepareMerchantImage(raw),
      throwsA(isA<MerchantImagePickException>()),
    );
  });
}
