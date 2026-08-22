import 'dart:io';
import 'package:bindu_decor_admin/Admin_Auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bindu Decor Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: AdminAuth(),
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