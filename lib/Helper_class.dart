String _resolveImageUrl(String raw) {
  var value = raw.trim();
  if (value.isEmpty) return '';
  if (value.startsWith('assets/')) return value;
  final uri = Uri.tryParse(value);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) return value;
  if (value.startsWith('//')) return 'https:$value';
  value = value.replaceAll('\\', '/');
  while (value.startsWith('/')) { value = value.substring(1); }
  final origin = Uri.base;
  final baseUrl = origin.host.isNotEmpty
      ? '${origin.scheme.isEmpty ? 'http' : origin.scheme}://${origin.host}${origin.hasPort ? ':${origin.port}' : ''}/bindu_decor'
      : 'http://192.168.1.15/bindu_decor';
  if (value.toLowerCase().startsWith('bindu_decor/')) value = value.substring('bindu_decor/'.length);
  if (value.toLowerCase().startsWith('uploads/')) return '$baseUrl/$value';
  return '$baseUrl/uploads/$value';
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
    final rawImage = (map['image_url'] ?? map['imageUrl'] ?? map['img_url'] ?? '').toString().trim();
    final rawImages = map['image_urls'] ?? map['imageUrls'];
    final List<String> images = <String>[];
    if (rawImages is List) {
      for (final value in rawImages) {
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) images.add(_resolveImageUrl(text));
      }
    }
    if (rawImage.isNotEmpty) {
      final resolved = _resolveImageUrl(rawImage);
      if (resolved.isNotEmpty && !images.contains(resolved)) images.insert(0, resolved);
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
    final raw = (map['image_url'] ?? map['imageUrl'] ?? map['img_url'] ?? '').toString().trim();
    final resolved = raw.isEmpty ? '' : _resolveImageUrl(raw);
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
    final raw = (map['img_url'] ?? map['image_url'] ?? map['imageUrl'] ?? '').toString().trim();
    final resolved = raw.isEmpty ? '' : _resolveImageUrl(raw);
    return ClientItems(
      id: (map['id'] ?? '').toString(),
      imgUrl: resolved,
      imageUrl: resolved,
      imageUrlFull: resolved,
    );
  }

  String get primaryImageUrl => imageUrlFull ?? imageUrl ?? imgUrl ?? '';
}
