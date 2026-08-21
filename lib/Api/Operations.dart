import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../Helper_Class.dart';

class OperationsApi {
  static const String baseUrl = "http://192.168.1.15/bindu_decor/";

  /// Fetches all active projects from the server
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

  /// Adds a project along with text fields and optional raw image bytes.
  static Future<Map<String, dynamic>> addProject({
    required Map<String, String> fields,
    List<int>? imageBytes,
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/projects.php?action=add");
      final request = http.MultipartRequest('POST', uri);

      // Attach form text fields
      request.fields.addAll(fields);

      // Attach raw byte image if available
      if (imageBytes != null && imageBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'imageFile',
            imageBytes,
            filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"status": "error", "message": "Server error ${response.statusCode}"};
    } catch (e) {
      debugPrint("API Error: $e");
      return {"status": "error", "message": e.toString()};
    }
  }

  /// Deletes a project by ID via API
  static Future<bool> deleteProject(String id) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/projects.php?action=delete"),
        body: {'id': id},
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        return resData['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint("API Delete Error: $e");
      return false;
    }
  }
}