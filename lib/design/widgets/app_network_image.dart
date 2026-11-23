import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

/// Network image with a disk cache, a short fade-in, and decoding limited to
/// the size it is shown at. Plain `Image.network` keeps no disk cache and
/// decodes the full-resolution bitmap, which is what makes image lists drop
/// frames and balloon memory.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.error,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Shown while loading. Defaults to an empty box.
  final WidgetBuilder? placeholder;

  /// Shown when the image fails to load. Defaults to an empty box.
  final WidgetBuilder? error;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screenW = MediaQuery.sizeOf(context).width;
    final w = width != null && width!.isFinite ? width! : screenW;
    // Decode at display width in device pixels, never more than 1080.
    final cacheW = (w * dpr).clamp(64, 1080).round();

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheW,
      fadeInDuration: const Duration(milliseconds: 180),
      fadeOutDuration: Duration.zero,
      placeholder: (ctx, _) => placeholder?.call(ctx) ?? const SizedBox.shrink(),
      errorWidget: (ctx, _, __) => error?.call(ctx) ?? const SizedBox.shrink(),
    );
  }
}
