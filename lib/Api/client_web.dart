import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

http.Client createClient() {
  final client = BrowserClient();
  // Set withCredentials to true to allow cookies and CORS credentials
  client.withCredentials = true;
  return client;
}