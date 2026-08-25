// Helper_class.dart

// ==========================================
// IMAGE URL RESOLUTION — routed through image.php
// ==========================================
// Same reasoning as OperationsApi.resolveImageUrl(): direct static files
// under /uploads/ were failing with a connection-level error even though
// the JSON APIs on the same host always succeed. Routing every image
// through image.php makes image loads behave exactly like the working
// JSON endpoints.

import 'dart:convert';

import 'AdminDashboard.dart';

const String _kBaseUrl = 'http://192.168.1.54/bindu_decor';

String _resolveImageUrl(String raw) {
  var value = raw.trim();
  if (value.isEmpty) return '';

  // Asset images - return as is
  if (value.startsWith('assets/')) return value;

  // Data URIs - return as is
  if (value.startsWith('data:image/')) return value;

  // Already an image.php URL - return as is
  if (value.contains('image.php?path=')) return value;

  String cleanPath = value;

  // If it's a full URL, extract just the path portion
  final uri = Uri.tryParse(value);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    cleanPath = uri.path;
  } else if (value.startsWith('//')) {
    // protocol-relative URL
    final parsed = Uri.tryParse('https:$value');
    cleanPath = parsed?.path ?? value;
  }

  cleanPath = _cleanPath(cleanPath);
  if (cleanPath.isEmpty) return '';

  final baseUrl = _getBaseUrl();
  return '$baseUrl/image.php?path=${Uri.encodeComponent(cleanPath)}';
}

// Normalizes a raw path down to "uploads/filename.ext"
String _cleanPath(String path) {
  String clean = path.replaceAll('\\', '/');

  while (clean.startsWith('/')) {
    clean = clean.substring(1);
  }

  // Remove duplicate bindu_decor/
  if (clean.toLowerCase().startsWith('bindu_decor/')) {
    clean = clean.substring('bindu_decor/'.length);
  }

  // Remove duplicate uploads/uploads/
  if (clean.toLowerCase().startsWith('uploads/uploads/')) {
    clean = clean.substring('uploads/'.length);
  }

  // Ensure uploads/ prefix if path is not empty and doesn't already have it
  if (clean.isNotEmpty && !clean.toLowerCase().startsWith('uploads/')) {
    clean = 'uploads/$clean';
  }

  return clean;
}

// Get base URL with fallback
String _getBaseUrl() {
  try {
    final origin = Uri.base;
    if (origin.host.isNotEmpty && origin.host != 'localhost') {
      final scheme = origin.scheme.isEmpty ? 'http' : origin.scheme;
      final port = origin.hasPort ? ':${origin.port}' : '';
      return '$scheme://${origin.host}$port/bindu_decor';
    }
  } catch (e) {
    // Fallback to the configured URL
  }
  // Default fallback - change this to your actual server IP
  return _kBaseUrl;
}

// ==========================================
// PROJECT ITEM
// ==========================================
class ProjectItem {
  final String id;
  final String title;
  final String subTitle;
  final String location;
  final List<String> tags;
  final String pricing;
  final String bhk;
  final String scope;
  final String propertyType;
  final String size;
  final String description;
  final List<String> imageUrls;
  final String? imageUrl;

  ProjectItem({
    this.id = '',
    this.title = '',
    this.subTitle = '',
    this.location = '',
    this.tags = const <String>[],
    this.pricing = '',
    this.bhk = '',
    this.scope = '',
    this.propertyType = '',
    this.size = '',
    this.description = '',
    this.imageUrls = const <String>[],
    this.imageUrl,
  });

  factory ProjectItem.fromMap(Map<String, dynamic> map) {
    String rawImage = '';
    if (map['image_url'] != null && map['image_url'].toString().isNotEmpty) {
      rawImage = map['image_url'].toString().trim();
    } else if (map['imageUrl'] != null && map['imageUrl'].toString().isNotEmpty) {
      rawImage = map['imageUrl'].toString().trim();
    }

    final rawImages = map['image_url'] ?? map['imageUrls'];
    final List<String> images = <String>[];

    if (rawImages is List) {
      for (final value in rawImages) {
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) {
          final resolved = _resolveImageUrl(text);
          if (resolved.isNotEmpty) images.add(resolved);
        }
      }
    }

    if (rawImage.isNotEmpty) {
      final resolved = _resolveImageUrl(rawImage);
      if (resolved.isNotEmpty && !images.contains(resolved)) {
        images.insert(0, resolved);
      }
    }

