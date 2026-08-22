import 'package:http/http.dart' as http;

http.Client createClient() {
  throw UnsupportedError(
    'Cannot create an HTTP client without platform implementation. Ensure conditionally imported files exist.',
  );
}