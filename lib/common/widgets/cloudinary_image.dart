import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:digiluk/common/repositories/cloudinary_repository.dart';

class CloudinaryImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool tapForFullScreen;
  final int? displayWidth;
  final int? displayHeight;
  final String quality;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CloudinaryImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.tapForFullScreen = true,
    this.displayWidth,
    this.displayHeight,
    this.quality = 'auto',
    this.placeholder,
    this.errorWidget,
  });

  String get _displayUrl => imageUrl.cloudinaryOptimized(
        width: displayWidth ?? width?.toInt(),
        height: displayHeight ?? height?.toInt(),
        quality: quality,
      );

  Widget _buildImage() {
    final image = CachedNetworkImage(
      imageUrl: _displayUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>
          placeholder ??
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
      fadeInDuration: const Duration(milliseconds: 300),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  @override
  Widget build(BuildContext context) {
    if (tapForFullScreen) {
      return GestureDetector(
        onTap: () => _showFullScreen(context),
        child: _buildImage(),
      );
    }
    return _buildImage();
  }

  void _showFullScreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
            title: const Text(
              'Image',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                fadeInDuration: const Duration(milliseconds: 300),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CloudinaryCircleAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Widget? fallback;
  final bool tapForFullScreen;
  final int? displayWidth;

  const CloudinaryCircleAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24,
    this.backgroundColor,
    this.fallback,
    this.tapForFullScreen = true,
    this.displayWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: fallback,
      );
    }

    final child = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: CachedNetworkImageProvider(
        imageUrl.cloudinaryOptimized(
          width: displayWidth ?? (radius * 2).toInt(),
          quality: 'auto',
        ),
      ),
      child: fallback,
    );

    if (tapForFullScreen) {
      return GestureDetector(
        onTap: () => _showFullScreen(context),
        child: child,
      );
    }
    return child;
  }

  void _showFullScreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
            title: const Text(
              'Image',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 48),
                ),
                fadeInDuration: const Duration(milliseconds: 300),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
