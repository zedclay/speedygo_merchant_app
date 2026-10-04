import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/media/merchant_image_picker.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';

/// Outcome of [ProductImageCropScreen]: a cropped image, or a request to
/// remove the product image. Popping without a result keeps things as they
/// were.
class ProductImageCropResult {
  const ProductImageCropResult.image(MerchantPickedImage this.image)
    : remove = false;
  const ProductImageCropResult.remove() : image = null, remove = true;

  final MerchantPickedImage? image;
  final bool remove;
}

/// Square crop, in pixels of the image after [quarterTurns] clockwise turns.
typedef MerchantCropRequest = ({
  Uint8List bytes,
  int quarterTurns,
  double x,
  double y,
  double side,
});

/// Rotates, crops to a square and re-encodes under the upload contract.
/// A crop smaller than [kMerchantImageMinPx] is scaled up to that size.
MerchantPickedImage cropMerchantImage(MerchantCropRequest r) {
  final decoded = img.decodeImage(r.bytes);
  if (decoded == null) {
    throw const MerchantImagePickException(AppStrings.catalogImageFormatError);
  }
  var frame = img.bakeOrientation(decoded);
  final turns = r.quarterTurns % 4;
  if (turns != 0) frame = img.copyRotate(frame, angle: 90 * turns);
  final maxSide = math.min(frame.width, frame.height);
  final side = r.side.round().clamp(1, maxSide);
  final x = r.x.round().clamp(0, frame.width - side);
  final y = r.y.round().clamp(0, frame.height - side);
  var out = img.copyCrop(frame, x: x, y: y, width: side, height: side);
  if (side < kMerchantImageMinPx) {
    out = img.copyResize(
      out,
      width: kMerchantImageMinPx,
      height: kMerchantImageMinPx,
      interpolation: img.Interpolation.cubic,
    );
  }
  return encodeMerchantFrame(out);
}

/// Frame inset of the crop guide inside the square viewport.
const double _kCropInset = 16;

class ProductImageCropScreen extends StatefulWidget {
  const ProductImageCropScreen({
    super.key,
    required this.bytes,
    this.productName,
    this.allowRemove = true,
    this.pickReplacement,
    this.cropper,
  });

  final Uint8List bytes;
  final String? productName;
  final bool allowRemove;

  /// Replacement picker; defaults to [pickMerchantImage].
  final Future<MerchantPickedImage?> Function(BuildContext context)?
  pickReplacement;

  /// Crop implementation; defaults to [cropMerchantImage] on a worker isolate.
  final Future<MerchantPickedImage> Function(MerchantCropRequest request)?
  cropper;

  @override
  State<ProductImageCropScreen> createState() => _ProductImageCropScreenState();
}

class _ProductImageCropScreenState extends State<ProductImageCropScreen> {
  final _transform = TransformationController();
  late Uint8List _bytes = widget.bytes;
  Size? _sourceSize;
  int _turns = 0;
  double? _viewport;
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sourceSize = _readSize(_bytes);
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  static Size? _readSize(Uint8List bytes) {
    final info = img.findDecoderForData(bytes)?.startDecode(bytes);
    if (info == null || info.width <= 0 || info.height <= 0) return null;
    return Size(info.width.toDouble(), info.height.toDouble());
  }

  Size get _rotated {
    final s = _sourceSize!;
    return _turns.isOdd ? Size(s.height, s.width) : s;
  }

  /// Display scale at zoom 1: the rotated image covers the square viewport.
  double _baseScale(double viewport) =>
      viewport / math.min(_rotated.width, _rotated.height);

  double _maxScale(double viewport) {
    final cropAtOne = (viewport - 2 * _kCropInset) / _baseScale(viewport);
    return math.max(1, math.min(4, cropAtOne / kMerchantImageMinPx));
  }

  void _resetTransform(double viewport) {
    final base = _baseScale(viewport);
    final w = _rotated.width * base;
    final h = _rotated.height * base;
    _transform.value = Matrix4.translationValues(
      (viewport - w) / 2,
      (viewport - h) / 2,
      0,
    );
  }

  void _rotate() {
    setState(() {
      _turns = (_turns + 1) % 4;
      _error = null;
    });
    final v = _viewport;
    if (v != null) _resetTransform(v);
  }

