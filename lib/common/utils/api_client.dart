import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String _baseUrl = 'https://digi-luk-backend.vercel.app';

  static Future<String?> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken(true);
  }

  static Future<Map<String, dynamic>?> searchUserByEmail(String email) async {
    try {
      final token = await _getIdToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$_baseUrl/api/users/search'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': email.trim().toLowerCase()}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('Search user API error: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Search user error: $e');
      return null;
    }
  }
}
