import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:digiluk/common/repositories/cloudinary_repository.dart';

enum ImageUploadState { initial, uploading, error, uploaded }

class ImageUploadPreview extends StatelessWidget {
  final File? file;
  final String? uploadedUrl;
  final ImageUploadState state;
  final int uploadPercent;
  final VoidCallback? onSelect;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;
  final String? placeholderText;
  final String? placeholderIcon;
  final double? width;
  final double? height;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final double? circleRadius;

  const ImageUploadPreview({
    super.key,
    this.file,
    this.uploadedUrl,
    this.state = ImageUploadState.initial,
    this.uploadPercent = 0,
    this.onSelect,
    this.onRetry,
    this.onRemove,
    this.placeholderText,
    this.placeholderIcon,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.circleRadius,
  });

  bool get _hasImage => file != null || (uploadedUrl != null && uploadedUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    if (shape == BoxShape.circle) {
      return _buildCircle(context);
    }
    return _buildRectangle(context);
  }

  Widget _buildCircle(BuildContext context) {
    final radius = circleRadius ?? 44;
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: onSelect,
          child: CircleAvatar(
            radius: radius,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.12),
            backgroundImage: file != null
                ? FileImage(file!)
                : uploadedUrl != null && uploadedUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(
                        uploadedUrl!.cloudinaryOptimized(
                          width: (radius * 2).toInt(),
                          quality: 'auto',
                        ),
                      )
                    : null,
            child: _hasImage
                ? null
                : const Icon(Icons.camera_alt, color: Colors.grey),
          ),
        ),
        if (state == ImageUploadState.uploading) _buildOverlay(radius * 2, radius * 2),
        if (state == ImageUploadState.error) _buildErrorOverlay(radius * 2, radius * 2),
        if (_hasImage) _buildCloseButton(),
      ],
    );
  }

  Widget _buildRectangle(BuildContext context) {
    final w = width ?? double.infinity;
    final h = height ?? 120;
    return GestureDetector(
      onTap: onSelect,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: _hasImage
                ? ClipRRect(
                    borderRadius: borderRadius ?? BorderRadius.circular(12),
                    child: file != null
                        ? Image.file(file!, fit: BoxFit.cover)
                        : CachedNetworkImage(
                            imageUrl: uploadedUrl!.cloudinaryOptimized(
                              width: w == double.infinity ? null : w.toInt(),
                              height: h.toInt(),
                              quality: 'auto',
                            ),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                            fadeInDuration: const Duration(milliseconds: 300),
                          ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        placeholderIcon != null
                            ? _iconFromString(placeholderIcon!)
                            : Icons.add_photo_alternate_outlined,
                        size: 32,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        placeholderText ?? 'Tap to upload image',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),
          if (state == ImageUploadState.uploading) _buildOverlay(w, h),
          if (state == ImageUploadState.error) _buildErrorOverlay(w, h),
          if (_hasImage) _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildOverlay(double? w, double? h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: shape == BoxShape.circle
            ? null
            : (borderRadius ?? BorderRadius.circular(12)),
        shape: shape == BoxShape.circle ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                value: uploadPercent > 0 ? uploadPercent / 100 : null,
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            if (uploadPercent > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$uploadPercent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(double? w, double? h) {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: shape == BoxShape.circle
              ? null
              : (borderRadius ?? BorderRadius.circular(12)),
          shape: shape == BoxShape.circle ? BoxShape.circle : BoxShape.rectangle,
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh,
                color: Colors.red,
                size: 32,
              ),
              SizedBox(height: 4),
              Text(
                'Tap to retry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: 4,
      right: 4,
      child: GestureDetector(
        onTap: onRemove,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  IconData _iconFromString(String name) {
    switch (name) {
      case 'camera':
        return Icons.camera_alt;
      case 'receipt':
        return Icons.receipt_long;
      case 'image':
      default:
        return Icons.add_photo_alternate_outlined;
    }
  }
}

extension ImageUploadStateExtension on ImageUploadState {
  bool get isUploading => this == ImageUploadState.uploading;
  bool get isError => this == ImageUploadState.error;
  bool get isBlocking => isUploading || isError;
}