  void _toggleZoom() {
    final v = _viewport;
    if (v == null) return;
    final m = _transform.value;
    final current = m.getMaxScaleOnAxis();
    final maxScale = _maxScale(v);
    final target = current > 1.01 ? 1.0 : math.min(2.0, maxScale);
    if ((target - current).abs() < 0.001) return;
    final base = _baseScale(v);
    final w = _rotated.width * base * target;
    final h = _rotated.height * base * target;
    final c = v / 2;
    final tx = m.getTranslation().x;
    final ty = m.getTranslation().y;
    final nx = (c - (c - tx) * target / current).clamp(v - w, 0.0);
    final ny = (c - (c - ty) * target / current).clamp(v - h, 0.0);
    _transform.value = Matrix4.identity()
      ..setTranslationRaw(nx, ny, 0)
      ..scaleByDouble(target, target, 1, 1);
  }

  Future<void> _changePhoto() async {
    final picker = widget.pickReplacement ?? pickMerchantImage;
    final picked = await picker(context);
    if (picked == null || !mounted) return;
    final size = _readSize(picked.bytes);
    if (size == null) return;
    setState(() {
      _bytes = picked.bytes;
      _sourceSize = size;
      _turns = 0;
      _error = null;
    });
    final v = _viewport;
    if (v != null) _resetTransform(v);
  }

  MerchantCropRequest? _currentRequest() {
    final v = _viewport;
    if (v == null || _sourceSize == null) return null;
    final m = _transform.value;
    final s = m.getMaxScaleOnAxis();
    final t = m.getTranslation();
    final pixelsPerPoint = 1 / (s * _baseScale(v));
    return (
      bytes: _bytes,
      quarterTurns: _turns,
      x: (_kCropInset - t.x) * pixelsPerPoint,
      y: (_kCropInset - t.y) * pixelsPerPoint,
      side: (v - 2 * _kCropInset) * pixelsPerPoint,
    );
  }

  Future<void> _use() async {
    final request = _currentRequest();
    if (request == null || _working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final cropper =
          widget.cropper ??
          (MerchantCropRequest r) => Isolate.run(() => cropMerchantImage(r));
      final result = await cropper(request);
      if (!mounted) return;
      Navigator.of(context).pop(ProductImageCropResult.image(result));
    } on MerchantImagePickException catch (e) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = AppStrings.catalogImageFormatError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MerchantScaffold(
      title: AppStrings.catalogCropTitle,
      centerTitle: true,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      headerColor: AppColors.surface,
      bodyPadding: EdgeInsets.zero,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              key: const Key('crop-scroll'),
              padding: EdgeInsets.zero,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final v = constraints.maxWidth;
                    if (_sourceSize != null && _viewport != v) {
                      final first = _viewport == null;
                      _viewport = v;
                      if (first) {
                        _resetTransform(v);
                      } else {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _viewport == v) _resetTransform(v);
                        });
                      }
                    }
                    return SizedBox(
                      width: v,
                      height: v,
                      child: _sourceSize == null
                          ? const ColoredBox(
                              color: AppColors.surfaceVariant,
                              child: Center(
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            )
                          : _CropViewport(
                              bytes: _bytes,
                              source: _sourceSize!,
                              turns: _turns,
                              viewport: v,
                              baseScale: _baseScale(v),
                              maxScale: _maxScale(v),
                              controller: _transform,
                              onRotate: _working ? null : _rotate,
                              onZoom: _working ? null : _toggleZoom,
                            ),
                    );
                  },
                ),
                _ActionsRow(
                  onChange: _working ? null : _changePhoto,
                  onRemove: widget.allowRemove && !_working
                      ? () =>
                            Navigator.of(context)
                                .pop(const ProductImageCropResult.remove())
                      : null,
                  showRemove: widget.allowRemove,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(
                      _error!,
                      key: const Key('crop-error'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _TipsCard(productName: widget.productName),
                ),
              ],
            ),
          ),
          MerchantStickyBar(
            child: FilledButton(
              key: const Key('crop-use'),
              onPressed: _sourceSize == null || _working ? null : _use,
              child: _working
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Text(AppStrings.catalogCropUse),
            ),
          ),
        ],
      ),
    );
  }
}

