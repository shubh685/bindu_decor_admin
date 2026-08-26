import 'dart:convert';
import 'package:http/http.dart' as http;

class Api {

  // =====================================================
  // CHANGE THIS TO YOUR LIVE HOSTINGER URL
  // =====================================================

  static const String baseUrl =
      "http://192.168.1.4/bindu_decor/";

  // =====================================================
  // LOGIN
  // =====================================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {

    final response = await http.post(
      Uri.parse("$baseUrl/login.php"),

      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },

      body: jsonEncode({
        "email": email.trim(),
        "password": password,
      }),
    ).timeout(
      const Duration(seconds: 30),
    );


    return _parseResponse(response);
  }


  // =====================================================
  // SEND OTP
  // =====================================================

  static Future<Map<String, dynamic>> sendOtp({
    required String email,
    required String deviceTime,
  }) async {

    final response = await http.post(
      Uri.parse("$baseUrl/forgot_pwd.php"),

      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },

      body: jsonEncode({
        "action": "send_otp",
        "input": email.trim(),
        "device_time": deviceTime,
      }),
    ).timeout(
      const Duration(seconds: 30),
    );


    return _parseResponse(response);
  }


  // =====================================================
  // VERIFY OTP
  // =====================================================

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    required String deviceTime,
  }) async {

    final response = await http.post(
      Uri.parse("$baseUrl/forgot_pwd.php"),

      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },

      body: jsonEncode({
        "action": "verify_otp",
        "input": email.trim(),
        "otp": otp.trim(),
        "device_time": deviceTime,
      }),
    ).timeout(
      const Duration(seconds: 30),
    );


    return _parseResponse(response);
  }


  // =====================================================
  // RESET PASSWORD
  // =====================================================

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String password,
    required String deviceTime,
  }) async {

    final response = await http.post(
      Uri.parse("$baseUrl/forgot_pwd.php"),

      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },

      body: jsonEncode({
        "action": "reset_password",
        "email": email.trim(),
        "password": password,
        "device_time": deviceTime,
      }),
    ).timeout(
      const Duration(seconds: 30),
    );


    return _parseResponse(response);
  }


  // =====================================================
  // COMMON RESPONSE PARSER
  // =====================================================

  static Map<String, dynamic> _parseResponse(
      http.Response response,
      ) {

    try {

      final Map<String, dynamic> data =
      jsonDecode(response.body);

      data["http_code"] = response.statusCode;

      return data;

    } catch (e) {

      return {
        "status": false,
        "message":
        "Invalid server response: ${response.body}",
        "http_code": response.statusCode,
      };
    }
  }

  static Future<Map<String, dynamic>> logout({
    required int userId,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/logout.php"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "user_id": userId,
      }),
    ).timeout(
      const Duration(seconds: 30),
    );

    return _parseResponse(response);
  }

  // =====================================================
// CHANGE PASSWORD
// =====================================================
  static Future<Map<String, dynamic>> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/change_pwd.php"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "email": email.trim(),
        "password": oldPassword,
        "new_password": newPassword,
      }),
    ).timeout(
      const Duration(seconds: 30),
    );

    return _parseResponse(response);
  }
}