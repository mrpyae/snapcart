import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiProvider {
  static const String baseUrl = 'http://localhost/snapcartapi/WebAPI/api';

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/authapi.php?action=login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 5));

      return jsonDecode(res.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyPin(String userAccountId, String pin) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/authapi.php?action=verify_pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_account_id': userAccountId, 'pin': pin}),
      ).timeout(const Duration(seconds: 5));

      return jsonDecode(res.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> performSync(Map<String, dynamic> pushPayload, String? lastSync, {String businessId = 'default_biz'}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/syncapi.php?action=sync&business_id=$businessId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'payload': pushPayload,
          'last_sync': lastSync,
        }),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(res.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Sync network error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteServerData({
    required String permissionPassword,
    required List<String> modules,
    String businessId = 'default_biz',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/cleanupapi.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'permission_password': permissionPassword,
          'modules': modules,
          'business_id': businessId,
        }),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(res.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error deleting server data: $e'};
    }
  }
}