class _CropViewport extends StatelessWidget {
  const _CropViewport({
    required this.bytes,
    required this.source,
    required this.turns,
    required this.viewport,
    required this.baseScale,
    required this.maxScale,
    required this.controller,
    required this.onRotate,
    required this.onZoom,
  });

  final Uint8List bytes;
  final Size source;
  final int turns;
  final double viewport;
  final double baseScale;
  final double maxScale;
  final TransformationController controller;
  final VoidCallback? onRotate;
  final VoidCallback? onZoom;

  @override
  Widget build(BuildContext context) {
    final imageW = source.width * baseScale;
    final imageH = source.height * baseScale;
    final rotatedW = turns.isOdd ? imageH : imageW;
    final rotatedH = turns.isOdd ? imageW : imageH;
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: AppColors.surfaceVariant,
            child: InteractiveViewer(
              key: const Key('crop-viewer'),
              transformationController: controller,
              constrained: false,
              minScale: 1,
              maxScale: maxScale,
              boundaryMargin: EdgeInsets.zero,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: rotatedW,
                height: rotatedH,
                child: RotatedBox(
                  quarterTurns: turns,
                  child: Image.memory(
                    bytes,
                    width: imageW,
                    height: imageH,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: Padding(
              padding: EdgeInsets.all(_kCropInset),
              child: CustomPaint(painter: _CropGuidePainter()),
            ),
          ),
        ),
        Positioned(
          right: 24,
          bottom: 24,
          child: Column(
            children: [
              _ToolButton(
                key: const Key('crop-rotate'),
                icon: Icons.rotate_right,
                tooltip: AppStrings.catalogCropRotate,
                onPressed: onRotate,
              ),
              const SizedBox(height: 8),
              _ToolButton(
                key: const Key('crop-zoom'),
                icon: Icons.zoom_in,
                tooltip: AppStrings.catalogCropZoom,
                onPressed: maxScale > 1 ? onZoom : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CropGuidePainter extends CustomPainter {
  const _CropGuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (final f in const [1 / 3, 2 / 3]) {
      canvas.drawLine(
        Offset(0, size.height * f),
        Offset(size.width, size.height * f),
        line,
      );
      canvas.drawLine(
        Offset(size.width * f, 0),
        Offset(size.width * f, size.height),
        line,
      );
    }
    final dash = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const on = 8.0;
    const off = 5.0;
    void dashed(Offset a, Offset b) {
      final length = (b - a).distance;
      final dir = (b - a) / length;
      for (var d = 0.0; d < length; d += on + off) {
        canvas.drawLine(a + dir * d, a + dir * math.min(d + on, length), dash);
      }
    }

    const tl = Offset.zero;
    final tr = Offset(size.width, 0);
    final bl = Offset(0, size.height);
    final br = Offset(size.width, size.height);
    dashed(tl, tr);
    dashed(tr, br);
    dashed(br, bl);
    dashed(bl, tl);
    final dot = Paint()..color = AppColors.primary;
    for (final c in [tl, tr, bl, br]) {
      canvas.drawCircle(c, 8, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _CropGuidePainter oldDelegate) => false;
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.9),
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.outlineVariant),
      ),
      elevation: 2,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.onSurface),
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.onChange,
    required this.onRemove,
    required this.showRemove,
  });

  final VoidCallback? onChange;
  final VoidCallback? onRemove;
  final bool showRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: merchantCardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('crop-change'),
                onPressed: onChange,
                icon: const Icon(Icons.photo_library_outlined, size: 20),
                label: const Text(AppStrings.catalogImageChangePhoto),
              ),
            ),
            if (showRemove) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: OutlinedButton(
                  key: const Key('crop-remove'),
                  onPressed: onRemove,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    semanticLabel: AppStrings.catalogCropRemove,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({this.productName});

  final String? productName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget tip(String text) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: merchantCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.catalogCropTipsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          tip(AppStrings.catalogCropTip1),
          tip(AppStrings.catalogCropTip2),
          tip(AppStrings.catalogCropTip3(productName)),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 18,
                color: AppColors.outline,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.catalogCropFormat,
                  key: const Key('crop-format'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
