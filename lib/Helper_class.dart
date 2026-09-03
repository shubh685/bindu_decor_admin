import 'dart:convert';

const String _kBaseUrl = 'https://yellow-woodpecker-430323.hostingersite.com/api/bindu_admin_web';

String _resolveImageUrl(String raw) {
  var value = raw.trim();
  if (value.isEmpty) return '';

  if (value.startsWith('assets/')) return value;
  if (value.startsWith('data:image/')) return value;

  // If already an absolute HTTP/HTTPS URL or includes image.php proxy, preserve it completely
  if (value.startsWith('http://') || value.startsWith('https://') || value.contains('image.php')) {
    return value;
  }

  String cleanPath = _cleanPath(value);
  if (cleanPath.isEmpty) return '';

  final baseUrl = _getBaseUrl();
  return '$baseUrl/image.php?path=${Uri.encodeComponent(cleanPath)}';
}

String _cleanPath(String path) {
  String clean = path.replaceAll('\\', '/');

  while (clean.startsWith('/')) {
    clean = clean.substring(1);
  }

  if (clean.toLowerCase().startsWith('bindu_decor/')) {
    clean = clean.substring('bindu_decor/'.length);
  }

  if (clean.toLowerCase().startsWith('uploads/uploads/')) {
    clean = clean.substring('uploads/'.length);
  }

  if (clean.isNotEmpty && !clean.toLowerCase().startsWith('uploads/')) {
    clean = 'uploads/$clean';
  }

  return clean;
}

String _getBaseUrl() {
  try {
    final origin = Uri.base;
    if (origin.host.isNotEmpty && origin.host != 'localhost') {
      final scheme = origin.scheme.isEmpty ? 'http' : origin.scheme;
      final port = origin.hasPort ? ':${origin.port}' : '';
      return '$scheme://${origin.host}$port/bindu_decor';
    }
  } catch (e) {}
  return _kBaseUrl;
}

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
    List<String> images = [];

    if (map['image_urls'] != null) {
      final raw = map['image_urls'];

      if (raw is List) {
        for (var item in raw) {
          final url = item.toString().trim();
          if (url.isNotEmpty) images.add(url);
        }
      } else if (raw is String) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            for (var item in decoded) {
              final url = item.toString().trim();
              if (url.isNotEmpty) images.add(url);
            }
          } else {
            final url = raw.trim();
            if (url.isNotEmpty) images.add(url);
          }
        } catch (_) {
          final url = raw.trim();
          if (url.isNotEmpty) images.add(url);
        }
      }
    }

    if (images.isEmpty && map['image_url'] != null) {
      final url = map['image_url'].toString().trim();
      if (url.isNotEmpty) images.add(url);
    }

    if (images.isEmpty && map['imageUrl'] != null) {
      final url = map['imageUrl'].toString().trim();
      if (url.isNotEmpty) images.add(url);
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
}

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
    List<String> images = [];

    if (map['image_urls'] != null) {
      final raw = map['image_urls'];

      if (raw is List) {
        for (var item in raw) {
          final url = item.toString().trim();
          if (url.isNotEmpty) images.add(url);
        }
      } else if (raw is String) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            for (var item in decoded) {
              final url = item.toString().trim();
              if (url.isNotEmpty) images.add(url);
            }
          } else {
            final url = raw.trim();
            if (url.isNotEmpty) images.add(url);
          }
        } catch (_) {
          final url = raw.trim();
          if (url.isNotEmpty) images.add(url);
        }
      }
    }

    if (images.isEmpty && map['image_url'] != null) {
      final url = map['image_url'].toString().trim();
      if (url.isNotEmpty) images.add(url);
    }

    if (images.isEmpty && map['imageUrl'] != null) {
      final url = map['imageUrl'].toString().trim();
      if (url.isNotEmpty) images.add(url);
    }

    return DecorProductItem(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      category: (map['category'] ?? 'HOME DECOR').toString(),
      imageUrls: images,
      imageUrl: images.isNotEmpty ? images.first : null,
      description: (map['description'] ?? '').toString(),
      material: map['material']?.toString(),
      printType: (map['print_type'] ?? map['printType'])?.toString(),
    );
  }

  String get primaryImageUrl => imageUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : '');
}

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

  // Guarantees non-nullable string returns for Flutter widgets
  String get primaryImageUrl => imageUrlFull ?? imageUrl ?? imgUrl ?? '';
  String get safeImageUrl => imageUrlFull ?? imageUrl ?? imgUrl ?? '';
}

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
    List<String> parsedPhotos = [];
    if (json['photos'] != null) {
      List rawList = [];
      if (json['photos'] is List) {
        rawList = json['photos'];
      } else if (json['photos'] is String) {
        try {
          final decoded = jsonDecode(json['photos']);
          if (decoded is List) rawList = decoded;
        } catch (_) {}
      }

      parsedPhotos = rawList
          .map((img) {
        final str = img.toString().trim();
        if (str.startsWith('http://') || str.startsWith('https://')) {
          return str;
        }
        return _resolveImageUrl(str);
      })
          .where((url) => url.isNotEmpty)
          .toList();
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
}