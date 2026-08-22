import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client createClient() {
  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 60)
    ..idleTimeout = const Duration(seconds: 60)
    ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  return IOClient(client);
}