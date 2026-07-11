import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String _baseUrl = 'https://digi-luk-backend.vercel.app';

  static Future<String?> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
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

  static Future<List<Map<String, dynamic>>> searchGroups(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/groups/search'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.cast<Map<String, dynamic>>();
      }
      debugPrint('Search groups API error: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Search groups error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getPublicGroup(String trustId) async {
    try {
      final token = await _getIdToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/api/groups/$trustId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('Get public group error: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Get public group error: $e');
      return null;
    }
  }

  static Future<bool> requestJoinGroup(String trustId) async {
    try {
      final token = await _getIdToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/api/groups/request-join'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'trustId': trustId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Request join error: $e');
      return false;
    }
  }

  static Future<bool> approveRequest(
      String trustId, String notificationId, String userId) async {
    try {
      final token = await _getIdToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/api/groups/approve-request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'trustId': trustId,
          'notificationId': notificationId,
          'userId': userId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Approve request error: $e');
      return false;
    }
  }

  static Future<bool> rejectRequest(
      String trustId, String notificationId, String userId) async {
    try {
      final token = await _getIdToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/api/groups/reject-request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'trustId': trustId,
          'notificationId': notificationId,
          'userId': userId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Reject request error: $e');
      return false;
    }
  }
}
