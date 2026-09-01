import 'dart:io';
import 'package:bindu_decor_admin/Admin_Auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AdminDashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // CRITICAL: Override HTTP client for all network requests
  HttpOverrides.global = MyHttpOverrides();

  // Check 10-day auto login session state
  final bool isLoggedIn = await SessionManager.isSessionValid();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bindu Decor Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: isLoggedIn ? const AdminDashboard() : AdminAuth(),
    );
  }
}

// CRITICAL: Override all SSL/network issues
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..connectionTimeout = const Duration(seconds: 60)
      ..idleTimeout = const Duration(seconds: 60)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

// Session Manager helper handling 10-day expiration linked with login.php user response
// Session Manager helper handling 10-day expiration linked with login.php user response
class SessionManager {
  static const String keyIsLoggedIn = "is_logged_in";
  static const String keyLoginTimestamp = "login_timestamp";
  static const String keyUserId = "user_id";
  static const String keyUserName = "user_name";
  static const String keyUserEmail = "user_email";
  static const int sessionDurationDays = 10;

  // Check if session exists and is under 10 days old
  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool(keyIsLoggedIn) ?? false;
    final int? loginTimestamp = prefs.getInt(keyLoginTimestamp);

    if (!isLoggedIn || loginTimestamp == null) {
      await clearSession();
      return false;
    }

    final DateTime loginDate = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
    final DateTime expirationDate = loginDate.add(const Duration(days: sessionDurationDays));

    if (DateTime.now().isAfter(expirationDate)) {
      await clearSession();
      return false;
    }

    return true;
  }

  // Call this method upon successful response from login.php
  static Future<void> saveSession(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsLoggedIn, true);
    await prefs.setInt(keyLoginTimestamp, DateTime.now().millisecondsSinceEpoch);

    if (userData.containsKey('id')) {
      final idValue = userData['id'];
      if (idValue is int) {
        await prefs.setInt(keyUserId, idValue);
      } else if (idValue is String) {
        await prefs.setInt(keyUserId, int.tryParse(idValue) ?? 0);
      }
    }
    if (userData.containsKey('name')) {
      await prefs.setString(keyUserName, userData['name']?.toString() ?? '');
    }
    if (userData.containsKey('email')) {
      await prefs.setString(keyUserEmail, userData['email']?.toString() ?? '');
    }
  }

  // Auto-logout action
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyIsLoggedIn);
    await prefs.remove(keyLoginTimestamp);
    await prefs.remove(keyUserId);
    await prefs.remove(keyUserName);
    await prefs.remove(keyUserEmail);
  }
}