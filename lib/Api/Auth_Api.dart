import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Api {
  // =====================================================
  // CENTRAL PHP API LOCATION
  // =====================================================
  static const String baseUrl =
      "https://yellow-woodpecker-430323.hostingersite.com/bindu_admin_web/";

  // Helper method to safely format endpoints
  static Uri _getUri(String endpoint) {
    String cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return Uri.parse('$baseUrl/$cleanEndpoint');
  }

  // Common headers for JSON requests
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Default timeout duration
  static const Duration _timeoutDuration = Duration(seconds: 30);

  // =====================================================
  // LOGIN
  // =====================================================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
        _getUri('login.php'),
        headers: _headers,
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      )
          .timeout(_timeoutDuration);

      return _parseResponse(response);
    } on TimeoutException {
      return {
        'status': false,
        'message': 'Connection timed out. Please try again.',
      };
    } catch (e) {
      return {
        'status': false,
        'message': 'Network error or unable to reach server.',
      };
    }
  }

  // =====================================================
  // SEND OTP
  // =====================================================
  static Future<Map<String, dynamic>> sendOtp({
    required String email,
    required String deviceTime,
  }) async {
    try {
      final response = await http
          .post(
        _getUri('forgot_pwd.php'),
        headers: _headers,
        body: jsonEncode({
          'action': 'send_otp',
          'input': email.trim(),
          'device_time': deviceTime,
        }),
      )
          .timeout(_timeoutDuration);

      return _parseResponse(response);
    } on TimeoutException {
      return {
        'status': false,
        'message': 'Request timed out while sending OTP.',
      };
    } catch (e) {
      return {
        'status': false,
        'message': 'Network error occurred while sending OTP.',
      };
    }
  }

  // =====================================================
  // VERIFY OTP
  // =====================================================
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    required String deviceTime,
  }) async {
    try {
      final response = await http
          .post(
        _getUri('forgot_pwd.php'),
        headers: _headers,
        body: jsonEncode({
          'action': 'verify_otp',
          'input': email.trim(),
          'otp': otp.trim(),
          'device_time': deviceTime,
        }),
      )
          .timeout(_timeoutDuration);

      return _parseResponse(response);
    } on TimeoutException {
      return {
        'status': false,
        'message': 'Request timed out while verifying OTP.',
      };
    } catch (e) {
      return {
        'status': false,
        'message': 'Network error occurred while verifying OTP.',
      };
    }
  }

  // =====================================================
  // RESET PASSWORD
  // =====================================================
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String password,
    required String deviceTime,
  }) async {
    try {
      final response = await http
          .post(
        _getUri('forgot_pwd.php'),
        headers: _headers,
        body: jsonEncode({
          'action': 'reset_password',
          'email': email.trim(),
          'password': password,
          'device_time': deviceTime,
        }),
      )
          .timeout(_timeoutDuration);

      return _parseResponse(response);
    } on TimeoutException {
      return {
        'status': false,
        'message': 'Request timed out while resetting password.',
      };
    } catch (e) {
      return {
        'status': false,
        'message': 'Network error occurred while resetting password.',
      };
    }
  }

  // =====================================================
  // LOGOUT
  // =====================================================
  static Future<Map<String, dynamic>> logout({
    required int userId,
  }) async {
    try {
      final response = await http
          .post(
        _getUri('logout.php'),
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
        }),
      )
          .timeout(_timeoutDuration);

      return _parseResponse(response);
    } on TimeoutException {
      return {
        'status': false,
        'message': 'Request timed out while logging out.',
      };
    } catch (e) {
      return {
        'status': false,
        'message': 'Network error occurred during logout.',
      };
    }
  }

  // =====================================================
  // CHANGE PASSWORD
  // =====================================================
  static Future<Map<String, dynamic>> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
        _getUri('change_pwd.php'),
        headers: _headers,
        body: jsonEncode({
          'email': email.trim(),
          'password': oldPassword,
          'new_password': newPassword,
        }),
      )
          .timeout(_timeoutDuration);

      return _parseResponse(response);
    } on TimeoutException {
      return {
        'status': false,
        'message': 'Request timed out while changing password.',
      };
    } catch (e) {
      return {
        'status': false,
        'message': 'Network error occurred while changing password.',
      };
    }
  }

  // =====================================================
  // COMMON RESPONSE PARSER
  // =====================================================
  static Map<String, dynamic> _parseResponse(http.Response response) {
    if (response.statusCode != 200) {
      return {
        'status': false,
        'message': 'Server error (${response.statusCode}): ${response.body}',
        'http_code': response.statusCode,
      };
    }

    try {
      String cleanBody = response.body.trim();
      if (cleanBody.startsWith('\uFEFF')) {
        cleanBody = cleanBody.substring(1);
      }

      final Map<String, dynamic> data = jsonDecode(cleanBody);
      data['http_code'] = response.statusCode;
      return data;
    } catch (e) {
      return {
        'status': false,
        'message': 'Server output is not valid JSON: ${response.body.trim()}',
        'http_code': response.statusCode,
      };
    }
  }
}