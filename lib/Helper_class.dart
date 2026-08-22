// ==========================================
// ENHANCED DATA MODELS WITH FULL URL GENERATION
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
  final String? imageUrl; // Single image URL for backward compatibility

  ProjectItem({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.location,
    required this.tags,
    required this.pricing,
    required this.bhk,
    required this.scope,
    required this.propertyType,
    required this.size,
    required this.description,
    required this.imageUrls,
    this.imageUrl,
  });

  // Get the primary image URL with proper scheme
  String get primaryImageUrl {
    final url = imageUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : '');
    if (url.isEmpty) return '';
    return _normalizeUrl(url);
  }

  // Get all image URLs with proper schemes
  List<String> get normalizedImageUrls {
    return imageUrls.map((url) => _normalizeUrl(url)).toList();
  }

  String _normalizeUrl(String url) {
    if (url.startsWith('//')) return 'https:$url';
    if (!url.startsWith('http://') &&
        !url.startsWith('https://') &&
        !url.startsWith('assets/') &&
        !url.startsWith('uploads/')) {
      return 'https://$url';
    }
    return url;
  }
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
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrls,
    this.imageUrl,
    required this.description,
    required this.material,
    required this.printType,
  });

  String get primaryImageUrl {
    final url = imageUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : '');
    if (url.isEmpty) return '';
    return _normalizeUrl(url);
  }

  String _normalizeUrl(String url) {
    if (url.startsWith('//')) return 'https:$url';
    if (!url.startsWith('http://') &&
        !url.startsWith('https://') &&
        !url.startsWith('assets/') &&
        !url.startsWith('uploads/')) {
      return 'https://$url';
    }
    return url;
  }
}

class ClientItems {
  final String id;
  final String? imgUrl;
  final String? imageUrl;
  final String? imageUrlFull;

  ClientItems({
    required this.id,
    this.imgUrl,
    this.imageUrl,
    this.imageUrlFull,
  });

  String get primaryImageUrl {
    final url = imageUrlFull ?? imageUrl ?? imgUrl ?? '';
    if (url.isEmpty) return '';
    return _normalizeUrl(url);
  }

  String _normalizeUrl(String url) {
    if (url.startsWith('//')) return 'https:$url';
    if (!url.startsWith('http://') &&
        !url.startsWith('https://') &&
        !url.startsWith('assets/') &&
        !url.startsWith('uploads/')) {
      return 'https://$url';
    }
    return url;
  }
}