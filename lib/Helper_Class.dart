class DecorProductItem {
  final String id;
  final String title;
  final String category;
  final List<ImageDetail>? imageDetails;
  final List<String> imageUrls;
  final String description;
  final String? material;
  final String? printType;

  const DecorProductItem({
    this.id = '',
    required this.title,
    this.category = "HOME DECOR",
    this.imageDetails,
    required this.imageUrls,
    required this.description,
    this.material = "Premium Grade Material",
    this.printType = "High Definition Digital Print / Finish",
  });

  factory DecorProductItem.fromMap(Map<String, dynamic> map) {
    String img = map['image_url'] ?? map['img_url'] ?? '';
    return DecorProductItem(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? 'HOME DECOR',
      imageUrls: img.isNotEmpty ? [img] : [],
      description: map['description'] ?? '',
      material: map['material'] ?? 'Premium Grade Material',
      printType: map['print_type'] ?? 'High Definition Digital Print / Finish',
    );
  }
}

class ImageDetail {
  final String imageUrl;
  final String? title;
  final String? description;

  const ImageDetail({
    required this.imageUrl,
    this.title,
    this.description,
  });
}

class ClientItems {
  final String id;
  final String imgUrl;

  const ClientItems({
    this.id = '',
    required this.imgUrl,
  });

  factory ClientItems.fromMap(Map<String, dynamic> map) {
    return ClientItems(
      id: map['id']?.toString() ?? '',
      imgUrl: map['img_url'] ?? map['image_url'] ?? '',
    );
  }
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

  const ProjectItem({
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
  });

  factory ProjectItem.fromMap(Map<String, dynamic> map) {
    String image = map['image_url'] ?? map['imageUrl'] ?? '';
    return ProjectItem(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      subTitle: map['sub_title'] ?? '',
      location: map['location'] ?? '',
      tags: [],
      pricing: map['pricing'] ?? '',
      bhk: map['bhk'] ?? '',
      scope: map['scope'] ?? '',
      propertyType: map['property_type'] ?? '',
      size: map['size'] ?? '',
      description: map['description'] ?? '',
      imageUrls: image.isNotEmpty ? [image] : [],
    );
  }

  Map<String, String> toMap() {
    return {
      'id': id,
      'title': title,
      'sub_title': subTitle,
      'location': location,
      'pricing': pricing,
      'bhk': bhk,
      'scope': scope,
      'property_type': propertyType,
      'size': size,
      'description': description,
      'image_url': imageUrls.isNotEmpty ? imageUrls.first : '',
    };
  }
}