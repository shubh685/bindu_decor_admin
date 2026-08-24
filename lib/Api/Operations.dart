// Operations.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:bindu_decor_admin/Helper_class.dart';

class OperationsApi {
  // ⚠️ CHANGE THIS TO YOUR ACTUAL SERVER URL
  // For local testing on same PC: use localhost
  // For Android emulator: use 10.0.2.2
  // For real device: use your PC's actual LAN IP
  static const String baseUrl = 'http://192.168.1.54/bindu_decor/';

  // ==========================================
  // IMAGE URL RESOLUTION — now routed through image.php
  // ==========================================
  //
  // Why: your JSON APIs (clients.php/projects.php/products.php) always
  // return HTTP 200, but direct static files under /uploads/ were failing
  // with statusCode 0 (a connection-level failure, not a 404). Serving
  // images through image.php makes them behave exactly like your working
  // JSON endpoints — same headers, same code path, same reliability.

  static String resolveImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';

    String raw = imagePath.trim();
    print('🔍 RESOLVING IMAGE: "$raw"');

    // Data URI - return as is
    if (raw.startsWith('data:image/')) {
      return raw;
    }

    // Asset - return as is
    if (raw.startsWith('assets/')) {
      return raw;
    }

    // Already pointing at our image.php - return as is
    if (raw.contains('image.php?path=')) {
      print('✅ Already an image.php URL: $raw');
      return raw;
    }

    String cleanPath = raw;

