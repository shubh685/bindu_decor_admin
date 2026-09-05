import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:bindu_decor_admin/Helper_class.dart';

class OperationsApi {
  // ==========================================
  // CENTRAL PHP API LOCATION
  // ==========================================
  static const String baseUrl = 'https://yellow-woodpecker-430323.hostingersite.com/bindu_admin_web/';

  // ==========================================
  // IMAGE URL RESOLUTION — routed through image.php

  static String resolveImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) return '';

    String raw = imagePath.trim();

    // Return directly if it's already a full network URL or base64/asset string
    if (raw.startsWith('http://') || raw.startsWith('https://') || raw.startsWith('data:image/') || raw.startsWith('assets/')) {
      return raw;
    }

    // Sanitize backward slashes and leading slashes
    String cleanPath = raw.replaceAll('\\', '/');
    while (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    // Remove duplicate base folder prefix if backend returns it
    if (cleanPath.toLowerCase().startsWith('bindu_decor/')) {
      cleanPath = cleanPath.substring('bindu_decor/'.length);
    }

    // Remove duplicate uploads directory if nested
    if (cleanPath.toLowerCase().startsWith('uploads/')) {
      cleanPath = cleanPath.substring('uploads/'.length);
    }

    // Prepend uploads folder if missing
    if (!cleanPath.toLowerCase().startsWith('uploads/') && cleanPath.isNotEmpty) {
      cleanPath = 'uploads/$cleanPath';
    }

    if (cleanPath.isEmpty) return '';

    // Construct full clean URL (Ensure baseUrl doesn't leave trailing slashes)
    String cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$cleanBase/$cleanPath';
  }

  static bool _isSuccessStatus(int status) => status == 200 || status == 201;

  // ==========================================
  // HELPER: Build URL with proper formatting
  // ==========================================
  static String _buildUrl(String endpoint) {
    String cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$baseUrl/$cleanEndpoint';
  }

  // ==========================================
  // PRODUCT OPERATIONS
  // ==========================================

  static Future<Map<String, dynamic>> addProduct({
    required Map<String, String> fields,
    List<Uint8List>? imageBytesList,
    List<String>? fileNamesList,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      final uri = Uri.parse(_buildUrl('products.php'));
      final request = http.MultipartRequest('POST', uri);

      request.fields['action'] = 'add';
      request.fields.addAll(fields);

      final List<Uint8List> bytesList = imageBytesList ??
          (imageBytes != null ? [imageBytes] : []);
      final List<String>? namesList = fileNamesList ?? (imageFileName != null ? [imageFileName] : null);

      _attachFilesToRequest(request, 'images', bytesList, namesList);

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint('Add Product HTTP(${response.statusCode}): ${response.body}');

      if (_isSuccessStatus(response.statusCode)) {
        try {
          return json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          return {
            'status': 'error',
            'message': 'Invalid JSON response from server',
            'raw': response.body
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
          'raw': response.body
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProduct({
    required Map<String, String> fields,
    List<Uint8List>? imageBytesList,
    List<String>? fileNamesList,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      final uri = Uri.parse(_buildUrl('products.php'));
      final request = http.MultipartRequest('POST', uri);

      request.fields['action'] = 'update';
      request.fields.addAll(fields);

      final List<Uint8List> bytesList = imageBytesList ??
          (imageBytes != null ? [imageBytes] : []);
      final List<String>? namesList = fileNamesList ?? (imageFileName != null ? [imageFileName] : null);

      _attachFilesToRequest(request, 'images', bytesList, namesList);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Update Product HTTP(${response.statusCode}): ${response.body}');

      if (_isSuccessStatus(response.statusCode)) {
        try {
          return json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          return {
            'status': 'error',
            'message': 'Invalid JSON response from server',
            'raw': response.body
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
          'raw': response.body
        };
      }
    } catch (e) {
      debugPrint("OperationsApi updateProduct error: $e");
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<bool> deleteProduct(String id) async {
    try {
      final response = await http.post(
        Uri.parse(_buildUrl('products.php')),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'action': 'delete', 'id': id},
      );

      debugPrint('Delete Product HTTP(${response.statusCode}): ${response.body}');

      if (_isSuccessStatus(response.statusCode)) {
        try {
          final data = json.decode(response.body);
          return data['status'] == 'success';
        } catch (e) {
          return false;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  // ==========================================
  // PROJECT OPERATIONS
  // ==========================================

  static Future<Map<String, dynamic>> addProject({
    required Map<String, String> fields,
    List<Uint8List>? imageBytesList,
    List<String>? fileNamesList,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      final uri = Uri.parse(_buildUrl('projects.php'));
      final request = http.MultipartRequest('POST', uri);

      request.fields['action'] = 'add';
      request.fields.addAll(fields);

      final List<Uint8List> bytesList = imageBytesList ??
          (imageBytes != null ? [imageBytes] : []);
      final List<String>? namesList = fileNamesList ?? (imageFileName != null ? [imageFileName] : null);

      _attachFilesToRequest(request, 'imageFile', bytesList, namesList);

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint('Add Project HTTP(${response.statusCode}): ${response.body}');

      if (_isSuccessStatus(response.statusCode)) {
        try {
          return json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          return {
            'status': 'error',
            'message': 'Invalid JSON response from server',
            'raw': response.body
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
          'raw': response.body
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProject({
    required Map<String, String> fields,
    List<Uint8List>? imageBytesList,
    List<String>? fileNamesList,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      final uri = Uri.parse(_buildUrl('projects.php'));
      final request = http.MultipartRequest('POST', uri);

      request.fields['action'] = 'update';
      request.fields.addAll(fields);

      final List<Uint8List> bytesList = imageBytesList ??
          (imageBytes != null ? [imageBytes] : []);
      final List<String>? namesList = fileNamesList ?? (imageFileName != null ? [imageFileName] : null);

      _attachFilesToRequest(request, 'imageFile', bytesList, namesList);

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint('Update Project HTTP(${response.statusCode}): ${response.body}');

      if (_isSuccessStatus(response.statusCode)) {
        try {
          return json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          return {
            'status': 'error',
            'message': 'Invalid JSON response from server',
            'raw': response.body
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
          'raw': response.body
        };
      }
    } catch (e) {
      debugPrint("OperationsApi updateProject error: $e");
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<bool> deleteProject(String id) async {
    try {
      final response = await http.post(
        Uri.parse(_buildUrl('projects.php')),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'action': 'delete', 'id': id},
      );

      debugPrint('Delete Project HTTP(${response.statusCode}): ${response.body}');

      if (_isSuccessStatus(response.statusCode)) {
        try {
          final data = json.decode(response.body);
          return data['status'] == 'success';
        } catch (e) {
          return false;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting project: $e');
      return false;
    }
  }

  // ==========================================
  // CLIENT OPERATIONS
  // ==========================================

  static Future<List<ClientItems>> fetchClients() async {
    try {
      final response = await http.get(
        Uri.parse(_buildUrl('clients.php?action=fetch')),
        headers: {'Accept': 'application/json'},
      );

      debugPrint('Fetch Clients Status: ${response.statusCode}');

      if (_isSuccessStatus(response.statusCode)) {
        try {
          final data = json.decode(response.body);
          if (data['status'] == 'success' && data['data'] != null) {
            final List<dynamic> clients = data['data'];
            return clients.map((item) => ClientItems.fromMap(item)).toList();
          }
        } catch (e) {
          debugPrint('Error parsing clients response: $e');
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching clients: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addClient({
    String? imageUrl,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      final uri = Uri.parse(_buildUrl('clients.php'));
      final request = http.MultipartRequest('POST', uri);

      request.fields['action'] = 'add';

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

      debugPrint('Add Client HTTP(${response.statusCode}): ${response.body}');

      if (_isSuccessStatus(response.statusCode)) {
        try {
          return json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          return {
            'status': 'error',
            'message': 'Invalid JSON response from server',
            'raw': response.body
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
          'raw': response.body
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  static Future<bool> deleteClient(String id) async {
    try {
      final response = await http.post(
        Uri.parse(_buildUrl('clients.php')),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'action': 'delete', 'id': id},
      );

      debugPrint('Delete Client HTTP(${response.statusCode}): ${response.body}');

      if (_isSuccessStatus(response.statusCode)) {
        try {
          final data = json.decode(response.body);
          return data['status'] == 'success';
        } catch (e) {
          return false;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting client: $e');
      return false;
    }
  }

  // ==========================================
  // HELPER: Attach files to request
  // ==========================================
  static void _attachFilesToRequest(
      http.MultipartRequest request,
      String fieldBase,
      List<Uint8List> bytesList,
      List<String>? namesList,
      ) {
    if (bytesList.isEmpty) return;

    final bool multiple = bytesList.length > 1;
    final String fieldName = multiple ? '${fieldBase}[]' : fieldBase;

    for (int i = 0; i < bytesList.length; i++) {
      final filename = (namesList != null && i < namesList.length && namesList[i].isNotEmpty)
          ? namesList[i]
          : '${fieldBase}_$i.jpg';

      String subtype = 'jpeg';
      final fnameLower = filename.toLowerCase();
      if (fnameLower.endsWith('.png')) subtype = 'png';
      else if (fnameLower.endsWith('.webp')) subtype = 'webp';
      else if (fnameLower.endsWith('.gif')) subtype = 'gif';
      else if (fnameLower.endsWith('.bmp')) subtype = 'bmp';

      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytesList[i],
          filename: filename,
          contentType: MediaType('image', subtype),
        ),
      );
    }
  }

  // ==========================================
  // FETCH PRODUCTS
  // ==========================================
  static Future<List<DecorProductItem>> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse(_buildUrl('products.php')),
      );

      debugPrint('Fetch Products Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['status'] == 'success' && data['data'] != null) {
            final List list = data['data'];
            return list.map((item) {
              List<String> imageUrls = [];
              if (item['image_urls'] is List) {
                imageUrls = List<String>.from(item['image_urls']);
              } else if (item['image_url'] is String) {
                imageUrls = [item['image_url']];
              }

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
        } catch (e) {
          debugPrint('Error parsing products response: $e');
        }
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
    return [];
  }

  // ==========================================
  // FETCH PROJECTS
  // ==========================================
  static Future<List<ProjectItem>> fetchProjects() async {
    try {
      final response = await http.get(
        Uri.parse(_buildUrl('projects.php')),
      );

      debugPrint('Fetch Projects Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['status'] == 'success' && data['data'] != null) {
            final List list = data['data'];
            return list.map((item) {
              List<String> imageUrls = [];
              if (item['image_urls'] is List) {
                imageUrls = List<String>.from(item['image_urls']);
              } else if (item['image_url'] is String) {
                imageUrls = [item['image_url']];
              }

              return ProjectItem(
                id: item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                title: item['title'] ?? '',
                subTitle: item['sub_title'] ?? 'Featured Residence',
                location: item['location'] ?? 'Mumbai',
                pricing: item['pricing'] ?? 'N/A',
                bhk: item['bhk'] ?? '3-BHK',
                scope: item['scope'] ?? 'Full Interior',
                propertyType: item['property_type'] ?? 'Apartment',
                size: item['size'] ?? '2000 sq ft',
                description: item['description'] ?? 'No description provided.',
                imageUrls: imageUrls,
              );
            }).toList();
          }
        } catch (e) {
          debugPrint('Error parsing projects response: $e');
        }
      }
    } catch (e) {
      debugPrint('Error fetching projects: $e');
    }
    return [];
  }
}