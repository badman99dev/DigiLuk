import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

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

  Future<String> uploadImage(File file, {String folder = 'digiluk'}) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final respData = await http.Response.fromStream(response);

      if (response.statusCode != 200) {
        throw Exception('Cloudinary upload failed: ${respData.body}');
      }

      final data = jsonDecode(respData.body);
      final url = data['secure_url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('Cloudinary did not return secure_url');
      }
      return url;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
