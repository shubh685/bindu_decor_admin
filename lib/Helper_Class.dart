class DecorProductItem {
  final String title;
  final String category;
  final List<ImageDetail>? imageDetails;
  final List<String> imageUrls;
  final String description;
  final String? material;
  final String? printType;

  const DecorProductItem({
    required this.title,
    this.category = "HOME DECOR",
    this.imageDetails,
    required this.imageUrls,
    required this.description,
    this.material = "Premium Grade Material",
    this.printType = "High Definition Digital Print / Finish",
  });
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
  final String imgUrl;
  const ClientItems({required this.imgUrl});
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

  // Factory constructor for MySQL response parsing
  factory ProjectItem.fromMap(Map<String, dynamic> map) {
    String image = map['image_url'] ?? map['imageUrl'] ?? '';
    return ProjectItem(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      subTitle: map['sub_title']  ?? '',
      location: map['location'] ?? '',
      tags: [],
      pricing: map['pricing'] ?? '',
      bhk: map['bhk'] ?? '',
      scope: map['scope'] ?? '',
      propertyType: map['property_type'] ??  '',
      size: map['size'] ?? '',
      description: map['description'] ?? '',
      imageUrls: map['image_url'] ?? '',
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