    // If it's a full URL (any host), extract just the path portion
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      try {
        final uri = Uri.parse(raw);
        cleanPath = uri.path;
      } catch (e) {
        cleanPath = raw;
      }
    }

    // Normalize
    cleanPath = cleanPath.replaceAll('\\', '/');
    while (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    // Strip any duplicate bindu_decor/ or uploads/uploads/ prefixes
    List<String> prefixes = [
      'http://localhost/bindu_decor/',
      'http://127.0.0.1/bindu_decor/',
      'http://10.0.2.2/bindu_decor/',
      'http://192.168.1.54/bindu_decor/',
      'bindu_decor/',
    ];
    for (String prefix in prefixes) {
      if (cleanPath.toLowerCase().startsWith(prefix.toLowerCase())) {
        cleanPath = cleanPath.substring(prefix.length);
        break;
      }
    }
    while (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    if (cleanPath.toLowerCase().startsWith('uploads/uploads/')) {
      cleanPath = cleanPath.substring('uploads/'.length);
    }
    if (!cleanPath.toLowerCase().startsWith('uploads/') && cleanPath.isNotEmpty) {
      cleanPath = 'uploads/$cleanPath';
    }

    if (cleanPath.isEmpty) return '';

    String base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final fullUrl = '${base}image.php?path=${Uri.encodeComponent(cleanPath)}';

    print('✅ RESOLVED IMAGE URL: $fullUrl');
    return fullUrl;
  }

  // Helper: check successful status codes (200 or 201)
  static bool _isSuccessStatus(int status) => status == 200 || status == 201;

  // ==========================================
  // PRODUCT OPERATIONS
  // ==========================================

  static Future<List<DecorProductItem>> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}products.php?action=fetch'),
        headers: {'Accept': 'application/json'},
      );

      print('Fetch Products Status: ${response.statusCode}');
      print('Fetch Products Response: ${response.body}');

      if (_isSuccessStatus(response.statusCode)) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final List<dynamic> products = data['data'];
          return products.map((item) => DecorProductItem.fromMap(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addProduct({
    required Map<String, String> fields,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${baseUrl}products.php?action=add'),
      );

      request.fields.addAll(fields);

      if (imageBytes != null && imageBytes.isNotEmpty) {
        final fileName = imageFileName ?? 'product.jpg';
        String subtype = 'jpeg';
        if (fileName.toLowerCase().endsWith('.png')) subtype = 'png';
        else if (fileName.toLowerCase().endsWith('.webp')) subtype = 'webp';
        else if (fileName.toLowerCase().endsWith('.gif')) subtype = 'gif';
        final multipartFile = http.MultipartFile.fromBytes(
          'imageFile',
          imageBytes,
          filename: fileName,
          contentType: MediaType('image', subtype),
        );
        request.files.add(multipartFile);
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print('Add Product HTTP(${response.statusCode}): ${response.body}');

      if (_isSuccessStatus(response.statusCode)) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'raw': response.body};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  static Future<bool> deleteProduct(String id) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}products.php?action=delete'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'id': id},
      );

      print('Delete Product HTTP(${response.statusCode}): ${response.body}');

      if (_isSuccessStatus(response.statusCode)) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  // ==========================================
  // PROJECT OPERATIONS
  // ==========================================

  static Future<List<ProjectItem>> fetchProjects() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}projects.php?action=fetch'),
        headers: {'Accept': 'application/json'},
      );

      print('Fetch Projects Status: ${response.statusCode}');
      print('Fetch Projects Response: ${response.body}');

      if (_isSuccessStatus(response.statusCode)) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final List<dynamic> projects = data['data'];
          return projects.map((item) => ProjectItem.fromMap(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching projects: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addProject({
    required Map<String, String> fields,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${baseUrl}projects.php?action=add'),
      );

      request.fields.addAll(fields);

      if (imageBytes != null && imageBytes.isNotEmpty) {
        final fileName = imageFileName ?? 'project.jpg';
        String subtype = 'jpeg';
        if (fileName.toLowerCase().endsWith('.png')) subtype = 'png';
        else if (fileName.toLowerCase().endsWith('.webp')) subtype = 'webp';
        else if (fileName.toLowerCase().endsWith('.gif')) subtype = 'gif';
        final multipartFile = http.MultipartFile.fromBytes(
          'imageFile',
          imageBytes,
          filename: fileName,
          contentType: MediaType('image', subtype),
        );
        request.files.add(multipartFile);
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print('Add Project HTTP(${response.statusCode}): ${response.body}');

      if (_isSuccessStatus(response.statusCode)) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'raw': response.body};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  static Future<bool> deleteProject(String id) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}projects.php?action=delete'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'id': id},
      );

      print('Delete Project HTTP(${response.statusCode}): ${response.body}');

      if (_isSuccessStatus(response.statusCode)) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error deleting project: $e');
      return false;
    }
  }

  // ==========================================
  // CLIENT OPERATIONS
  // ==========================================

  static Future<List<ClientItems>> fetchClients() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}clients.php?action=fetch'),
        headers: {'Accept': 'application/json'},
      );

      print('Fetch Clients Status: ${response.statusCode}');
      print('Fetch Clients Response: ${response.body}');

      if (_isSuccessStatus(response.statusCode)) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final List<dynamic> clients = data['data'];
          return clients.map((item) => ClientItems.fromMap(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching clients: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addClient({
    String? imageUrl,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${baseUrl}clients.php?action=add'),
      );

      if (imageUrl != null && imageUrl.isNotEmpty) {
        request.fields['image_url'] = imageUrl;
      }

      if (imageBytes != null && imageBytes.isNotEmpty) {
        final fileName = imageFileName ?? 'client.jpg';
        String subtype = 'jpeg';
        if (fileName.toLowerCase().endsWith('.png')) subtype = 'png';
        else if (fileName.toLowerCase().endsWith('.webp')) subtype = 'webp';
        else if (fileName.toLowerCase().endsWith('.gif')) subtype = 'gif';
        final multipartFile = http.MultipartFile.fromBytes(
          'imageFile',
          imageBytes,
          filename: fileName,
          contentType: MediaType('image', subtype),
        );
        request.files.add(multipartFile);
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print('Add Client HTTP(${response.statusCode}): ${response.body}');

      if (_isSuccessStatus(response.statusCode)) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'raw': response.body};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  static Future<bool> deleteClient(String id) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}clients.php?action=delete'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'id': id},
      );

      print('Delete Client HTTP(${response.statusCode}): ${response.body}');

      if (_isSuccessStatus(response.statusCode)) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error deleting client: $e');
      return false;
    }
  }
}