    return ProjectItem(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      subTitle: (map['sub_title'] ?? map['subTitle'] ?? '').toString(),
      location: (map['location'] ?? '').toString(),
      tags: map['tags'] is List ? (map['tags'] as List).map((e) => e.toString()).toList() : const <String>[],
      pricing: (map['pricing'] ?? '').toString(),
      bhk: (map['bhk'] ?? '').toString(),
      scope: (map['scope'] ?? '').toString(),
      propertyType: (map['property_type'] ?? map['propertyType'] ?? '').toString(),
      size: (map['size'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      imageUrls: images,
      imageUrl: images.isNotEmpty ? images.first : null,
    );
  }

  String get primaryImageUrl => imageUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : '');
  List<String> get normalizedImageUrls => imageUrls.map(_resolveImageUrl).where((e) => e.isNotEmpty).toList();
}

// ==========================================
// PRODUCT ITEM
// ==========================================
class DecorProductItem {
  final String id;
  final String title;
  final String category;
  final List<String> imageUrls;
  final String? imageUrl;
  final String? description;
  final String? material;
  final String? printType;

  DecorProductItem({
    this.id = '',
    this.title = '',
    this.category = 'HOME DECOR',
    this.imageUrls = const <String>[],
    this.imageUrl,
    this.description,
    this.material,
    this.printType,
  });

  factory DecorProductItem.fromMap(Map<String, dynamic> map) {
    String rawImage = '';
    if (map['image_url'] != null && map['image_url'].toString().isNotEmpty) {
      rawImage = map['image_url'].toString().trim();
    } else if (map['imageUrl'] != null && map['imageUrl'].toString().isNotEmpty) {
      rawImage = map['imageUrl'].toString().trim();
    }

    final resolved = rawImage.isEmpty ? '' : _resolveImageUrl(rawImage);

    return DecorProductItem(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      category: (map['category'] ?? 'HOME DECOR').toString(),
      imageUrls: resolved.isEmpty ? const <String>[] : <String>[resolved],
      imageUrl: resolved.isEmpty ? null : resolved,
      description: (map['description'] ?? '').toString(),
      material: map['material']?.toString(),
      printType: (map['print_type'] ?? map['printType'])?.toString(),
    );
  }

  String get primaryImageUrl => imageUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : '');
}

// ==========================================
// CLIENT ITEM
// ==========================================
class ClientItems {
  final String id;
  final String? imgUrl;
  final String? imageUrl;
  final String? imageUrlFull;

  ClientItems({
    this.id = '',
    this.imgUrl,
    this.imageUrl,
    this.imageUrlFull,
  });

  factory ClientItems.fromMap(Map<String, dynamic> map) {
    String rawImage = '';
    if (map['img_url'] != null && map['img_url'].toString().isNotEmpty) {
      rawImage = map['img_url'].toString().trim();
    } else if (map['image_url'] != null && map['image_url'].toString().isNotEmpty) {
      rawImage = map['image_url'].toString().trim();
    }

    final resolved = rawImage.isEmpty ? '' : _resolveImageUrl(rawImage);

    return ClientItems(
      id: (map['id'] ?? '').toString(),
      imgUrl: resolved.isEmpty ? null : resolved,
      imageUrl: resolved.isEmpty ? null : resolved,
      imageUrlFull: resolved.isEmpty ? null : resolved,
    );
  }

  String get primaryImageUrl => imageUrlFull ?? imageUrl ?? imgUrl ?? '';
}

// ==========================================
// BLOG MODEL

class BlogItem {
  final String id;
  final String title;
  final String subject;
  final String description;
  final String authorName;
  final String status;
  final List<String> photos;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BlogItem({
    this.id = '',
    this.title = '',
    this.subject = '',
    this.description = '',
    this.authorName = '',
    this.status = 'Draft',
    this.photos = const <String>[],
    this.createdAt,
    this.updatedAt,
  });

  factory BlogItem.fromJson(Map<String, dynamic> json) {
    // Process photos array and resolve image URLs properly
    List<String> parsedPhotos = [];
    if (json['photos'] != null) {
      if (json['photos'] is List) {
        parsedPhotos = (json['photos'] as List)
            .map((img) => _resolveImageUrl(img.toString()))
            .where((url) => url.isNotEmpty)
            .toList();
      } else if (json['photos'] is String) {
        try {
          final decoded = jsonDecode(json['photos']);
          if (decoded is List) {
            parsedPhotos = decoded
                .map((img) => _resolveImageUrl(img.toString()))
                .where((url) => url.isNotEmpty)
                .toList();
          }
        } catch (_) {}
      }
    }

    return BlogItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      authorName: (json['author_name'] ?? json['authorName'] ?? '').toString(),
      status: (json['status'] ?? 'Draft').toString(),
      photos: parsedPhotos,
      createdAt: json['created_at'] != null && json['created_at'].toString().isNotEmpty
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null && json['updated_at'].toString().isNotEmpty
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'description': description,
      'author_name': authorName,
      'status': status,
      'photos': photos,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get primaryImageUrl => photos.isNotEmpty ? photos.first : '';
}
