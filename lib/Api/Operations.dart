import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../Helper_Class.dart';

class OperationsApi {
  static const String baseUrl = "http://192.168.0.102/bindu_decor";

  static void _attachImageFile(http.MultipartRequest request, List<int> imageBytes, String prefix) {
    bool isPng = imageBytes.length > 8 &&
        imageBytes[0] == 0x89 &&
        imageBytes[1] == 0x50 &&
        imageBytes[2] == 0x4E &&
        imageBytes[3] == 0x47;

    String extension = isPng ? 'png' : 'jpg';
    String mimeSubtype = isPng ? 'png' : 'jpeg';

    request.files.add(
      http.MultipartFile.fromBytes(
        'imageFile',
        imageBytes,
        filename: '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$extension',
        contentType: MediaType('image', mimeSubtype),
      ),
    );
  }

  // Projects
  static Future<List<ProjectItem>> fetchProjects() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/projects.php?action=fetch"));
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['status'] == 'success' && resData['data'] != null) {
          final List list = resData['data'];
          return list.map((item) => ProjectItem.fromMap(item)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("API Fetch Error: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> addProject({
    required Map<String, String> fields,
    List<int>? imageBytes,
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/projects.php?action=add");
      final request = http.MultipartRequest('POST', uri);
      request.fields.addAll(fields);

      if (imageBytes != null && imageBytes.isNotEmpty) {
        _attachImageFile(request, imageBytes, 'project');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        try {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } on FormatException {
          return {
            "status": "error",
            "message": "Invalid JSON response from server: ${response.body}"
          };
        }
      } else {
        return {
          "status": "error",
          "message": "Server error with status code: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<bool> deleteProject(String id) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/projects.php?action=delete"),
        body: {'id': id},
      );
      return response.statusCode == 200 && jsonDecode(response.body)['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  // Products
  static Future<List<DecorProductItem>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/products.php?action=fetch"));
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['status'] == 'success' && resData['data'] != null) {
          final List list = resData['data'];
          return list.map((item) => DecorProductItem.fromMap(item)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> addProduct({
    required Map<String, String> fields,
    List<int>? imageBytes,
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/products.php?action=add");
      final request = http.MultipartRequest('POST', uri);
      request.fields.addAll(fields);

      if (imageBytes != null && imageBytes.isNotEmpty) {
        _attachImageFile(request, imageBytes, 'product');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<bool> deleteProduct(String id) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/products.php?action=delete"),
        body: {'id': id},
      );
      return response.statusCode == 200 && jsonDecode(response.body)['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  // Clients
  static Future<List<ClientItems>> fetchClients() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/clients.php?action=fetch"));
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['status'] == 'success' && resData['data'] != null) {
          final List list = resData['data'];
          return list.map((item) => ClientItems.fromMap(item)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> addClient({
    String? imageUrl,
    List<int>? imageBytes,
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/clients.php?action=add");
      final request = http.MultipartRequest('POST', uri);

      if (imageUrl != null && imageUrl.isNotEmpty) {
        request.fields['image_url'] = imageUrl;
      }

      if (imageBytes != null && imageBytes.isNotEmpty) {
        _attachImageFile(request, imageBytes, 'client');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<bool> deleteClient(String id) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/clients.php?action=delete"),
        body: {'id': id},
      );
      return response.statusCode == 200 && jsonDecode(response.body)['status'] == 'success';
    } catch (e) {
      return false;
    }
  }
}