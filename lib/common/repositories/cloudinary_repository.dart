import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cloudinaryRepositoryProvider = Provider(
  (ref) => const CloudinaryRepository(
    cloudName: 'dlyrigdvz',
    uploadPreset: 'digiluk_uploads',
  ),
);

class CloudinaryRepository {
  final String cloudName;
  final String uploadPreset;

  const CloudinaryRepository({
    required this.cloudName,
    required this.uploadPreset,
  });

  String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  Future<String> uploadImage(
    File file, {
    String folder = 'digiluk',
    void Function(int percent)? onProgress,
  }) async {
    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'upload_preset': uploadPreset,
        'folder': folder,
        'file': await MultipartFile.fromFile(file.path),
      });

      final response = await dio.post(
        _uploadUrl,
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            onProgress?.call((sent / total * 100).round());
          }
        },
      );

      final data = response.data as Map<String, dynamic>?;
      final url = data?['secure_url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('Cloudinary did not return secure_url');
      }
      return url;
    } on DioException catch (e) {
      throw Exception('Cloudinary upload failed: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}

extension CloudinaryUrlUtils on String {
  String cloudinaryOptimized({
    int? width,
    int? height,
    String quality = 'auto',
  }) {
    if (isEmpty) return this;
    if (!contains('cloudinary.com')) return this;
    final parts = <String>[];
    if (quality.isNotEmpty) parts.add('q_$quality');
    if (width != null) parts.add('w_$width');
    if (height != null) parts.add('h_$height');
    if (parts.isEmpty) return this;
    return replaceFirst('/upload/', '/upload/${parts.join(',')}/');
  }
}
