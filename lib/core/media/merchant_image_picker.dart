import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';

/// Backend product/cover image contract (see storage policy).
const int kMerchantImageMaxBytes = 2 * 1024 * 1024;
const int kMerchantImageMinPx = 400;
const int kMerchantImageMaxPx = 4096;

/// Upload limits for one media purpose; mirrors the backend storage policy.
class MerchantImageConstraints {
  const MerchantImageConstraints({
    required this.maxBytes,
    required this.minPx,
    required this.maxPx,
    required this.fallbackPx,
    required this.filename,
    required this.tooSmallMessage,
    required this.tooLargeMessage,
  });

  final int maxBytes;
  final int minPx;
  final int maxPx;

  /// Longest side used for the last-resort re-encode.
  final int fallbackPx;
  final String filename;
  final String tooSmallMessage;
  final String tooLargeMessage;

  /// Product images and branch covers (2 MiB, 400–4096 px).
  static MerchantImageConstraints get productOrCover => MerchantImageConstraints(
        maxBytes: kMerchantImageMaxBytes,
        minPx: kMerchantImageMinPx,
        maxPx: kMerchantImageMaxPx,
        fallbackPx: 1280,
        filename: 'product.jpg',
        tooSmallMessage: AppStrings.catalogImageTooSmall,
        tooLargeMessage: AppStrings.catalogImageTooLarge,
      );

  /// Branch logo (1 MiB, 128–2048 px on the server; encoded at ≤ 1024 px).
  static MerchantImageConstraints get logo => MerchantImageConstraints(
        maxBytes: 1024 * 1024,
        minPx: 128,
        maxPx: 1024,
        fallbackPx: 512,
        filename: 'logo.jpg',
        tooSmallMessage: AppStrings.storeLogoTooSmall,
        tooLargeMessage: AppStrings.storeLogoTooLarge,
      );
}

/// Result of a gallery/camera pick (JPEG bytes ready for upload).
class MerchantPickedImage {
  const MerchantPickedImage({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;
}

class MerchantImagePickException implements Exception {
  const MerchantImagePickException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Opens the system photo gallery or camera — not a generic document browser.
Future<MerchantPickedImage?> pickMerchantImage(
  BuildContext context, {
  ImagePicker? picker,
  MerchantImageConstraints? constraints,
}) async {
  final resolved = constraints ?? MerchantImageConstraints.productOrCover;
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(AppStrings.catalogImageFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(AppStrings.catalogImageFromCamera),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      );
    },
  );
  if (source == null) return null;

  try {
    final image = await (picker ?? ImagePicker()).pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (image == null) return null;

    final raw = await image.readAsBytes();
    if (raw.isEmpty) return null;

    return prepareMerchantImage(raw, constraints: resolved);
  } on MissingPluginException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.catalogImagePluginRestart)),
      );
    }
    return null;
  } on MerchantImagePickException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
    return null;
  }
}

/// Decode → enforce dimensions → JPEG under the purpose's byte limit.
MerchantPickedImage prepareMerchantImage(
  Uint8List raw, {
  MerchantImageConstraints? constraints,
}) {
  final decoded = img.decodeImage(raw);
  if (decoded == null) {
    throw MerchantImagePickException(AppStrings.catalogImageFormatError);
  }

  return encodeMerchantFrame(
    img.bakeOrientation(decoded),
    constraints: constraints ?? MerchantImageConstraints.productOrCover,
  );
}

/// Enforce dimensions → JPEG under the purpose's byte limit for a decoded,
/// upright frame.
MerchantPickedImage encodeMerchantFrame(
  img.Image source, {
  MerchantImageConstraints? constraints,
}) {
  final c = constraints ?? MerchantImageConstraints.productOrCover;
  var frame = source;
  final longest = frame.width > frame.height ? frame.width : frame.height;
  if (longest > c.maxPx) {
    frame = img.copyResize(
      frame,
      width: frame.width >= frame.height ? c.maxPx : null,
      height: frame.height > frame.width ? c.maxPx : null,
      interpolation: img.Interpolation.linear,
    );
  }

  if (frame.width < c.minPx || frame.height < c.minPx) {
    throw MerchantImagePickException(c.tooSmallMessage);
  }

  Uint8List? encoded;
  for (final quality in const [85, 75, 65, 55, 45]) {
    final bytes = Uint8List.fromList(img.encodeJpg(frame, quality: quality));
    if (bytes.length <= c.maxBytes) {
      encoded = bytes;
      break;
    }
  }

  if (encoded == null) {
    // Last resort: shrink longest side and encode again.
    frame = img.copyResize(
      frame,
      width: frame.width >= frame.height ? c.fallbackPx : null,
      height: frame.height > frame.width ? c.fallbackPx : null,
      interpolation: img.Interpolation.linear,
    );
    if (frame.width < c.minPx || frame.height < c.minPx) {
      throw MerchantImagePickException(c.tooLargeMessage);
    }
    encoded = Uint8List.fromList(img.encodeJpg(frame, quality: 55));
    if (encoded.length > c.maxBytes) {
      throw MerchantImagePickException(c.tooLargeMessage);
    }
  }

  return MerchantPickedImage(
    bytes: encoded,
    filename: c.filename,
    contentType: 'image/jpeg',
  );
}
