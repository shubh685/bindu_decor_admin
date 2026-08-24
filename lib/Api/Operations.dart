import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:bindu_decor_admin/Helper_class.dart';

class OperationsApi {
  // Update this URL to match your server setup
  static const String baseUrl = 'http://10.165.115.78/bindu_decor/';

  // ==========================================
  // IMAGE URL RESOLUTION
  // ==========================================

  static String resolveImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';

    // If already full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // If it's an asset, return as is
    if (imagePath.startsWith('assets/')) {
      return imagePath;
    }

    // Remove any leading slashes
    String cleanPath = imagePath;
    while (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    // Remove bindu_decor/ prefix if present
    if (cleanPath.startsWith('bindu_decor/')) {
      cleanPath = cleanPath.substring(12);
    }

    // Ensure uploads/ prefix for local files
    if (!cleanPath.startsWith('uploads/') && !cleanPath.startsWith('http')) {
      cleanPath = 'uploads/$cleanPath';
    }

    // Build full URL
    return '$baseUrl$cleanPath';
  }

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

      if (response.statusCode == 200) {
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

      // Add text fields
      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add image if present
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final fileName = imageFileName ?? 'product.jpg';
        final multipartFile = http.MultipartFile.fromBytes(
          'imageFile',
          imageBytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Add Product Response: $responseBody');

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}'};
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

      if (response.statusCode == 200) {
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

      if (response.statusCode == 200) {
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

      // Add text fields
      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add image if present
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final fileName = imageFileName ?? 'project.jpg';
        final multipartFile = http.MultipartFile.fromBytes(
          'imageFile',
          imageBytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Add Project Response: $responseBody');

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}'};
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

      if (response.statusCode == 200) {
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

      if (response.statusCode == 200) {
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

      // Add image URL if provided
      if (imageUrl != null && imageUrl.isNotEmpty) {
        request.fields['image_url'] = imageUrl;
      }

      // Add image bytes if provided
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final fileName = imageFileName ?? 'client.jpg';
        final multipartFile = http.MultipartFile.fromBytes(
          'imageFile',
          imageBytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Add Client Response: $responseBody');

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}'};
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

      if (response.statusCode == 200) {
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