// ==========================================
// UPDATED OPERATIONS API
// ==========================================
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../Helper_Class.dart';

class OperationsApi {
  static const String baseUrl = 'http://192.168.1.15/bindu_decor/';

  // Fetch projects with proper image URLs
  static Future<List<ProjectItem>> fetchProjects() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects.php'),
        body: {'action': 'fetch'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> projectsData = data['data'] ?? [];
          return projectsData.map((item) {
            // Get the image URL from any of the possible fields
            String imageUrl = item['image_url'] ??
                item['imageUrl'] ??
                item['img_url'] ??
                '';

            // Build image URLs list
            List<String> imageUrls = [];
            if (imageUrl.isNotEmpty) {
              imageUrls.add(imageUrl);
            }

            return ProjectItem(
              id: item['id']?.toString() ?? '',
              title: item['title'] ?? '',
              subTitle: item['sub_title'] ?? '',
              location: item['location'] ?? '',
              tags: const [],
              pricing: item['pricing'] ?? '',
              bhk: item['bhk'] ?? '',
              scope: item['scope'] ?? '',
              propertyType: item['property_type'] ?? '',
              size: item['size'] ?? '',
              description: item['description'] ?? '',
              imageUrls: imageUrls,
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching projects: $e');
    }
    return [];
  }

  // Fetch products with proper image URLs
  static Future<List<DecorProductItem>> fetchProducts() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products.php'),
        body: {'action': 'fetch'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> productsData = data['data'] ?? [];
          return productsData.map((item) {
            String imageUrl = item['image_url'] ??
                item['imageUrl'] ??
                item['img_url'] ??
                '';
            List<String> imageUrls = imageUrl.isNotEmpty ? [imageUrl] : [];

            return DecorProductItem(
              id: item['id']?.toString() ?? '',
              title: item['title'] ?? '',
              category: item['category'] ?? 'HOME DECOR',
              imageUrls: imageUrls,
              description: item['description'] ?? '',
              material: item['material'] ?? 'Premium Grade Material',
              printType: item['print_type'] ?? 'High Definition Digital Print / Finish',
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
    return [];
  }

  // Fetch clients with proper image URLs
  static Future<List<ClientItems>> fetchClients() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/clients.php'),
        body: {'action': 'fetch'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> clientsData = data['data'] ?? [];
          return clientsData.map((item) {
            return ClientItems(
              id: item['id']?.toString() ?? '',
              imgUrl: item['img_url'] ?? item['image_url'] ?? '',
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching clients: $e');
    }
    return [];
  }

  // Add project with proper image handling
  static Future<Map<String, dynamic>> addProject({
    required Map<String, String> fields,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/projects.php?action=add'),
      );

      // Add text fields
      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add image file if bytes are provided
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final fileName = imageFileName ?? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        request.files.add(
          http.MultipartFile.fromBytes(
            'imageFile',
            imageBytes,
            filename: fileName,
          ),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      return jsonData;
    } catch (e) {
      debugPrint('Error adding project: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Add product with proper image handling
  static Future<Map<String, dynamic>> addProduct({
    required Map<String, String> fields,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/products.php?action=add'),
      );

      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      if (imageBytes != null && imageBytes.isNotEmpty) {
        final fileName = imageFileName ?? 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
        request.files.add(
          http.MultipartFile.fromBytes(
            'imageFile',
            imageBytes,
            filename: fileName,
          ),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      return jsonData;
    } catch (e) {
      debugPrint('Error adding product: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Delete methods
  static Future<bool> deleteProject(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects.php'),
        body: {'action': 'delete', 'id': id},
      );
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteProduct(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products.php'),
        body: {'action': 'delete', 'id': id},
      );
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteClient(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/clients.php'),
        body: {'action': 'delete', 'id': id},
      );
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      return false;
    }
  }


// Add client with proper image handling (supports camera, gallery, file picker, external URL)
  static Future<Map<String, dynamic>> addClient({
    String? imageUrl,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/clients.php?action=add'),
      );

      // If image URL is provided (external URL or local path)
      if (imageUrl != null && imageUrl.isNotEmpty) {
        request.fields['image_url'] = imageUrl;
      }

      // If image bytes are provided (from camera or gallery)
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final fileName = imageFileName ??
            'client_${DateTime.now().millisecondsSinceEpoch}.jpg';
        request.files.add(
          http.MultipartFile.fromBytes(
            'imageFile',
            imageBytes,
            filename: fileName,
          ),
        );
      }

      final streamedResponse = await request.send();
      final responseData = await streamedResponse.stream.bytesToString();
      final jsonData = json.decode(responseData);

      debugPrint('Add Client Response: $jsonData');
      return jsonData;
    } catch (e) {
      debugPrint('Error adding client: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }
}